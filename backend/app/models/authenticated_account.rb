# frozen_string_literal: true

class AuthenticatedAccount
  attr_accessor :id, :access

  def initialize(params = {})
    @id = params[:id]
    @access = params[:access]
  end
end
