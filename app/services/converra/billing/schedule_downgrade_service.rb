# frozen_string_literal: true

module Converra
  module Billing
    class ScheduleDowngradeService
      pattr_initialize [:account!]

      def perform
        raise Error, 'Billing is not enabled' unless PlanCatalog.enabled?

        plan = PlanCatalog.find(account.custom_attributes['plan_name'])
        raise Error, 'Already on Starter' if plan.blank? || account.custom_attributes['plan_name'].to_s == 'starter'

        account.update!(
          custom_attributes: account.custom_attributes.merge('cancel_at_period_end' => true)
        )
        account
      end

      class Error < StandardError; end
    end
  end
end
