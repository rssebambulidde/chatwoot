# frozen_string_literal: true

module Converra
  module Billing
    class ProcessNotificationService
      COMPLETED_STATUSES = %w[COMPLETED Completed completed].freeze

      pattr_initialize [:order_tracking_id!, :merchant_reference: nil]

      def perform
        payment = find_payment
        return if payment.blank?

        status = PesapalClient.new.transaction_status(order_tracking_id)
        payment.update!(payment_status: status)

        return unless payment_completed?(status)
        return if payment.completed?

        payment.complete!
        ApplyPlanService.new(
          account: payment.account,
          plan_slug: payment.plan_slug,
          subscription_ends_on: 1.month.from_now
        ).perform
      end

      private

      def find_payment
        payment = ConverraPlanPayment.find_by(order_tracking_id: order_tracking_id)
        payment ||= ConverraPlanPayment.find_by(merchant_reference: merchant_reference) if merchant_reference.present?
        payment
      end

      def payment_completed?(status)
        COMPLETED_STATUSES.include?(status) || status.to_s.downcase == 'completed'
      end
    end
  end
end
