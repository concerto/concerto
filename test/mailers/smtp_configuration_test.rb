require "test_helper"

class SmtpConfigurationTest < ActiveSupport::TestCase
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

  class TestMailer < ApplicationMailer
    def ping
      mail(to: "recipient@example.com", subject: "Ping", body: "pong")
    end
  end

  test "disables email delivery cleanly when SMTP_ADDRESS is unset" do
    settings = ActionMailerConfiguration.build({})

    assert_equal false, settings[:perform_deliveries]
    assert_equal false, settings[:raise_delivery_errors]
    assert_not settings.key?(:delivery_method)
    assert_not settings.key?(:smtp_settings)
    assert_equal({ host: "example.com", protocol: "https" }, settings[:default_url_options])
  end

  test "treats blank SMTP_ADDRESS as unconfigured" do
    settings = ActionMailerConfiguration.build("SMTP_ADDRESS" => "   ")

    assert_equal false, settings[:perform_deliveries]
    assert_equal false, settings[:raise_delivery_errors]
    assert_not settings.key?(:smtp_settings)
  end

  test "configures default_url_options from APP_HOST and DISABLE_SSL" do
    assert_equal(
      { host: "signage.example.com", protocol: "https" },
      ActionMailerConfiguration.default_url_options("APP_HOST" => "signage.example.com")
    )

    assert_equal(
      { host: "signage.example.com", protocol: "http" },
      ActionMailerConfiguration.default_url_options("APP_HOST" => "signage.example.com", "DISABLE_SSL" => "true")
    )

    assert_equal(
      { host: "signage.example.com", protocol: "http", port: 8080 },
      ActionMailerConfiguration.default_url_options("APP_HOST" => "signage.example.com:8080", "DISABLE_SSL" => "true")
    )

    assert_equal(
      { host: "signage.example.com", protocol: "http", port: 3000 },
      ActionMailerConfiguration.default_url_options("APP_HOST" => "http://signage.example.com:3000/")
    )

    assert_equal(
      { host: "signage.example.com", protocol: "https" },
      ActionMailerConfiguration.default_url_options("APP_HOST" => "https://signage.example.com:443")
    )
  end

  test "falls back gracefully when APP_HOST is blank or invalid URI" do
    assert_equal(
      { host: "example.com", protocol: "https" },
      ActionMailerConfiguration.default_url_options("APP_HOST" => "  ")
    )

    assert_equal(
      { host: "invalid host name", protocol: "https" },
      ActionMailerConfiguration.default_url_options("APP_HOST" => "invalid host name")
    )
  end

  test "configures authenticated SMTP delivery with sensible defaults" do
    settings = ActionMailerConfiguration.build(
      "APP_HOST" => "signage.example.com",
      "SMTP_ADDRESS" => "smtp.example.com",
      "SMTP_USERNAME" => "mailer-user",
      "SMTP_PASSWORD" => "secret-pass"
    )

    assert_equal :smtp, settings[:delivery_method]
    assert_equal true, settings[:perform_deliveries]
    assert_equal true, settings[:raise_delivery_errors]
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
      settings[:smtp_settings]
    )
  end

  test "supports unauthenticated internal SMTP relays by omitting nil auth keys" do
    settings = ActionMailerConfiguration.build(
      "SMTP_ADDRESS" => "relay.internal",
      "SMTP_PORT" => "25",
      "SMTP_ENABLE_STARTTLS_AUTO" => "false"
    )

    assert_equal :smtp, settings[:delivery_method]
    assert_equal(
      {
        address: "relay.internal",
        port: 25,
        enable_starttls_auto: false
      },
      settings[:smtp_settings]
    )
    assert_not settings[:smtp_settings].key?(:user_name)
    assert_not settings[:smtp_settings].key?(:password)
    assert_not settings[:smtp_settings].key?(:authentication)
    assert_not settings[:smtp_settings].key?(:domain)
  end

  test "supports explicit SMTP_DOMAIN and case-insensitive SMTP_AUTHENTICATION" do
    settings = ActionMailerConfiguration.build(
      "APP_HOST" => "signage.example.com",
      "SMTP_ADDRESS" => "smtp.example.com",
      "SMTP_DOMAIN" => "mail.example.org",
      "SMTP_USERNAME" => "user",
      "SMTP_PASSWORD" => "pass",
      "SMTP_AUTHENTICATION" => "LOGIN"
    )

    assert_equal "mail.example.org", settings[:smtp_settings][:domain]
    assert_equal :login, settings[:smtp_settings][:authentication]
  end

  test "treats SMTP_AUTHENTICATION=none as unauthenticated even when credentials are set" do
    settings = ActionMailerConfiguration.build(
      "SMTP_ADDRESS" => "relay.internal",
      "SMTP_USERNAME" => "unused-user",
      "SMTP_PASSWORD" => "unused-pass",
      "SMTP_AUTHENTICATION" => "none"
    )

    assert_not settings[:smtp_settings].key?(:authentication)
    assert_not settings[:smtp_settings].key?(:user_name)
    assert_not settings[:smtp_settings].key?(:password)
  end

  test "configures implicit TLS on port 465 when SMTP_TLS is true and disables STARTTLS" do
    settings = ActionMailerConfiguration.build(
      "SMTP_ADDRESS" => "smtp.example.com",
      "SMTP_TLS" => "true",
      "SMTP_USERNAME" => "user",
      "SMTP_PASSWORD" => "pass"
    )

    assert_equal 465, settings[:smtp_settings][:port]
    assert_equal true, settings[:smtp_settings][:tls]
    assert_equal false, settings[:smtp_settings][:enable_starttls_auto]

    custom_port_settings = ActionMailerConfiguration.build(
      "SMTP_ADDRESS" => "smtp.example.com",
      "SMTP_TLS" => "true",
      "SMTP_PORT" => "2465"
    )
    assert_equal 2465, custom_port_settings[:smtp_settings][:port]
  end

  test "apply_to applies settings to both config options and ActionMailer-like targets" do
    configured_settings = ActionMailerConfiguration.build(
      "APP_HOST" => "signage.example.com",
      "SMTP_ADDRESS" => "smtp.example.com",
      "SMTP_USERNAME" => "mailer-user",
      "SMTP_PASSWORD" => "secret-pass"
    )

    mailer_target_class = Struct.new(
      :default_url_options,
      :perform_deliveries,
      :raise_delivery_errors,
      :delivery_method,
      :smtp_settings
    )

    [ ActiveSupport::OrderedOptions.new, mailer_target_class.new ].each do |target|
      ActionMailerConfiguration.apply_to(target, configured_settings)
      assert_equal({ host: "signage.example.com", protocol: "https" }, target.default_url_options)
      assert_equal :smtp, target.delivery_method
      assert_equal true, target.perform_deliveries
      assert_equal true, target.raise_delivery_errors
      assert_equal configured_settings[:smtp_settings], target.smtp_settings
    end

    disabled_settings = ActionMailerConfiguration.build({})
    disabled_target = mailer_target_class.new
    ActionMailerConfiguration.apply_to(disabled_target, disabled_settings)
    assert_equal({ host: "example.com", protocol: "https" }, disabled_target.default_url_options)
    assert_equal false, disabled_target.perform_deliveries
    assert_equal false, disabled_target.raise_delivery_errors
    assert_nil disabled_target.delivery_method
    assert_nil disabled_target.smtp_settings

    %i[default_url_options= perform_deliveries= raise_delivery_errors= delivery_method= smtp_settings=].each do |setter|
      assert_respond_to ActionMailer::Base, setter
    end
  end

  test "does not override test environment mailer delivery settings on boot" do
    assert_equal :test, ActionMailer::Base.delivery_method
    assert_equal true, ActionMailer::Base.perform_deliveries
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

  def with_env(overrides)
    saved = overrides.keys.index_with { |key| ENV[key] }
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
