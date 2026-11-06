module Fasp
  module Rms
    module V0
      class FeaturesController < Fasp::ApiController
        SUPPORTED_CONTENT_TYPES = [
          "image/gif",
          "image/jpeg",
          "image/jxl",
          "image/png",
          "image/webp"
        ].freeze

        def index
          render json: features
        end

        private

        def features
         {
           contentSecurityPolicy: {
             hosts: csp_hosts
           },
           contentTypes: SUPPORTED_CONTENT_TYPES,
           representations: [
             {
               mediaType: "image",
               variants: [
                 {
                   type: "dynamic",
                   definition: "/d/:width/:height.:ext",
                   args: {
                     width: "integer",
                     height: "integer",
                     ext: "string"
                   }
                 }
               ]
             }
           ]
          }
        end

        def csp_hosts
          protocol = request.protocol
          Rails.application.config.x.rms.csp_hosts.map do |host|
            "#{protocol}#{host}"
          end
        end
      end
    end
  end
end
