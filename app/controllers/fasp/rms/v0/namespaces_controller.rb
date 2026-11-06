module Fasp
  module Rms
    module V0
      class NamespacesController < Fasp::ApiController
        def show
          render json: { namespace: current_server.namespace }
        end
      end
    end
  end
end
