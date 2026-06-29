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
      if Converra::Billing::PlanCatalog.enabled? && non_web_channel_requested?
        limit_service = Converra::Billing::LimitService.new(account: Current.account)
        if limit_service.non_web_inbox_limit_exceeded?
          return render_payment_required('Your plan does not include more email or messaging inboxes. Upgrade on the Billing page.')
        end
      end

      super
    end

    private

    def non_web_channel_requested?
      channel_type = permitted_params[:channel][:type]
      channel_type.present? && channel_type != 'web_widget'
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
end

Rails.application.config.to_prepare do
  AccountBuilder.prepend(ConverraBilling::AccountBuilderExtension)
  Api::V1::InboxesHelper.prepend(ConverraBilling::InboxesHelperExtension)
  Api::V1::Accounts::ConversationsController.prepend(ConverraBilling::ConversationsControllerExtension)
  Account.has_many :converra_plan_payments, dependent: :destroy unless Account.reflect_on_association(:converra_plan_payments)
end
