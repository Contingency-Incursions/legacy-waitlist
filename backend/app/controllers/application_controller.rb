class ApplicationController < ActionController::API
  include ActionController::Helpers
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  include Authentication
  before_action :authenticate!

  rescue_from 'AccessDeniedError' do |exception|
    render json: { error: 'Access Denied' }, status: :forbidden
  end
end
