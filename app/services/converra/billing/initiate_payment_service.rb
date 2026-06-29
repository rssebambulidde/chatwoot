# frozen_string_literal: true

module Converra
  module Billing
    class InitiatePaymentService
      pattr_initialize [:account!, :plan_slug!, :user!]

      def perform
        raise Error, 'Billing is not enabled' unless PlanCatalog.enabled?

        plan = PlanCatalog.find(plan_slug)
        raise Error, 'Invalid plan' if plan.blank? || plan['price_ugx'].to_i.zero?

        payment = account.converra_plan_payments.create!(
          plan_slug: plan_slug,
          amount: plan['price_ugx'],
          currency: ENV.fetch('CONVERRA_BILLING_CURRENCY', 'UGX'),
          status: :pending,
          merchant_reference: merchant_reference,
          description: "#{installation_name} #{plan['name']} plan",
          billing_email: user.email,
          billing_name: user.name
        )

        result = PesapalClient.new.submit_order(payment: payment)
        payment.update!(order_tracking_id: result[:order_tracking_id], redirect_url: result[:redirect_url])
        result
      end

      class Error < StandardError; end

      private

      def merchant_reference
        "converra-#{account.id}-#{plan_slug}-#{SecureRandom.hex(6)}"
      end

      def installation_name
        GlobalConfig.get_value('INSTALLATION_NAME').presence || 'Converra'
      end
    end
  end
end
