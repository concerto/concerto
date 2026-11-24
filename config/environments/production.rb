require "active_support/core_ext/integer/time"
require "uri"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Allow admins to control ssl via the DISABLE_SSL environment variable.
  config.assume_ssl = ENV["DISABLE_SSL"].blank?

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # Allow admins to control ssl via the DISABLE_SSL environment variable.
  config.force_ssl = ENV["DISABLE_SSL"].blank?

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Configure Action Mailer URL options from APP_HOST (or fall back safely so
  # boot and asset precompilation work without runtime environment variables).
  mailer_protocol = ENV["DISABLE_SSL"].blank? ? "https" : "http"
  app_host = ENV["APP_HOST"].presence
  if app_host
    default_url_options = begin
      parsed_app_host = URI.parse(app_host.include?("://") ? app_host : "#{mailer_protocol}://#{app_host}")
      options = {
        host: parsed_app_host.host || app_host,
        protocol: parsed_app_host.scheme || mailer_protocol
      }
      if parsed_app_host.port && parsed_app_host.port != parsed_app_host.default_port
        options[:port] = parsed_app_host.port
      end
      options
    rescue URI::InvalidURIError
      { host: app_host, protocol: mailer_protocol }
    end
    config.action_mailer.default_url_options = default_url_options
  else
    config.action_mailer.default_url_options = { host: "example.com", protocol: mailer_protocol }
  end

  # Configure outgoing SMTP delivery when SMTP_ADDRESS is set; otherwise disable
  # deliveries so mailers do not fail trying to connect to localhost:25.
  if ENV["SMTP_ADDRESS"].present?
    smtp_tls = ENV["SMTP_TLS"] == "true"
    raw_smtp_auth = ENV["SMTP_AUTHENTICATION"].presence
    if raw_smtp_auth&.casecmp?("none")
      smtp_username = nil
      smtp_password = nil
      smtp_auth = nil
    else
      smtp_username = ENV["SMTP_USERNAME"].presence
      smtp_password = ENV["SMTP_PASSWORD"].presence
      smtp_auth = raw_smtp_auth || ("plain" if smtp_username || smtp_password)
    end

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.smtp_settings = {
      address: ENV["SMTP_ADDRESS"].presence,
      port: (ENV["SMTP_PORT"].presence || (smtp_tls ? 465 : 587)).to_i,
      domain: ENV["SMTP_DOMAIN"].presence || (default_url_options[:host] if app_host),
      user_name: smtp_username,
      password: smtp_password,
      authentication: smtp_auth&.downcase&.to_sym,
      tls: (true if smtp_tls),
      enable_starttls_auto: smtp_tls ? false : ENV["SMTP_ENABLE_STARTTLS_AUTO"] != "false"
    }.compact
  else
    config.action_mailer.perform_deliveries = false
    config.action_mailer.raise_delivery_errors = false
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
