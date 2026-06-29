# frozen_string_literal: true

module Converra
  module Billing
    class ApplyPlanService
      pattr_initialize [:account!, :plan_slug!, subscription_ends_on: nil]

      def perform
        plan = PlanCatalog.find(plan_slug)
        raise ArgumentError, "Unknown plan: #{plan_slug}" if plan.blank?

        account.disable_features(*PlanCatalog::PREMIUM_FEATURES)
        account.enable_features(*plan['features']) if plan['features'].present?

        ends_on = subscription_ends_on || default_subscription_ends_on(plan)
        account.update!(
          limits: plan['limits'].stringify_keys,
          custom_attributes: account.custom_attributes.merge(
            'plan_name' => plan_slug.to_s,
            'converra_plan_name' => plan['name'],
            'subscribed_quantity' => plan.dig('limits', 'agents'),
            'subscription_ends_on' => ends_on&.iso8601,
            'conversations_monthly_limit' => plan['conversations_monthly'],
            'non_web_inboxes_limit' => plan['non_web_inboxes']
          )
        )
        account
      end

      private

      def default_subscription_ends_on(plan)
        return nil if plan['price_ugx'].to_i.zero?

        1.month.from_now
      end
    end
  end
end
