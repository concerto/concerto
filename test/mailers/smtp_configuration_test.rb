require "test_helper"

class SmtpConfigurationTest < ActiveSupport::TestCase
  SMTP_ENV_KEYS = %w[
    APP_HOST
    DISABLE_SSL
    MAILER_FROM_ADDRESS
    SMTP_ADDRESS
    SMTP_PORT
    SMTP_DOMAIN
    SMTP_USERNAME
    SMTP_PASSWORD
    SMTP_AUTHENTICATION
    SMTP_TLS
    SMTP_ENABLE_STARTTLS_AUTO
  ].freeze

  class FakeConfig < ActiveSupport::OrderedOptions
    def method_missing(name, *args)
      if name.end_with?("=")
        super
      elsif key?(name)
        self[name]
      else
        self[name] = self.class.new
      end
    end

    def respond_to_missing?(_name, _include_private = false)
      true
    end
  end

  class FakeApplication
    attr_reader :config

    def initialize
      @config = FakeConfig.new
    end

    def configure(&block)
      instance_eval(&block)
    end
  end

  class TestMailer < ApplicationMailer
    def ping
      mail(to: "recipient@example.com", subject: "Ping", body: "pong")
    end
  end

  test "disables email delivery cleanly when SMTP_ADDRESS is unset" do
    config = load_production_config({})

    assert_equal false, config.action_mailer.perform_deliveries
    assert_equal false, config.action_mailer.raise_delivery_errors
    assert_equal({ host: "example.com", protocol: "https" }, config.action_mailer.default_url_options)
  end

  test "treats blank SMTP_ADDRESS as unconfigured" do
    config = load_production_config("SMTP_ADDRESS" => "   ")

    assert_equal false, config.action_mailer.perform_deliveries
    assert_equal false, config.action_mailer.raise_delivery_errors
  end

  test "configures default_url_options from APP_HOST and DISABLE_SSL" do
    ssl_config = load_production_config("APP_HOST" => "signage.example.com")
    assert_equal({ host: "signage.example.com", protocol: "https" }, ssl_config.action_mailer.default_url_options)

    http_config = load_production_config("APP_HOST" => "signage.example.com", "DISABLE_SSL" => "true")
    assert_equal({ host: "signage.example.com", protocol: "http" }, http_config.action_mailer.default_url_options)

    port_config = load_production_config("APP_HOST" => "signage.example.com:8080", "DISABLE_SSL" => "true")
    assert_equal(
      { host: "signage.example.com", protocol: "http", port: 8080 },
      port_config.action_mailer.default_url_options
    )

    url_config = load_production_config("APP_HOST" => "http://signage.example.com:3000/")
    assert_equal(
      { host: "signage.example.com", protocol: "http", port: 3000 },
      url_config.action_mailer.default_url_options
    )

    default_port_url_config = load_production_config("APP_HOST" => "https://signage.example.com:443")
    assert_equal(
      { host: "signage.example.com", protocol: "https" },
      default_port_url_config.action_mailer.default_url_options
    )
  end

  test "falls back gracefully when APP_HOST is blank or invalid URI" do
    blank_config = load_production_config("APP_HOST" => "  ")
    assert_equal({ host: "example.com", protocol: "https" }, blank_config.action_mailer.default_url_options)

    invalid_config = load_production_config("APP_HOST" => "invalid host name")
    assert_equal({ host: "invalid host name", protocol: "https" }, invalid_config.action_mailer.default_url_options)
  end

  test "configures authenticated SMTP delivery with sensible defaults" do
    config = load_production_config(
      "APP_HOST" => "signage.example.com",
      "SMTP_ADDRESS" => "smtp.example.com",
      "SMTP_USERNAME" => "mailer-user",
      "SMTP_PASSWORD" => "secret-pass"
    )

    assert_equal :smtp, config.action_mailer.delivery_method
    assert_equal true, config.action_mailer.perform_deliveries
    assert_equal true, config.action_mailer.raise_delivery_errors
    assert_equal(
      {
        address: "smtp.example.com",
        port: 587,
        domain: "signage.example.com",
        user_name: "mailer-user",
        password: "secret-pass",
        authentication: :plain,
        enable_starttls_auto: true
      },
      config.action_mailer.smtp_settings
    )
  end

  test "supports unauthenticated internal SMTP relays by omitting nil auth keys" do
    config = load_production_config(
      "SMTP_ADDRESS" => "relay.internal",
      "SMTP_PORT" => "25",
      "SMTP_ENABLE_STARTTLS_AUTO" => "false"
    )

    assert_equal :smtp, config.action_mailer.delivery_method
    assert_equal(
      {
        address: "relay.internal",
        port: 25,
        enable_starttls_auto: false
      },
      config.action_mailer.smtp_settings
    )
    assert_not config.action_mailer.smtp_settings.key?(:user_name)
    assert_not config.action_mailer.smtp_settings.key?(:password)
    assert_not config.action_mailer.smtp_settings.key?(:authentication)
    assert_not config.action_mailer.smtp_settings.key?(:domain)
  end

  test "supports explicit SMTP_DOMAIN and case-insensitive SMTP_AUTHENTICATION" do
    config = load_production_config(
      "APP_HOST" => "signage.example.com",
      "SMTP_ADDRESS" => "smtp.example.com",
      "SMTP_DOMAIN" => "mail.example.org",
      "SMTP_USERNAME" => "user",
      "SMTP_PASSWORD" => "pass",
      "SMTP_AUTHENTICATION" => "LOGIN"
    )

    assert_equal "mail.example.org", config.action_mailer.smtp_settings[:domain]
    assert_equal :login, config.action_mailer.smtp_settings[:authentication]
  end

  test "treats SMTP_AUTHENTICATION=none as unauthenticated even when credentials are set" do
    config = load_production_config(
      "SMTP_ADDRESS" => "relay.internal",
      "SMTP_USERNAME" => "unused-user",
      "SMTP_PASSWORD" => "unused-pass",
      "SMTP_AUTHENTICATION" => "none"
    )

    assert_not config.action_mailer.smtp_settings.key?(:authentication)
    assert_not config.action_mailer.smtp_settings.key?(:user_name)
    assert_not config.action_mailer.smtp_settings.key?(:password)
  end

  test "configures implicit TLS on port 465 when SMTP_TLS is true and disables STARTTLS" do
    config = load_production_config(
      "SMTP_ADDRESS" => "smtp.example.com",
      "SMTP_TLS" => "true",
      "SMTP_USERNAME" => "user",
      "SMTP_PASSWORD" => "pass"
    )

    assert_equal 465, config.action_mailer.smtp_settings[:port]
    assert_equal true, config.action_mailer.smtp_settings[:tls]
    assert_equal false, config.action_mailer.smtp_settings[:enable_starttls_auto]

    custom_port_config = load_production_config(
      "SMTP_ADDRESS" => "smtp.example.com",
      "SMTP_TLS" => "true",
      "SMTP_PORT" => "2465"
    )
    assert_equal 2465, custom_port_config.action_mailer.smtp_settings[:port]
  end

  test "ApplicationMailer uses MAILER_FROM_ADDRESS with Concerto fallback" do
    with_env("MAILER_FROM_ADDRESS" => nil) do
      mail = TestMailer.ping
      assert_equal [ "no-reply@example.com" ], mail.from
      assert_equal "Concerto <no-reply@example.com>", mail[:from].value
    end

    with_env("MAILER_FROM_ADDRESS" => "   ") do
      mail = TestMailer.ping
      assert_equal "Concerto <no-reply@example.com>", mail[:from].value
    end

    with_env("MAILER_FROM_ADDRESS" => "Concerto Signage <signage@myorg.edu>") do
      mail = TestMailer.ping
      assert_equal [ "signage@myorg.edu" ], mail.from
      assert_equal "Concerto Signage <signage@myorg.edu>", mail[:from].value
    end
  end

  test "Devise mailer_sender uses MAILER_FROM_ADDRESS with Concerto fallback" do
    assert_not_equal "please-change-me-at-config-initializers-devise@example.com", Devise.mailer_sender

    devise_initializer_path = Rails.root.join("config/initializers/devise.rb").to_s

    with_env("MAILER_FROM_ADDRESS" => nil) do
      fake_config = FakeConfig.new
      Devise.stub(:setup, ->(&block) { block.call(fake_config) }) do
        load devise_initializer_path
      end
      assert_equal "Concerto <no-reply@example.com>", fake_config.mailer_sender
    end

    with_env("MAILER_FROM_ADDRESS" => "noreply@myorg.edu") do
      fake_config = FakeConfig.new
      Devise.stub(:setup, ->(&block) { block.call(fake_config) }) do
        load devise_initializer_path
      end
      assert_equal "noreply@myorg.edu", fake_config.mailer_sender
    end

    Devise.stub(:mailer_sender, "noreply@myorg.edu") do
      mail = Devise::Mailer.reset_password_instructions(users(:admin), "fake-token")
      assert_equal [ "noreply@myorg.edu" ], mail.from
      assert_includes mail.body.encoded, "fake-token"
    end
  end

  private

  def load_production_config(env_overrides)
    production_config_path = Rails.root.join("config/environments/production.rb").to_s
    fake_app = FakeApplication.new
    with_env(env_overrides) do
      Rails.stub(:application, fake_app) do
        load production_config_path
      end
    end
    fake_app.config
  end

  def with_env(overrides)
    saved = SMTP_ENV_KEYS.index_with { |key| ENV[key] }
    SMTP_ENV_KEYS.each { |key| ENV.delete(key) }
    overrides.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
    yield
  ensure
    saved.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end
end
