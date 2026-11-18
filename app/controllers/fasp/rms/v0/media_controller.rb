module Fasp
  module Rms
    module V0
      class MediaController < Fasp::ApiController
        def show
          render json: media_response_object
        end

        private

        def media_response_object
          case storage_request.state
          when :enqueued || :processing
            response_object_processing
          when :ok
            resopnse_object_success
          when :rejected
            response_object_rejected
          end
        end

        def storage_request
          @storage_request = StorageRequest.find_by(media_file_id: params[:id])
        end

        def media_file
          @media_file = @storage_request.media_file
        end

        def response_object_success
          {
           "id": @storage_request.media_file_id,
           "activityPub": {
             "id": @storage_request.ap_object_id
           },
           "originalURL": @storage_request.file_url,
           "status": "ok",
           "contentType": media_file.content_type,
           "contentLength": media_file.file_size,
           "contentDigest": media_file.sha512,
           "metadata": {
             "height": media_file.height,
             "width": media_file.width
           },
           "extension": File.extname(@storage_request.file_url),
           # TODO: define representations
           "representations": []
          }
        end

        def response_object_processing
          {
           "id": @storage_request.media_file_id,
           "activityPub": {
             "id": @storage_request.ap_object_id
           },
           "originalURL": @storage_request.file_url,
           "status": "processing"
          }
        end

        def response_object_rejected
          {
           "id": @storage_request.media_file_id,
           "activityPub": {
             "id": @storage_request.ap_object_id
           },
           "originalURL": @storage_request.file_url,
           "status": "rejected",
           "reason": {
             "code": @storage_request.rejection_reason,
             # TODO: how do we want to handle this?
             "message": @storage_request.rejection_reason
           }
          }
        end
      end
    end
  end
end
