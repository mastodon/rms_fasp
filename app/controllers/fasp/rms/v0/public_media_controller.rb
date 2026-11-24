module Fasp
  module Rms
    module V0
      class PublicMediaController < ApplicationController
        skip_before_action :require_authentication

        before_action :verify_signature_parameter

        def show
          render json: media_file_response

        rescue FaspBase::Error => e
          e.message
        end

        private
        # TODO
        # do we only want to allow a certain set of url pathsegments, like
        # "https://www.example.com/d/567/345" or , "https://www.example.com/s/567/345"
        # or is it completely free?
        #
        # handle different variants
        # add X-Accel-Redirect header with file url
        # return file url
        # request image from image proxy

        def verify_signature_parameter
          url = Addressable::URI.parse(request.url)
          return unless url.query_values["sig"]

          encoded_sig = url.query_values["sig"]
          sig = Base64.decode64(encoded_sig)
          # editing query_values with addressable returns sorted query parameters
          # upper case letters come before lower case letters
          # like "https://www.example.com/query?X=1&Y=2&a=3%b=4"
          url.query_values = url.query_values.except("sig")
          url_string = url.display_uri.to_s

          public_pem = server.public_key_pem
          public_key = OpenSSL::PKey.read(public_pem)
          digest = Digest::SHA256.base64digest(url_string)

          raise FaspBase::Error, "not verified" unless public_key.verify(nil, sig, digest)
        end

        def server
          return unless request.params["namespace"].present?

          FaspBase::Server.find_by(namespace: request.params["namespace"])
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
