require "uri"

# Configure production Action Mailer URL options and SMTP delivery from
# environment variables, keeping config/environments/production.rb stock.
module ActionMailerConfiguration
  module_function

  def apply!(config = Rails.application.config.action_mailer, env: ENV)
    settings = build(env)
    apply_to(config, settings)

    # action_mailer.set_configs runs before config/initializers/*, so also apply
    # via the ActionMailer load hook to ensure ActionMailer::Base reflects these
    # settings regardless of when it is loaded.
    ActiveSupport.on_load(:action_mailer) do
      ActionMailerConfiguration.apply_to(self, settings)
    end

    settings
  end

  def apply_to(target, settings)
    target.default_url_options = settings[:default_url_options]
    target.perform_deliveries = settings[:perform_deliveries]
    target.raise_delivery_errors = settings[:raise_delivery_errors]
    if settings.key?(:delivery_method)
      target.delivery_method = settings[:delivery_method]
      target.smtp_settings = settings[:smtp_settings]
    end
  end

  def build(env = ENV)
    url_options = default_url_options(env)
    settings = { default_url_options: url_options }

    if env["SMTP_ADDRESS"].present?
      settings.merge(
        delivery_method: :smtp,
        perform_deliveries: true,
        raise_delivery_errors: true,
        smtp_settings: smtp_settings(env, default_domain: (url_options[:host] if env["APP_HOST"].present?))
      )
    else
      settings.merge(
        perform_deliveries: false,
        raise_delivery_errors: false
      )
    end
  end

  def default_url_options(env = ENV)
    protocol = env["DISABLE_SSL"].blank? ? "https" : "http"
    app_host = env["APP_HOST"].presence
    return { host: "example.com", protocol: protocol } unless app_host

    parsed = URI.parse(app_host.include?("://") ? app_host : "#{protocol}://#{app_host}")
    options = {
      host: parsed.host || app_host,
      protocol: parsed.scheme || protocol
    }
    if parsed.port && parsed.port != parsed.default_port
      options[:port] = parsed.port
    end
    options
  rescue URI::InvalidURIError
    { host: app_host, protocol: protocol }
  end

  def smtp_settings(env = ENV, default_domain: nil)
    smtp_tls = env["SMTP_TLS"] == "true"
    raw_auth = env["SMTP_AUTHENTICATION"].presence

    if raw_auth&.casecmp?("none")
      username = nil
      password = nil
      authentication = nil
    else
      username = env["SMTP_USERNAME"].presence
      password = env["SMTP_PASSWORD"].presence
      authentication = raw_auth || ("plain" if username || password)
    end

    {
      address: env["SMTP_ADDRESS"].presence,
      port: (env["SMTP_PORT"].presence || (smtp_tls ? 465 : 587)).to_i,
      domain: env["SMTP_DOMAIN"].presence || default_domain,
      user_name: username,
      password: password,
      authentication: authentication&.downcase&.to_sym,
      tls: (true if smtp_tls),
      enable_starttls_auto: smtp_tls ? false : env["SMTP_ENABLE_STARTTLS_AUTO"] != "false"
    }.compact
  end
end

ActionMailerConfiguration.apply! if Rails.env.production?
