module Fasp
  class ApiController < ::ActionController::Base
    include FaspBase::ApiAuthentication

    skip_forgery_protection
  end
end
