# frozen_string_literal: true

module Converra
  module Billing
    class ResetCaptainUsageService
      PERIOD_START_KEY = 'captain_responses_period_start'

      pattr_initialize [:account!]

      def perform
        return account unless PlanCatalog.enabled?
        return account unless account.respond_to?(:reset_response_usage)

        account.reset_response_usage
        account.update!(
          custom_attributes: account.custom_attributes.merge(
            PERIOD_START_KEY => Time.current.iso8601
          )
        )
        account
      end
    end
  end
end
