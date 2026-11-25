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
          storage = StorageRequest.find_by(media_file_id: params[:id])
          response_failure unless storage.state == "ok"

          @file_url = storage.file_url
          # how do we store/load the actual file?
          # media_file_id = storage.media_file
          build_signed_image_proxy_url
        end

        def get_options
          # this only works, when we allow only one processing Option
          # need fix
          variants = request.params[:any]
          variants.gsub!('/', ':')
        end

        def build_signed_image_proxy_url
          variants = get_options
          signature = build_encoded_path
          @encoded_url
          url = "#{ENV.fetch("IMGPROXY_ENDPOINT")}/#{signature}/#{variants}/#{@encoded_url}.#{request.params[:ext]}"
        end

        def build_encoded_path
          salt = ENV.fetch("IMGPROXY_SALT")
          key = ENV.fetch("IMGPROXY_KEY")
          @encoded_url = Base64.encode64(@file_url)
          path = "#{salt}/#{@encoded_url}.#{request.params[:ext]}"
          digest = OpenSSL::Digest.new("sha256")
          hmac = Base64.urlsafe_encode64(OpenSSL::HMAC.digest(digest, key, "#{salt}#{path}")).tr("=", "")
          signed_path = "/#{hmac}#{path}"
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
