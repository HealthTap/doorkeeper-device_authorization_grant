# frozen_string_literal: true

module Doorkeeper
  module DeviceAuthorizationGrant
    module Concerns
      # This concerns allows us a more modular approach to customizing controller logic. By placing the methods in a
      # concern, we can include this in an existing controller that inherits from ApplicationController (or any other)
      module DeviceCodesMethods
        extend ActiveSupport::Concern

        def create
          headers.merge!(authorize_response.headers)
          render(json: authorize_response.body, status: authorize_response.status)
        rescue Doorkeeper::Errors::DoorkeeperError => e
          handle_token_exception(e)
        end

        private

        def authorize_response
          @authorize_response ||= strategy.authorize
        end

        # @return [Request::DeviceAuthorization]
        def strategy
          @strategy ||= Request::DeviceAuthorization.new(server)
        end
      end
    end
  end
end
