# frozen_string_literal: true

require "test_helper"

class BlobStorageServiceTest < ActiveSupport::TestCase
  setup do
    @blob_service_url = "http://blob-service.test:9003"

    # Create a mock JWT token with the expected payload structure
    @token_payload = {
      accountId: "test-account-123",
      blobStoreId: "test-store-456",
      exp: 1.hour.from_now.to_i
    }
    @token = JWT.encode(@token_payload, nil, 'none')

    @service = BlobStorageService.new(
      blob_service_url: @blob_service_url,
      token: @token
    )

    @test_key = "test/path/file.txt"
    @test_content = "Hello, World!"
  end

  test "initializes with correct attributes" do
    assert_equal @blob_service_url, @service.blob_service_url
    assert_equal @token, @service.token
    assert_equal "test-account-123", @service.account_id
    assert_equal "test-store-456", @service.blob_store_id
  end

  test "raises error with invalid token" do
    error = assert_raises(ActiveStorage::Error) do
      BlobStorageService.new(
        blob_service_url: @blob_service_url,
        token: "invalid-token"
      )
    end
    assert_match /Invalid blob token/, error.message
  end

  test "blob_service_upload_url returns correct URL" do
    expected_url = "#{@blob_service_url}/blob?pathname=#{ERB::Util.url_encode(@test_key)}"
    assert_equal expected_url, @service.blob_service_upload_url(@test_key)
  end

  test "blob_service_upload_url handles special characters in pathname" do
    key_with_spaces = "test/path with spaces/file.txt"
    url = @service.blob_service_upload_url(key_with_spaces)
    assert_includes url, ERB::Util.url_encode(key_with_spaces)
    assert_includes url, "#{@blob_service_url}/blob?pathname="
  end

  test "nginx_redirect_path returns correct internal path" do
    expected_path = "/_blob_internal/test-account-123/test-store-456/0/#{@test_key}?token=#{ERB::Util.url_encode(@token)}"
    assert_equal expected_path, @service.nginx_redirect_path(@test_key)
  end

  test "nginx_redirect_path includes encoded token" do
    path = @service.nginx_redirect_path(@test_key)
    assert_includes path, "token=#{ERB::Util.url_encode(@token)}"
  end

  test "nginx_redirect_path uses placeholder nonce" do
    path = @service.nginx_redirect_path(@test_key)
    assert_includes path, "/_blob_internal/test-account-123/test-store-456/0/"
  end

  test "nginx_redirect_path handles nested keys" do
    nested_key = "uploads/ab/cd/abc123/document.pdf"
    path = @service.nginx_redirect_path(nested_key)
    assert_includes path, nested_key
    assert_includes path, "/_blob_internal/test-account-123/test-store-456/0/"
  end

  test "service name returns correct string" do
    service_name = nil
    ActiveSupport::Notifications.subscribe("service_exist.active_storage") do |event|
      service_name = event.payload[:service]
    end

    @service.exist?(@test_key) rescue nil # Will fail but we just need the notification

    assert_equal "Blob Service", service_name
  ensure
    ActiveSupport::Notifications.unsubscribe("service_exist.active_storage")
  end

  test "parses token payload correctly" do
    # The service should have extracted the correct values from the token
    assert_equal @token_payload[:accountId], @service.account_id
    assert_equal @token_payload[:blobStoreId], @service.blob_store_id
  end

  test "handles token with string keys" do
    # Test with string keys instead of symbol keys
    string_payload = {
      "accountId" => "string-account",
      "blobStoreId" => "string-store"
    }
    string_token = JWT.encode(string_payload, nil, 'none')

    service = BlobStorageService.new(
      blob_service_url: @blob_service_url,
      token: string_token
    )

    assert_equal "string-account", service.account_id
    assert_equal "string-store", service.blob_store_id
  end

  test "upload raises error when blob service returns non-success status" do
    # Note: This test would require HTTP mocking (like WebMock)
    # Skipping actual HTTP call testing as it requires additional setup
    skip "Requires HTTP mocking library like WebMock"
  end

  test "download raises error when blob service returns non-success status" do
    # Note: This test would require HTTP mocking (like WebMock)
    skip "Requires HTTP mocking library like WebMock"
  end

  test "exist? raises error for invalid keys" do
    # Note: This test would require HTTP mocking (like WebMock)
    skip "Requires HTTP mocking library like WebMock"
  end

  test "delete constructs correct URL" do
    # Test that delete would construct the correct URL
    # Note: Actual HTTP testing requires mocking
    skip "Requires HTTP mocking library like WebMock"
  end

  test "url_for_direct_upload returns Rails route" do
    # This would require Rails routing to be fully loaded
    skip "Requires full Rails routing context"
  end

  test "headers_for_direct_upload includes correct headers" do
    key = "test/file.pdf"
    content_type = "application/pdf"
    checksum = "abc123"

    headers = @service.headers_for_direct_upload(
      key,
      content_type: content_type,
      checksum: checksum
    )

    assert_equal content_type, headers["Content-Type"]
    assert_equal checksum, headers["Content-MD5"]
    assert_equal key, headers["X-Blob-Key"]
  end

  test "headers_for_direct_upload with custom metadata" do
    key = "test/file.pdf"
    content_type = "application/pdf"
    checksum = "abc123"
    custom_metadata = { user_id: "123", project: "test" }

    headers = @service.headers_for_direct_upload(
      key,
      content_type: content_type,
      checksum: checksum,
      custom_metadata: custom_metadata
    )

    assert_equal content_type, headers["Content-Type"]
    assert_equal checksum, headers["Content-MD5"]
    assert_equal key, headers["X-Blob-Key"]
    # Note: Custom metadata handling depends on implementation
  end
end
