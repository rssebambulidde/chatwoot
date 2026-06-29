# frozen_string_literal: true

module Converra
  module Billing
    class LimitService
      pattr_initialize [:account!]

      def plan
        @plan ||= PlanCatalog.find(current_plan_slug) || PlanCatalog.find('starter')
      end

      def current_plan_slug
        slug = account.custom_attributes['plan_name'].presence || 'starter'
        return downgrade_to_starter! if paid_plan_expired?(slug)

        slug
      end

      def subscription_active?
        return true if plan['price_ugx'].to_i.zero?

        subscription_ends_on.present? && subscription_ends_on > Time.current
      end

      def subscription_ends_on
        value = account.custom_attributes['subscription_ends_on']
        return if value.blank?

        Time.zone.parse(value)
      end

      def paid_plan_expired?(slug)
        plan = PlanCatalog.find(slug)
        return false if plan.blank? || plan['price_ugx'].to_i.zero?

        subscription_ends_on.present? && subscription_ends_on <= Time.current
      end

      def downgrade_to_starter!
        Converra::Billing::ApplyPlanService.new(account: account, plan_slug: 'starter', subscription_ends_on: nil).perform
        account.reload
        'starter'
      end

      def conversations_this_month
        account.conversations.where('created_at > ?', 30.days.ago).count
      end

      def conversations_allowed
        account.custom_attributes['conversations_monthly_limit'].presence ||
          plan['conversations_monthly'] ||
          ChatwootApp.max_limit
      end

      def conversation_limit_exceeded?
        return false unless PlanCatalog.enabled?
        return false unless subscription_active?

        conversations_this_month >= conversations_allowed.to_i
      end

      def non_web_inboxes_allowed
        account.custom_attributes['non_web_inboxes_limit'].presence ||
          plan['non_web_inboxes'] ||
          ChatwootApp.max_limit
      end

      def non_web_inboxes_count
        account.inboxes.where.not(channel_type: Channel::WebWidget.to_s).count
      end

      def non_web_inbox_limit_exceeded?
        return false unless PlanCatalog.enabled?
        return false unless subscription_active?

        non_web_inboxes_count >= non_web_inboxes_allowed.to_i
      end

      def sync_plan_limits!
        return if account.limits.is_a?(Hash) && account.limits['agents'].present?

        ApplyPlanService.new(
          account: account,
          plan_slug: current_plan_slug,
          subscription_ends_on: subscription_ends_on
        ).perform
        account.reload
        @plan = nil
      end

      def agents_allowed
        account.limits['agents'].presence || plan.dig('limits', 'agents') || account.usage_limits[:agents]
      end

      def limits_payload
        sync_plan_limits!
        {
          'plan' => {
            'slug' => current_plan_slug,
            'name' => plan['name'],
            'price_ugx' => plan['price_ugx'],
            'subscription_active' => subscription_active?,
            'subscription_ends_on' => account.custom_attributes['subscription_ends_on'],
            'cancel_at_period_end' => cancel_at_period_end?
          },
          'conversation' => meter_payload(conversations_allowed.to_i, conversations_this_month),
          'non_web_inboxes' => meter_payload(non_web_inboxes_allowed.to_i, non_web_inboxes_count),
          'agents' => meter_payload(agents_allowed.to_i, account.users.count),
          'captain' => captain_payload,
          'over_limit' => over_limit?,
          'usage_warnings' => usage_warnings
        }
      end

      def over_limit?
        over_limit_agents? || over_limit_non_web_inboxes? || over_limit_conversations?
      end

      def usage_warnings
        warnings = []
        warnings << 'conversation' if usage_warning?(conversations_this_month, conversations_allowed.to_i)
        warnings << 'agents' if usage_warning?(account.users.count, agents_allowed.to_i)
        warnings << 'non_web_inboxes' if usage_warning?(non_web_inboxes_count, non_web_inboxes_allowed.to_i)
        warnings
      end

      def cancel_at_period_end?
        ActiveModel::Type::Boolean.new.cast(account.custom_attributes['cancel_at_period_end'])
      end

      private

      def meter_payload(allowed, consumed)
        { 'allowed' => allowed, 'consumed' => consumed }
      end

      def captain_payload
        captain = account.usage_limits[:captain] || {}
        {
          'responses' => captain[:responses],
          'documents' => captain[:documents]
        }
      end

      def usage_warning?(consumed, allowed)
        return false if allowed.to_i.zero?

        consumed.to_f / allowed >= 0.8
      end

      def over_limit_agents?
        account.users.count > agents_allowed.to_i
      end

      def over_limit_non_web_inboxes?
        non_web_inboxes_count > non_web_inboxes_allowed.to_i
      end

      def over_limit_conversations?
        conversations_this_month > conversations_allowed.to_i
      end
    end
  end
end
