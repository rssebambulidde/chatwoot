# frozen_string_literal: true

class SuperAdmin::ConverraBillingController < SuperAdmin::ApplicationController
  def show
    redirect_to super_admin_root_path and return unless Converra::Billing::PlanCatalog.enabled?

    @stats = Converra::Billing::AdminStatsService.new.stats
  end

  def migrate_starter_trials
    redirect_to super_admin_root_path and return unless Converra::Billing::PlanCatalog.enabled?

    result = Converra::Billing::MigrateStarterTrialsService.new.perform
    redirect_to super_admin_converra_billing_path,
                notice: "Applied #{result[:trial_days]}-day Starter trial to #{result[:count]} account(s)"
  rescue Converra::Billing::MigrateStarterTrialsService::Error => e
    redirect_to super_admin_converra_billing_path, alert: e.message
  end
end
