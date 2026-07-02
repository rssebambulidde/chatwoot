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
        return downgrade_to_starter! if paid_plan_expired?(slug) && slug != 'starter'

        slug
      end

      def subscription_active?
        return true unless PlanCatalog.paid_subscription?(plan)

        subscription_ends_on.present? && subscription_ends_on > Time.current
      end

      def subscription_ends_on
        value = account.custom_attributes['subscription_ends_on']
        return if value.blank?

        Time.zone.parse(value)
      end

      def paid_plan_expired?(slug)
        plan = PlanCatalog.find(slug)
        return false unless PlanCatalog.paid_subscription?(plan)

        subscription_ends_on.present? && subscription_ends_on <= Time.current
      end

      def downgrade_to_starter!
        Converra::Billing::ApplyPlanService.new(account: account, plan_slug: 'starter', subscription_ends_on: nil).perform
        account.reload
        'starter'
      end

      def agent_limit_exceeded?
        return false unless PlanCatalog.enabled?

        account.users.count >= agents_allowed.to_i
      end

      def sync_plan_limits!
        return unless PlanCatalog.enabled?
        return if account.limits.is_a?(Hash) && account.limits['agents'].present? && !plan_out_of_sync?

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
            'trial_days' => plan['trial_days'],
            'subscription_active' => subscription_active?,
            'subscription_ends_on' => account.custom_attributes['subscription_ends_on'],
            'on_trial' => on_trial?,
            'cancel_at_period_end' => cancel_at_period_end?
          },
          'agents' => meter_payload(agents_allowed.to_i, account.users.count),
          'captain' => captain_payload,
          'captain_responses_resets_on' => captain_responses_resets_on&.iso8601,
          'subscription_lapsed' => subscription_lapsed?,
          'over_limit' => over_limit?,
          'usage_warnings' => usage_warnings
        }
      end

      def over_limit?
        over_limit_agents? || over_limit_captain_responses?
      end

      def usage_warnings
        warnings = []
        warnings << 'subscription_expired' if subscription_payment_required?
        warnings << 'subscription_lapsed_agents' if subscription_lapsed? && over_limit_agents?
        warnings << 'agents' if usage_warning?(account.users.count, agents_allowed.to_i)
        warnings << 'captain_responses' if captain_response_warning?
        warnings
      end

      def cancel_at_period_end?
        ActiveModel::Type::Boolean.new.cast(account.custom_attributes['cancel_at_period_end'])
      end

      def subscription_lapsed?
        account.custom_attributes['subscription_lapsed_at'].present?
      end

      def subscription_payment_required?
        PlanCatalog.paid_subscription?(plan) && !subscription_active?
      end

      def on_trial?
        return false unless PlanCatalog.trial_plan?(plan)
        return false unless subscription_active?
        return false if account.converra_plan_payments.completed.where(plan_slug: current_plan_slug).exists?

        true
      end

      def captain_responses_resets_on
        period_start = account.custom_attributes[ResetCaptainUsageService::PERIOD_START_KEY]
        return if period_start.blank?

        Time.zone.parse(period_start) + 1.month
      rescue ArgumentError, TypeError
        nil
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

      def over_limit_captain_responses?
        responses = account.usage_limits.dig(:captain, :responses)
        return false if responses.blank?

        responses[:consumed].to_i > responses[:total_count].to_i
      end

      def captain_response_warning?
        responses = account.usage_limits.dig(:captain, :responses)
        return false if responses.blank?

        usage_warning?(responses[:consumed].to_i, responses[:total_count].to_i)
      end

      def plan_out_of_sync?
        plan_features_out_of_sync? || plan_limits_out_of_sync?
      end

      def plan_features_out_of_sync?
        PlanCatalog::PREMIUM_FEATURES.any? { |feature| !account.feature_enabled?(feature) }
      end

      def plan_limits_out_of_sync?
        plan_limits = plan['limits'] || {}
        %w[agents captain_responses captain_documents].any? do |key|
          account.limits[key].to_i != plan_limits[key].to_i
        end
      end
    end
  end
end
