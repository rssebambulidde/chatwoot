# frozen_string_literal: true

class Billing::PaymentController < ApplicationController
  layout 'legal'

  def callback
    order_tracking_id = params[:OrderTrackingId].presence || params[:orderTrackingId]
    payment = nil
    if order_tracking_id.present? && Converra::Billing::PlanCatalog.enabled?
      payment = Converra::Billing::ProcessNotificationService.new(order_tracking_id: order_tracking_id).perform
    end

    redirect_to payment_result_path(payment), allow_other_host: true
  end

  private

  def payment_result_path(payment)
    if payment&.account_id.present?
      base = "#{frontend_url}/app/accounts/#{payment.account_id}/settings/billing"
      return "#{base}?payment=cancelled" if params[:cancelled].present?

      return "#{base}?payment=success"
    end

    return '/pricing?payment=cancelled' if params[:cancelled].present?

    '/pricing?payment=success'
  end

  def frontend_url
    ENV.fetch('FRONTEND_URL', request.base_url).chomp('/')
  end
end
