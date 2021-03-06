module SSO
  module Server
    module Warden
      module Hooks
        class AfterAuthentication
          include ::SSO::Logging

          attr_reader :user, :warden, :options

          def self.to_proc
            proc do |user, warden, options|
              begin
                new(user: user, warden: warden, options: options).call
              rescue => exception
                ::SSO.config.exception_handler.call exception
                # The show must go on
              end
            end
          end

          def initialize(user:, warden:, options:)
            @user, @warden, @options = user, warden, options
          end

          def call
            debug { 'Starting hook because this is considered the first login of the current session...' }
            request = warden.request
            session = warden.env['rack.session']

            debug { "Generating a passport for user #{user.id.inspect} for the session with the SSO server..." }
            attributes = { owner_id: user.id, ip: request.ip, agent: request.user_agent }

            generation = SSO::Server::Passports.generate attributes
            if generation.success?
              debug { "Passport with ID #{generation.object.inspect} generated successfuly. Persisting it in session..." }
              session[:passport_id] = generation.object
            else
              fail generation.code.inspect + generation.object.inspect
            end

            debug { 'Finished.' }
          end
        end
      end
    end
  end
end
