# frozen_string_literal: true

module Converra
  module Billing
    class ResetExpiredCaptainUsageService
      def perform
        return unless PlanCatalog.enabled?

        Account.find_each do |account|
          next unless period_expired?(account)

          ResetCaptainUsageService.new(account: account).perform
        rescue StandardError => e
          Rails.logger.error(
            "Converra captain usage reset failed for account #{account.id}: #{e.message}"
          )
        end
      end

      private

      def period_expired?(account)
        period_start = account.custom_attributes[ResetCaptainUsageService::PERIOD_START_KEY]
        return true if period_start.blank?

        Time.zone.parse(period_start) <= 1.month.ago
      rescue ArgumentError, TypeError
        true
      end
    end
  end
end
