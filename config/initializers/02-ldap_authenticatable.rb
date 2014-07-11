if ActiveRecord::Base.connection.table_exists? 'concerto_configs' and !ConcertoConfig[:ldap_host].blank?
  require 'net/ldap'
  require 'devise/strategies/authenticatable'

  module Devise
    module Strategies
      class LdapAuthenticatable < Authenticatable
        def authenticate!
          if params[:user]
            if self.class.verified?(email, password)
              user = User.find_by_email(email)
              success!(user)
            else
              fail(:invalid_login)
            end
          end
        end

        def self.verified?(user, password)
          begin
            ldap = Net::LDAP.new
            if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
              ldap.host = ConcertoConfig[:ldap_host] 
              ldap.port = ConcertoConfig[:ldap_port] 
            end
            ldap.auth user, password
            verified = ldap.bind
          rescue => e
            Rails.logger.error("Unable to authenticate using LDAP - #{e.message}")
            verified = false
          end
          return verified
        end

        def email
          params[:user][:email]
        end

        def password
          params[:user][:password]
        end

        def user_data
          {:email => email, :password => password, :password_confirmation => password}
        end
      end
    end
  end

  Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)
end
