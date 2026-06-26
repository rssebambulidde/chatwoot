# frozen_string_literal: true

require Rails.root.join('lib/brevo_api_delivery_method')

Rails.application.configure do
  #########################################
  # Configuration Related to Action Mailer
  #########################################

  ActionMailer::Base.add_delivery_method :brevo_api, BrevoApiDeliveryMethod

  # We need the application frontend url to be used in our emails
  config.action_mailer.default_url_options = { host: ENV['FRONTEND_URL'] } if ENV['FRONTEND_URL'].present?
  # We load certain mailer templates from our database. This ensures changes to it is reflected immediately
  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  if !Rails.env.test? && ENV['BREVO_API_KEY'].present?
    # Brevo HTTP API — works on hosts that block outbound SMTP (e.g. Railway)
    config.action_mailer.delivery_method = :brevo_api
    config.action_mailer.brevo_api_settings = { api_key: ENV['BREVO_API_KEY'] }
  else
    # Config related to smtp
    smtp_settings = {
      address: ENV.fetch('SMTP_ADDRESS', 'localhost'),
      port: ENV.fetch('SMTP_PORT', 587)
    }

    smtp_settings[:authentication] = ENV.fetch('SMTP_AUTHENTICATION', 'login').to_sym if ENV['SMTP_AUTHENTICATION'].present?
    smtp_settings[:domain] = ENV['SMTP_DOMAIN'] if ENV['SMTP_DOMAIN'].present?
    smtp_settings[:user_name] = ENV.fetch('SMTP_USERNAME', nil)
    smtp_settings[:password] = ENV.fetch('SMTP_PASSWORD', nil)
    smtp_settings[:enable_starttls_auto] = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO', true))
    smtp_settings[:openssl_verify_mode] = ENV['SMTP_OPENSSL_VERIFY_MODE'] if ENV['SMTP_OPENSSL_VERIFY_MODE'].present?
    smtp_settings[:ssl] = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SMTP_SSL', true)) if ENV['SMTP_SSL']
    smtp_settings[:tls] = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SMTP_TLS', true)) if ENV['SMTP_TLS']
    smtp_settings[:open_timeout] = ENV['SMTP_OPEN_TIMEOUT'].to_i if ENV['SMTP_OPEN_TIMEOUT'].present?
    smtp_settings[:read_timeout] = ENV['SMTP_READ_TIMEOUT'].to_i if ENV['SMTP_READ_TIMEOUT'].present?

    config.action_mailer.delivery_method = :smtp unless Rails.env.test?
    config.action_mailer.smtp_settings = smtp_settings

    # Use sendmail if using postfix for email
    config.action_mailer.delivery_method = :sendmail if ENV['SMTP_ADDRESS'].blank?
  end

  # You can use letter opener for your local development by setting the environment variable
  config.action_mailer.delivery_method = :letter_opener if Rails.env.development? && ENV['LETTER_OPENER']

  # Re-apply after full boot so Railway-injected env vars are visible to Sidekiq workers.
  config.after_initialize do
    next if Rails.env.test?
    next if Rails.env.development? && ENV['LETTER_OPENER'].present?

    if ENV['BREVO_API_KEY'].present?
      ActionMailer::Base.delivery_method = :brevo_api
      ActionMailer::Base.brevo_api_settings = { api_key: ENV['BREVO_API_KEY'] }
      Rails.logger.info '[Mailer] Using Brevo API delivery'
    else
      Rails.logger.warn "[Mailer] BREVO_API_KEY missing; using #{ActionMailer::Base.delivery_method}"
    end
  end

  #########################################
  # Configuration Related to Action MailBox
  #########################################

  # Set this to appropriate ingress service for which the options are :
  # :relay for Exim, Postfix, Qmail
  # :mailgun for Mailgun
  # :mandrill for Mandrill
  # :postmark for Postmark
  # :sendgrid for Sendgrid
  # :ses for Amazon SES
  config.action_mailbox.ingress = ENV.fetch('RAILS_INBOUND_EMAIL_SERVICE', 'relay').to_sym

  # Amazon SES ActionMailbox configuration
  config.action_mailbox.ses.subscribed_topic = ENV['ACTION_MAILBOX_SES_SNS_TOPIC'] if ENV['ACTION_MAILBOX_SES_SNS_TOPIC'].present?
end
