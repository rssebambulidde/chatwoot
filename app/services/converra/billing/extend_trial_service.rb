# frozen_string_literal: true

module Converra
  module Billing
    class ExtendTrialService
      pattr_initialize [:account!, { days: nil, subscription_ends_on: nil }]

      def perform
        raise Error, 'Billing is not enabled' unless PlanCatalog.enabled?

        ends_on = resolve_ends_on
        raise Error, 'Trial end date must be in the future' if ends_on <= Time.current

        account.update!(
          custom_attributes: account.custom_attributes.merge(
            'subscription_ends_on' => ends_on.iso8601
          ).except('subscription_lapsed_at', 'renewal_reminder_sent_at')
        )
        account
      end

      class Error < StandardError; end

      private

      def resolve_ends_on
        if subscription_ends_on.present?
          parsed = Time.zone.parse(subscription_ends_on.to_s)&.end_of_day
          raise Error, 'Invalid trial end date' if parsed.blank?

          return parsed
        end

        if days.to_i.positive?
          current = LimitService.new(account: account).subscription_ends_on
          base = [current, Time.current].compact.max
          return (base + days.to_i.days).end_of_day
        end

        raise Error, 'Provide trial_days or subscription_ends_on'
      end
    end
  end
end
