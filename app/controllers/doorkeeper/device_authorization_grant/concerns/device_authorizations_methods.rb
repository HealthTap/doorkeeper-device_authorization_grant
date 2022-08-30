# frozen_string_literal: true

module Doorkeeper
  module DeviceAuthorizationGrant
    module Concerns
      # This concerns allows us a more modular approach to customizing controller logic. By placing the methods in a
      # concern, we can include this in an existing controller that inherits from ApplicationController (or any other)
      module DeviceAuthorizationsMethods
        extend ActiveSupport::Concern

        def index
          respond_to do |format|
            format.html
            format.json { head :no_content }
          end
        end

        def authorize
          device_grant_model.transaction do
            device_grant = device_grant_model.lock.find_by(user_code: user_code)
            return authorization_error_response(:invalid_user_code) if device_grant.nil?
            return authorization_error_response(:expired_user_code) if device_grant.expired?

            device_grant.update!(user_code: nil, resource_owner_id: current_resource_owner.id)
          end

          authorization_success_response
        end

        private

        def authorization_success_response
          respond_to do |format|
            notice = I18n.t(:success, scope: i18n_flash_scope(:authorize))
            format.html { redirect_to oauth_device_authorizations_index_url, notice: notice }
            format.json { head :no_content }
          end
        end

        # @param error_message_key [Symbol]
        def authorization_error_response(error_message_key)
          respond_to do |format|
            notice = I18n.t(error_message_key, scope: i18n_flash_scope(:authorize))
            format.html { redirect_to oauth_device_authorizations_index_url, notice: notice }
            format.json do
              render json: { errors: [notice] }, status: :unprocessable_entity
            end
          end
        end

        # @return [Class]
        def device_grant_model
          @device_grant_model ||= Doorkeeper::DeviceAuthorizationGrant.configuration.device_grant_model
        end

        # @return [String, nil]
        def user_code
          params[:user_code]
        end

        # @param action [Symbol]
        # @return [Array<Symbol>]
        def i18n_flash_scope(action)
          %I[doorkeeper flash device_codes #{action}]
        end
      end
    end
  end
end
