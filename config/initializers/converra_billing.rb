# frozen_string_literal: true

module ConverraBilling
  module AccountBuilderExtension
    def perform
      user, account = super
      if Converra::Billing::PlanCatalog.enabled?
        Converra::Billing::ApplyPlanService.new(account: account, plan_slug: 'starter').perform
        Converra::Billing::ResetCaptainUsageService.new(account: account.reload).perform
      end
      [user, account]
    end
  end

  module AccountUserLimitExtension
    def self.prepended(base)
      base.validate :validate_converra_agent_limit, on: :create
    end

    def validate_converra_agent_limit
      return unless self.class.converra_billing_enforced?

      if converra_limit_service.agent_limit_exceeded?
        errors.add(:base, I18n.t('converra_billing.agent_limit_exceeded'))
      end
    end
  end

  module AgentsControllerExtension
    private

    def validate_limit
      if Converra::Billing::PlanCatalog.enabled?
        render_payment_required(I18n.t('converra_billing.agent_limit_exceeded')) unless can_add_agent?
        return
      end

      super
    end

    def validate_limit_for_bulk_create
      if Converra::Billing::PlanCatalog.enabled?
        limit_available = params[:emails].count <= available_agent_count
        render_payment_required(I18n.t('converra_billing.agent_limit_exceeded')) unless limit_available
        return
      end

      super
    end
  end
end

Rails.application.config.to_prepare do
  AccountBuilder.prepend(ConverraBilling::AccountBuilderExtension)
  Account.has_many :converra_plan_payments, dependent: :destroy unless Account.reflect_on_association(:converra_plan_payments)

  AccountUser.include(ConverraBillingLimitable) unless AccountUser.include?(ConverraBillingLimitable)
  AccountUser.prepend(ConverraBilling::AccountUserLimitExtension) unless AccountUser < ConverraBilling::AccountUserLimitExtension

  Api::V1::Accounts::AgentsController.prepend(ConverraBilling::AgentsControllerExtension) unless
    Api::V1::Accounts::AgentsController < ConverraBilling::AgentsControllerExtension
end
