# frozen_string_literal: true

module Converra
  module Billing
    class DowngradeExpiredPlansService
      def perform
        return unless PlanCatalog.enabled?

        Account.where("custom_attributes ->> 'subscription_ends_on' IS NOT NULL").find_each do |account|
          next if subscription_active?(account)

          plan = PlanCatalog.find(account.custom_attributes['plan_name'])
          next unless PlanCatalog.paid_subscription?(plan)

          downgrade_account!(account, plan)
        end
      end

      private

      def downgrade_account!(account, plan)
        ApplyPlanService.new(account: account, plan_slug: 'starter', subscription_ends_on: nil).perform
        account.reload.update!(
          custom_attributes: account.custom_attributes.merge(
            'subscription_lapsed_at' => Time.current.iso8601,
            'converra_previous_plan_name' => plan['name']
          )
        )
        Converra::BillingMailer.subscription_lapsed(account: account).deliver_later
      end

      def subscription_active?(account)
        LimitService.new(account: account).subscription_active?
      end
    end
  end
end
