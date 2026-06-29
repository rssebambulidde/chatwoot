# frozen_string_literal: true

module Converra
  module Billing
    class DowngradeExpiredPlansService
      def perform
        return unless PlanCatalog.enabled?

        Account.where("custom_attributes ->> 'subscription_ends_on' IS NOT NULL").find_each do |account|
          next if subscription_active?(account)

          plan = PlanCatalog.find(account.custom_attributes['plan_name'])
          next if plan.blank? || plan['price_ugx'].to_i.zero?

          ApplyPlanService.new(account: account, plan_slug: 'starter', subscription_ends_on: nil).perform
        end
      end

      private

      def subscription_active?(account)
        LimitService.new(account: account).subscription_active?
      end
    end
  end
end
