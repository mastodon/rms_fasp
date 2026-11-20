module Fasp
  module Rms
    module V0
      class PublicMediaController < Fasp::ApiController
        before_action :validate_signature_parameter

        def show
          render json: media_file_response

        rescue => error
          response_failure
        end

        private

        # TODO
        # needs to validate signature header as well
        # (and build signature header for the tests)
        # handle different variants
        # return file

        def validate_signature_parameter
          url = Addressable::URI.parse(request.url)
          sig = url.query_values["sig"]
          url.query_values = url.query_values.except("sig")
          url_string = url.to_s
          url_string.chomp!("?") if url.query_values.count == 0
          check = Digest::SHA256.base64digest(url_string)
          raise error unless sig == check

          true
        end

        def media_file_response
          variants = request.params[:any]
          variants.chomp!(".")

          MediaFile.find(request.params[:id]) if variants.empty?
        end

        def response_failure
          {
            "status": "failure",
            "error": "NotFound"
          }
        end
      end
    end
  end
end
