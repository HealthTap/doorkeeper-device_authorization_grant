# frozen_string_literal: true

module Doorkeeper
  module DeviceAuthorizationGrant
    # Device authorization endpoint for OAuth 2.0 Device Authorization Grant.
    #
    # @see https://tools.ietf.org/html/rfc8628#section-3.1 RFC 8628, section 3.1
    class DeviceCodesController < ApplicationMetalController
      include Concerns::DeviceCodesMethods
    end
  end
end
