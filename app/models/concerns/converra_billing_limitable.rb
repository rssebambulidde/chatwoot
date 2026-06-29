# frozen_string_literal: true

module ConverraBillingLimitable
  extend ActiveSupport::Concern

  class_methods do
    def converra_billing_enforced?
      defined?(Converra::Billing::PlanCatalog) && Converra::Billing::PlanCatalog.enabled?
    end
  end

  private

  def converra_limit_service
    @converra_limit_service ||= Converra::Billing::LimitService.new(account: converra_billing_account)
  end

  def converra_billing_account
    if respond_to?(:account)
      account
    else
      Current.account
    end
  end
end
