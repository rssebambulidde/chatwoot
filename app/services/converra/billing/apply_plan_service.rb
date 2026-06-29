# frozen_string_literal: true

module Converra
  module Billing
    class ApplyPlanService
      pattr_initialize [:account!, :plan_slug!, { subscription_ends_on: nil, clear_cancel_at_period_end: false }]

      def perform
        plan = PlanCatalog.find(plan_slug)
        raise ArgumentError, "Unknown plan: #{plan_slug}" if plan.blank?

        account.enable_features(*PlanCatalog::PREMIUM_FEATURES)

        ends_on = subscription_ends_on || default_subscription_ends_on(plan)
        attributes = account.custom_attributes.merge(
          'plan_name' => plan_slug.to_s,
          'converra_plan_name' => plan['name'],
          'subscribed_quantity' => plan.dig('limits', 'agents'),
          'subscription_ends_on' => ends_on&.iso8601
        )
        if clear_cancel_at_period_end
          attributes = attributes.except(
            'conversations_monthly_limit',
            'non_web_inboxes_limit',
            'cancel_at_period_end',
            'renewal_reminder_sent_at',
            'subscription_lapsed_at',
            'converra_previous_plan_name'
          )
        end
        attributes = attributes.except('conversations_monthly_limit', 'non_web_inboxes_limit')

        account.update!(
          limits: plan['limits'].stringify_keys,
          custom_attributes: attributes
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
