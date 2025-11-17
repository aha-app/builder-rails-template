# frozen_string_literal: true

require "active_storage/service"
require "jwt"
require "net/http"
require "uri"

# Custom ActiveStorage service that uses nginx x-accel-redirect for efficient
# uploads and downloads through a blob service (similar to Vercel's blob storage)
#
# This service stores metadata in ActiveStorage but delegates actual blob storage
# to an external blob service, using nginx to stream data without buffering through Rails.
#
# Configuration in storage.yml:
#   blob_service:
#     service: BlobService
#     blob_service_url: http://blob-service.fredcodes-local.svc.cluster.local:9003
#     token: <%= ENV['BLOB_UPLOADS_RW'] %>
class BlobServiceStorage < ActiveStorage::Service
  attr_reader :blob_service_url, :token, :account_id, :blob_store_id

  def initialize(blob_service_url:, token:)
    @blob_service_url = blob_service_url
    @token = token

    # Parse the blob token to extract account and blob store metadata
    token_payload = parse_blob_token(token)
    @account_id = token_payload[:accountId]
    @blob_store_id = token_payload[:blobStoreId]
  end

  # Upload file to blob service
  # This is called by ActiveStorage when using direct uploads
  def upload(key, io, checksum: nil, **)
    instrument :upload, key: key, checksum: checksum do
      # For server-side uploads, we need to stream the IO to the blob service
      # In practice, you'll mostly use direct uploads which bypass this method
      uri = URI.parse("#{blob_service_url}/blob?pathname=#{ERB::Util.url_encode(key)}")

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request.body = io.read

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise ActiveStorage::IntegrityError, "Upload failed: #{response.code}"
      end
    end
  end

  # Download file from blob service
  # Returns the file content as a string
  def download(key, &block)
    if block_given?
      instrument :streaming_download, key: key do
        stream(key, &block)
      end
    else
      instrument :download, key: key do
        uri = URI.parse(download_url(key))

        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{token}"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end

        unless response.is_a?(Net::HTTPSuccess)
          raise ActiveStorage::FileNotFoundError, "File not found: #{key}"
        end

        response.body
      end
    end
  end

  # Download a chunk of the file
  def download_chunk(key, range)
    instrument :download_chunk, key: key, range: range do
      uri = URI.parse(download_url(key))

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Range"] = "bytes=#{range.begin}-#{range.end}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPPartialContent)
        raise ActiveStorage::FileNotFoundError, "File not found: #{key}"
      end

      response.body
    end
  end

  # Delete file from blob service
  def delete(key)
    instrument :delete, key: key do
      uri = URI.parse("#{blob_service_url}/blob?pathname=#{ERB::Util.url_encode(key)}")

      request = Net::HTTP::Delete.new(uri)
      request["Authorization"] = "Bearer #{token}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise ActiveStorage::Error, "Delete failed: #{response.code}"
      end
    end
  end

  # Delete multiple files
  def delete_prefixed(prefix)
    instrument :delete_prefixed, prefix: prefix do
      # Note: This requires the blob service to support prefix-based deletion
      # If not supported, you may need to list and delete individually
      # For now, we'll just log a warning
      Rails.logger.warn "delete_prefixed not fully implemented for BlobServiceStorage: #{prefix}"
    end
  end

  # Check if file exists
  def exist?(key)
    instrument :exist, key: key do |payload|
      uri = URI.parse("#{blob_service_url}/blob?pathname=#{ERB::Util.url_encode(key)}")

      request = Net::HTTP::Head.new(uri)
      request["Authorization"] = "Bearer #{token}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      answer = response.is_a?(Net::HTTPSuccess)
      payload[:exist] = answer
      answer
    end
  end

  # Generate URL for direct browser access
  # This returns a path that will use x-accel-redirect for efficient serving
  def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:, custom_metadata: {})
    instrument :url, key: key do |payload|
      # Return the Rails endpoint that will handle the x-accel-redirect
      url = Rails.application.routes.url_helpers.rails_blob_direct_upload_url(
        key: key,
        content_type: content_type,
        content_length: content_length,
        checksum: checksum
      )
      payload[:url] = url
      url
    end
  end

  # Generate headers for direct upload
  def headers_for_direct_upload(key, content_type:, checksum:, custom_metadata: {}, **)
    {
      "Content-Type" => content_type,
      "Content-MD5" => checksum,
      "X-Blob-Key" => key
    }
  end

  # Return the internal blob service URL for a given key
  # This is used by controllers to construct x-accel-redirect paths
  def blob_service_upload_url(key)
    "#{blob_service_url}/blob?pathname=#{ERB::Util.url_encode(key)}"
  end

  # Return the internal path for nginx x-accel-redirect downloads
  # Format: /_blob_internal/:accountId/:blobStoreId/:nonce/:pathname?token=...
  def nginx_redirect_path(key)
    # nonce is not validated by nginx, using '0' as placeholder
    "/_blob_internal/#{account_id}/#{blob_store_id}/0/#{key}?token=#{ERB::Util.url_encode(token)}"
  end

  private

  def download_url(key)
    "#{blob_service_url}/blob?pathname=#{ERB::Util.url_encode(key)}"
  end

  def stream(key)
    uri = URI.parse(download_url(key))

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{token}"

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request) do |response|
        unless response.is_a?(Net::HTTPSuccess)
          raise ActiveStorage::FileNotFoundError, "File not found: #{key}"
        end

        # Stream in chunks
        response.read_body do |chunk|
          yield chunk
        end
      end
    end
  end

  def parse_blob_token(token)
    # Decode JWT without verification (since we trust the token from env)
    # In production, you might want to verify the signature
    payload = JWT.decode(token, nil, false).first
    payload.deep_symbolize_keys
  rescue JWT::DecodeError => e
    raise ActiveStorage::Error, "Invalid blob token: #{e.message}"
  end

  def instrument(operation, payload = {}, &block)
    ActiveSupport::Notifications.instrument(
      "service_#{operation}.active_storage",
      payload.merge(service: service_name),
      &block
    )
  end

  def service_name
    "Blob Service"
  end
end
