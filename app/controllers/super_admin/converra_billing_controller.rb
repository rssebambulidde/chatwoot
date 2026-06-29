# frozen_string_literal: true

class SuperAdmin::ConverraBillingController < SuperAdmin::ApplicationController
  def show
    redirect_to super_admin_root_path and return unless Converra::Billing::PlanCatalog.enabled?

    @stats = Converra::Billing::AdminStatsService.new.stats
  end
end
