class ApplicationController < ActionController::Base
  before_action :ensure_domain

  helper Tesseract::Engine.helpers

  private

  # redirects herokuapp domains and old domains to preferred domains
  def ensure_domain
    return unless ENV['PREFERRED_DOMAIN']
    return if request.host == ENV['PREFERRED_DOMAIN']

    Rails.logger.info("Handling Domain Redirect: #{request.host}")
    redirect_to "https://#{ENV['PREFERRED_DOMAIN']}", status: :moved_permanently, allow_other_host: true
  end
end
