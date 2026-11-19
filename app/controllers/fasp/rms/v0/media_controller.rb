module Fasp
  module Rms
    module V0
      class MediaController < Fasp::ApiController
        before_action :storage_request

        def show
          render json: media_response_object

        rescue => error
          head :not_found
        end

        private

        def media_response_object
          raise error unless storage_request

          case storage_request.state
          when "enqueued", "processing"
            response_object_processing(storage_request.state)
          when "ok"
            response_object_success
          when "rejected"
            response_object_rejected
          end
        end

        def storage_request
          @storage_request = StorageRequest.find_by(id: params[:id])
        end

        def media_file
          @media_file = @storage_request.media_file
        end

        def rejection_reason
          return unless @storage_request.rejection_reason

          MediaFile::REJECTION_RESPONSE_MAP[@storage_request.rejection_reason.to_sym]
        end

        def shared_response_base
          {
            "id": @storage_request.id,
            "activityPub": {
              "id": @storage_request.ap_object_id
            },
            "originalURL": @storage_request.file_url,
          }
        end

        def response_object_success
          shared_response_base.merge({
            "status": "ok",
            "contentType": media_file.content_type,
            "contentLength": media_file.file_size,
            "contentDigest": media_file.sha512,
            "metadata": {
              "height": media_file.height,
              "width": media_file.width
            },
            # depending on what we want
            # Mime::EXTENSION_LOOKUP.key('image/jpeg') returns `jpeg`
            # Rack::Mime::MIME_TYPES.key('image/jpeg') returns `.jpeg`
            "extension": Rack::Mime::MIME_TYPES.key(media_file.content_type),
            # TODO: define representations
            "representations": []
          })
        end

        def response_object_processing(state)
          shared_response_base.merge({
           "status": state
          })
        end

        def response_object_rejected
          shared_response_base.merge({
           "status": "rejected",
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
