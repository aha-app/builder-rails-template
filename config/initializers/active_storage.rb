# frozen_string_literal: true

# Configure ActiveStorage to use our custom controllers with x-accel-redirect
Rails.application.config.after_initialize do
  # Override the DirectUploadsController with our custom implementation
  ActiveStorage::DirectUploadsController.class_eval do
    # Handle the actual PUT upload with x-accel-redirect
    def update
      blob = ActiveStorage::Blob.find_signed!(params[:signed_id])

      # Only use x-accel-redirect for BlobStorageService
      service = ActiveStorage::Blob.service
      if service.is_a?(BlobStorageService) && ENV['BLOB_UPLOADS_RW']
        # Construct the blob service upload URL
        upload_url = service.blob_service_upload_url(blob.key)

        # Success response - just return 204 No Content
        success_content = ""
        failure_content = JSON.generate(error: 'Upload failed')

        # Use x-accel-redirect to let nginx handle the streaming upload
        response.headers['X-Accel-Redirect'] = "/_blob_upload?url=#{ERB::Util.url_encode(upload_url)}&success=#{ERB::Util.url_encode(success_content)}&failure=#{ERB::Util.url_encode(failure_content)}"
        response.headers['X-Blob-Auth'] = "Bearer #{ENV['BLOB_UPLOADS_RW']}"
        response.headers['X-Content-Type'] = request.content_type || 'application/octet-stream'

        head :no_content
      else
        # Fall back to standard upload for other services
        super
      end
    end
  end

  # Override Blobs::RedirectController for downloads
  ActiveStorage::Blobs::RedirectController.class_eval do
    def show
      blob = ActiveStorage::Blob.find_signed!(params[:signed_id])

      # Only use x-accel-redirect for BlobStorageService
      service = ActiveStorage::Blob.service
      if service.is_a?(BlobStorageService) && ENV['BLOB_UPLOADS_RW']
        # Get the nginx internal redirect path
        internal_path = service.nginx_redirect_path(blob.key)

        # Use x-accel-redirect to let nginx handle streaming from blob service
        response.headers['X-Accel-Redirect'] = internal_path
        response.headers['Content-Type'] = blob.content_type
        response.headers['Content-Disposition'] = content_disposition_with(
          type: params[:disposition] || 'inline',
          filename: blob.filename.sanitized
        )

        head :ok
      else
        # Fall back to standard behavior - redirect to service URL
        expires_in ActiveStorage.service_urls_expire_in
        redirect_to blob.url(disposition: params[:disposition]), allow_other_host: true
      end
    end

    private

    def content_disposition_with(type:, filename:)
      disposition = type.to_s
      disposition += %Q[; filename="#{filename}"]
      disposition += %Q[; filename*=UTF-8''#{ERB::Util.url_encode(filename)}]
      disposition
    end
  end
end
