# frozen_string_literal: true

class Converra::Billing::PaymentReceiptJob < ApplicationJob
  queue_as :default

  def perform(payment_id)
    payment = ConverraPlanPayment.find_by(id: payment_id)
    return if payment.blank? || payment.billing_email.blank?

    Converra::BillingMailer.payment_receipt(payment: payment).deliver_later
  end
end
