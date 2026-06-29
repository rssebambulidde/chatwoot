# frozen_string_literal: true

module Converra
  module Billing
    class AdminStatsService
      def stats
        {
          enabled: PlanCatalog.enabled?,
          pesapal_env: ENV.fetch('PESAPAL_ENV', 'sandbox'),
          accounts_by_plan: accounts_by_plan,
          mrr_ugx: mrr_ugx,
          recent_payments: recent_payments,
          failed_payments_count: failed_payments_count
        }
      end

      private

      def accounts_by_plan
        counts = Hash.new(0)
        Account.find_each do |account|
          slug = account.custom_attributes['plan_name'].presence || 'starter'
          counts[slug] += 1
        end
        counts.sort_by { |_slug, count| -count }.to_h
      end

      def mrr_ugx
        Account.find_each.sum do |account|
          next 0 unless LimitService.new(account: account).subscription_active?

          plan = PlanCatalog.find(account.custom_attributes['plan_name'])
          plan&.dig('price_ugx').to_i
        end
      end

      def recent_payments
        ConverraPlanPayment.includes(:account).order(created_at: :desc).limit(10).map do |payment|
          {
            id: payment.id,
            account_name: payment.account.name,
            plan_slug: payment.plan_slug,
            amount: payment.amount,
            currency: payment.currency,
            status: payment.status,
            billing_interval: payment.billing_interval,
            completed_at: payment.completed_at
          }
        end
      end

      def failed_payments_count
        ConverraPlanPayment.failed.where('created_at > ?', 30.days.ago).count
      end
    end
  end
end
