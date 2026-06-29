# frozen_string_literal: true

module Branding
  module EnterpriseUnlock
    PLAN = 'enterprise'
    PLAN_QUANTITY = 10_000

    ENTERPRISE_FEATURES = %w[
      inbound_emails
      help_center
      campaigns
      team_management
      channel_facebook
      channel_email
      channel_instagram
      channel_tiktok
      captain_integration
      captain_integration_v2
      captain_tasks
      captain_document_auto_sync
      advanced_search_indexing
      advanced_search
      linear_integration
      channel_voice
      sla
      custom_roles
      csat_review_notes
      conversation_required_attributes
      advanced_assignment
      assignment_v2
      custom_tools
      companies
      audit_logs
      disable_branding
      saml
    ].freeze

    module_function

    def apply!
      return unless ChatwootApp.enterprise?
      return if ChatwootApp.chatwoot_cloud?

      set_installation_plan!
      enable_saas_mode!
      if converra_billing_enabled?
        reconcile_billing_accounts!
      else
        enable_features_on_all_accounts!
      end
      clear_premium_warning!
      GlobalConfig.clear_cache
    end

    def set_installation_plan!
      upsert_config('INSTALLATION_PRICING_PLAN', PLAN)
      upsert_config('INSTALLATION_PRICING_PLAN_QUANTITY', PLAN_QUANTITY)
    end

    def enable_saas_mode!
      upsert_config('ENABLE_ACCOUNT_SIGNUP', true)
      upsert_config('CREATE_NEW_ACCOUNT_FROM_DASHBOARD', false)
    end

    def enable_features_on_all_accounts!
      Account.find_each { |account| enable_features_for_account!(account) }
    end

    def reconcile_billing_accounts!
      Account.find_each { |account| reconcile_billing_account!(account) }
    end

    def enable_features_for_account!(account)
      return unless ChatwootApp.enterprise?
      return if ChatwootApp.chatwoot_cloud?
      return reconcile_billing_account!(account) if converra_billing_enabled?

      account.enable_features!(*ENTERPRISE_FEATURES)
      account.save!
    end

    def reconcile_billing_account!(account)
      plan_slug = account.custom_attributes['plan_name'].presence || 'starter'
      ends_on = account.custom_attributes['subscription_ends_on']
      parsed_ends_on = ends_on.present? ? Time.zone.parse(ends_on) : nil

      Converra::Billing::ApplyPlanService.new(
        account: account,
        plan_slug: plan_slug,
        subscription_ends_on: parsed_ends_on
      ).perform
    rescue StandardError => e
      Rails.logger.error("Failed to reconcile Converra plan for account #{account.id}: #{e.message}")
    end

    def converra_billing_enabled?
      defined?(Converra::Billing::PlanCatalog) && Converra::Billing::PlanCatalog.enabled?
    end

    def clear_premium_warning!
      Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
    end

    def upsert_config(name, value)
      record = InstallationConfig.find_or_initialize_by(name: name)
      record.value = value
      record.locked = false
      record.save!
    end
  end
end
