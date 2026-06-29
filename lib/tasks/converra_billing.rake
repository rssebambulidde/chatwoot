# frozen_string_literal: true

namespace :converra do
  namespace :billing do
    desc 'Downgrade workspaces with expired paid subscriptions to Starter'
    task downgrade_expired: :environment do
      Converra::Billing::DowngradeExpiredPlansService.new.perform
      puts 'Converra billing: expired plan downgrade complete'
    end

    desc 'Reset Copilot reply usage for workspaces whose monthly period has elapsed'
    task reset_captain_usage: :environment do
      Converra::Billing::ResetExpiredCaptainUsageService.new.perform
      puts 'Converra billing: captain usage reset complete'
    end
  end
end
