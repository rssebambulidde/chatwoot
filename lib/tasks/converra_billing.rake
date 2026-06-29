# frozen_string_literal: true

namespace :converra do
  namespace :billing do
    desc 'Downgrade workspaces with expired paid subscriptions to Starter'
    task downgrade_expired: :environment do
      Converra::Billing::DowngradeExpiredPlansService.new.perform
      puts 'Converra billing: expired plan downgrade complete'
    end
  end
end
