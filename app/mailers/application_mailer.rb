class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV["MAILER_FROM_ADDRESS"].presence || "Concerto <no-reply@example.com>" }
  layout "mailer"
end
