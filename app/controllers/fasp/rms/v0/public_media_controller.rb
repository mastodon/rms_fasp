module Fasp
  module Rms
    module V0
      class PublicMediaController < ApplicationController
        skip_before_action :require_authentication

        include ImgProxyUrlConcern

        def show
          return unless verify_signature_parameter

          img_proxy_url = build_img_proxy_url
          set_x_accel_redirect_header(img_proxy_url)

          redirect_to img_proxy_url, allow_other_host: true

        rescue ActiveRecord::RecordNotFound
          respond_to do |format|
            format.json { head 404 }
          end
        rescue FaspBase::Error
          respond_to do |format|
            format.json { head 401 }
          end
        end

        private

        def set_x_accel_redirect_header(redirect_url)
          response.headers["X-Accel-Redirect"] = redirect_url
        end
      end
    end
  end
end
