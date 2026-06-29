# frozen_string_literal: true

module Converra
  module Billing
    class InitiatePaymentService
      pattr_initialize [:account!, :plan_slug!, :user!, { billing_interval: 'monthly' }]

      def perform
        raise Error, 'Billing is not enabled' unless PlanCatalog.enabled?

        plan = PlanCatalog.find(plan_slug)
        raise Error, 'Invalid plan' if plan.blank? || plan['price_ugx'].to_i.zero?

        interval = billing_interval.to_s == 'annual' ? 'annual' : 'monthly'
        amount = plan_amount(plan, interval)

        payment = account.converra_plan_payments.create!(
          plan_slug: plan_slug,
          amount: amount,
          currency: ENV.fetch('CONVERRA_BILLING_CURRENCY', 'UGX'),
          status: :pending,
          billing_interval: interval,
          merchant_reference: merchant_reference,
          description: "#{installation_name} #{plan['name']} plan (#{interval})",
          billing_email: user.email,
          billing_name: user.name
        )

        result = PesapalClient.new.submit_order(payment: payment)
        payment.update!(order_tracking_id: result[:order_tracking_id], redirect_url: result[:redirect_url])
        result
      end

      class Error < StandardError; end

      private

      def plan_amount(plan, interval)
        return plan['annual_price_ugx'].to_i if interval == 'annual' && plan['annual_price_ugx'].to_i.positive?

        plan['price_ugx'].to_i
      end

      def merchant_reference
        "converra-#{account.id}-#{plan_slug}-#{SecureRandom.hex(6)}"
      end

      def installation_name
        GlobalConfig.get_value('INSTALLATION_NAME').presence || 'Converra'
      end
    end
  end
end
