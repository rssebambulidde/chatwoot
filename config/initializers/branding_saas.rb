# frozen_string_literal: true

Rails.application.config.to_prepare do
  Account.class_eval do
    after_create_commit :unlock_enterprise_features_for_saas_account

    def unlock_enterprise_features_for_saas_account
      Branding::EnterpriseUnlock.enable_features_for_account!(self)
    end
  end
end
