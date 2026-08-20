class ApplicationController < ActionController::Base
  before_action :ensure_domain

  helper Mitlibraries::Theme::Engine.helpers

  private

  # Appends additional information to the log payload that are not Controller specific
  def append_info_to_payload(payload)
    super
    payload[:host] = request.host
  end

  # redirects herokuapp domains and old domains to preferred domains
  def ensure_domain
    return unless ENV['PREFERRED_DOMAIN']
    return if request.host == ENV['PREFERRED_DOMAIN']

    Rails.logger.info("Handling Domain Redirect: #{request.host}")
    redirect_to "https://#{ENV.fetch('PREFERRED_DOMAIN', nil)}", status: :moved_permanently, allow_other_host: true
  end
end
