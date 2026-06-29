# frozen_string_literal: true

module ConverraBilling
  module AccountBuilderExtension
    def perform
      user, account = super
      if Converra::Billing::PlanCatalog.enabled?
        Converra::Billing::ApplyPlanService.new(account: account, plan_slug: 'starter').perform
      end
      [user, account]
    end
  end

  module InboxesHelperExtension
    def validate_limit
      if Converra::Billing::PlanCatalog.enabled?
        limit_service = Converra::Billing::LimitService.new(account: Current.account)
        if limit_service.non_web_inbox_blocked?(permitted_params[:channel][:type])
          return render_payment_required('Your plan does not include more email or messaging inboxes. Upgrade on the Billing page.')
        end
      end

      super
    end
  end

  module ConversationsControllerExtension
    def create
      if Converra::Billing::PlanCatalog.enabled?
        limit_service = Converra::Billing::LimitService.new(account: Current.account)
        if limit_service.conversation_limit_exceeded?
          return render_payment_required('Monthly conversation limit reached. Upgrade your plan on the Billing page.')
        end
      end

      super
    end
  end

  module InboxLimitExtension
    def self.prepended(base)
      base.validate :validate_converra_inbox_limits, on: :create
    end

    def validate_converra_inbox_limits
      return unless self.class.converra_billing_enforced?

      limit_service = converra_limit_service
      if limit_service.inbox_limit_exceeded?
        errors.add(:base, 'Account inbox limit exceeded. Upgrade on the Billing page.')
      elsif limit_service.non_web_inbox_blocked?(channel_type)
        errors.add(:base, 'Your plan does not include more email or messaging inboxes. Upgrade on the Billing page.')
      end
    end
  end

  module ConversationLimitExtension
    def self.prepended(base)
      base.validate :validate_converra_conversation_limit, on: :create
    end

    def validate_converra_conversation_limit
      return unless self.class.converra_billing_enforced?

      if converra_limit_service.conversation_limit_exceeded?
        errors.add(:base, 'Monthly conversation limit reached. Upgrade your plan on the Billing page.')
      end
    end
  end

  module AccountUserLimitExtension
    def self.prepended(base)
      base.validate :validate_converra_agent_limit, on: :create
    end

    def validate_converra_agent_limit
      return unless self.class.converra_billing_enforced?

      if converra_limit_service.agent_limit_exceeded?
        errors.add(:base, 'Account agent limit exceeded. Upgrade on the Billing page.')
      end
    end
  end
end

Rails.application.config.to_prepare do
  AccountBuilder.prepend(ConverraBilling::AccountBuilderExtension)
  Api::V1::InboxesHelper.prepend(ConverraBilling::InboxesHelperExtension)
  Api::V1::Accounts::ConversationsController.prepend(ConverraBilling::ConversationsControllerExtension)
  Account.has_many :converra_plan_payments, dependent: :destroy unless Account.reflect_on_association(:converra_plan_payments)

  Inbox.include(ConverraBillingLimitable) unless Inbox.include?(ConverraBillingLimitable)
  Inbox.prepend(ConverraBilling::InboxLimitExtension) unless Inbox < ConverraBilling::InboxLimitExtension

  Conversation.include(ConverraBillingLimitable) unless Conversation.include?(ConverraBillingLimitable)
  Conversation.prepend(ConverraBilling::ConversationLimitExtension) unless Conversation < ConverraBilling::ConversationLimitExtension

  AccountUser.include(ConverraBillingLimitable) unless AccountUser.include?(ConverraBillingLimitable)
  AccountUser.prepend(ConverraBilling::AccountUserLimitExtension) unless AccountUser < ConverraBilling::AccountUserLimitExtension
end
