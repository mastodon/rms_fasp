module Fasp
  module Rms
    module V0
      class MediaController < Fasp::ApiController
        before_action :set_storage_request

        def show
          render json: media_response_object

        rescue ActiveRecord::RecordNotFound
          head :not_found
        end

        private

        def media_response_object
          case @storage_request.state
          when "enqueued", "processing"
            shared_response_base
          when "ok"
            response_object_success
          when "rejected"
            response_object_rejected
          end
        end

        def set_storage_request
          @storage_request = StorageRequest.find(params[:id])
        end

        def media_file = @storage_request.media_file

        def rejection_reason
          return unless @storage_request.rejection_reason

          MediaFile::REJECTION_RESPONSE_MAP[@storage_request.rejection_reason.to_sym]
        end

        def shared_response_base
          {
            "id": @storage_request.id,
            "activityPub": {
              "id": @storage_request.ap_object.uri
            },
            "originalURL": @storage_request.file_url,
            "status": @storage_request.state
          }
        end

        def response_object_success
          shared_response_base.merge({
            "contentType": media_file.content_type,
            "contentLength": media_file.file_size,
            "contentDigest": media_file.sha512,
            "metadata": {
              "height": media_file.height,
              "width": media_file.width
            },
            "extension": Rack::Mime::MIME_TYPES.key(media_file.content_type),
            # TODO: define representations
            "representations": []
          })
        end

        def response_object_rejected
          shared_response_base.merge({
           "reason": {
             "code": @storage_request.rejection_reason,
             "message": rejection_reason
           }
          })
        end
      end
    end
  end
end
