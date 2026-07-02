# frozen_string_literal: true

namespace :converra do
  namespace :billing do
    desc 'Set 14-day Starter trials for existing workspaces without an end date'
    task migrate_starter_trials: :environment do
      unless Converra::Billing::PlanCatalog.enabled?
        puts 'Converra billing: skipped (billing not enabled)'
        next
      end

      starter = Converra::Billing::PlanCatalog.find('starter')
      trial_days = starter['trial_days'].to_i
      if trial_days.zero?
        puts 'Converra billing: starter has no trial_days configured'
        next
      end

      count = 0
      Account.find_each do |account|
        next unless account.custom_attributes['plan_name'].to_s == 'starter'
        next if account.custom_attributes['subscription_ends_on'].present?
        next if account.converra_plan_payments.completed.exists?

        account.update!(
          custom_attributes: account.custom_attributes.merge(
            'subscription_ends_on' => trial_days.days.from_now.iso8601
          )
        )
        count += 1
      end

      puts "Converra billing: applied #{trial_days}-day Starter trial to #{count} account(s)"
    end

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

    desc 'Reconcile plan features and limits for all workspaces (Converra billing)'
    task reconcile_plans: :environment do
      unless Converra::Billing::PlanCatalog.enabled?
        puts 'Converra billing: skipped reconcile (billing not enabled)'
        next
      end

      count = Account.count
      Branding::EnterpriseUnlock.reconcile_billing_accounts!
      puts "Converra billing: reconciled #{count} account(s)"
    end
  end
end
