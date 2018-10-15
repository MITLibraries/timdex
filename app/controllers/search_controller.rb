class SearchController < ApplicationController
  respond_to :json
  before_action :ensure_json!
  before_action :authenticate_user!, except: 'ping'

  def search
    # do actual searching stuff here and return something useful
    # for now just render a static json thing for testing
    render json: '[{"id": "aleph001"}, {"id": "aleph002"}]'
  end

  def ping
    render json: 'pong'
  end

  def ensure_json!
    request.format = :json
  end
end
