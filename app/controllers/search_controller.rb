class SearchController < ApplicationController
  respond_to :json
  before_action :ensure_json!
  before_action :authenticate_user!, except: 'ping'

  def search
    client = Elasticsearch::Client.new log: false
    @results = client.search(q: params[:q])
  end

  def record
    client = Elasticsearch::Client.new log: false
    @results = client.get(index: 'timdex', id: params[:id])
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    render json: 'record not found', status: :not_found
  end

  def ping
    render json: 'pong'
  end

  def ensure_json!
    request.format = :json
  end
end
