module Fasp
  module Rms
    module V0
      class BatchesController < Fasp::ApiController
        def create
          StorageRequest.transaction do
            @ap_object = find_or_create_ap_object
            @storage_requests = find_or_create_storage_requests
          end
          ProcessApObjectJob.perform_later(@ap_object)

          render json: { media: storage_request_results }, status: :accepted
        rescue ActiveRecord::RecordInvalid
          head :unprocessable_content
        end

        private

        def find_or_create_ap_object
          ApObject.find_or_create_by!(
            uri: params.dig(:activityPub, :id)
          )
        end

        def find_or_create_storage_requests
          (params[:urls] || []).map do |url|
            @ap_object.storage_requests.find_or_create_by!(
              fasp_base_server: current_server,
              file_url: url
            )
          end
        end

        def storage_request_results
          @storage_requests.map do |storage_request|
            {
              id: storage_request.id,
              url: storage_request.file_url
            }
          end
        end
      end
    end
  end
end
