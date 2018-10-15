# if a pr build, set the default mailer url by reading the heroku_app_name
def mail_host
  if ENV['PR_BUILD'] && ENV['HEROKU_APP_NAME']
    "#{ENV['HEROKU_APP_NAME']}.herokuapp.com"
  else
    ENV['EMAIL_URL_HOST']
  end
end

Rails.application.config.action_mailer.default_url_options = { host: mail_host }
