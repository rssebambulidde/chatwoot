# frozen_string_literal: true

module Converra
  module Billing
    class MigrateStarterTrialsService
      def perform
        raise Error, 'Billing is not enabled' unless PlanCatalog.enabled?

        starter = PlanCatalog.find('starter')
        trial_days = starter['trial_days'].to_i
        raise Error, 'Starter has no trial_days configured' if trial_days.zero?

        count = 0
        Account.find_each do |account|
          next unless account.custom_attributes['plan_name'].to_s == 'starter'
          next if account.custom_attributes['subscription_ends_on'].present?
          next if account.converra_plan_payments.completed.exists?

          account.update!(
            custom_attributes: account.custom_attributes.merge(
              'subscription_ends_on' => trial_days.days.from_now.iso8601
            )
          )
          count += 1
        end

        { trial_days: trial_days, count: count }
      end

      class Error < StandardError; end
    end
  end
end
