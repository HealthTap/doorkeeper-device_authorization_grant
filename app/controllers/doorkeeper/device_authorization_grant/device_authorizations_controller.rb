# frozen_string_literal: true

module Doorkeeper
  module DeviceAuthorizationGrant
    # The Device Authorizations controller provides a simple interface which
    # allows authenticated resource owners to authorize devices, by providing
    # a user code.
    class DeviceAuthorizationsController < Doorkeeper::ApplicationController
      before_action :authenticate_resource_owner!

      include Concerns::DeviceAuthorizationsMethods
    end
  end
end
