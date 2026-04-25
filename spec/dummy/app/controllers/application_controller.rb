# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  attr_accessor :resource

  def current_user
    @current_user
  end

  attr_writer :current_user
end
