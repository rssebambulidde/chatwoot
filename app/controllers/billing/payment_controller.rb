# frozen_string_literal: true

class Billing::PaymentController < ApplicationController
  layout 'legal'

  def callback
    order_tracking_id = params[:OrderTrackingId].presence || params[:orderTrackingId]
    if order_tracking_id.present? && Converra::Billing::PlanCatalog.enabled?
      Converra::Billing::ProcessNotificationService.new(order_tracking_id: order_tracking_id).perform
    end

    redirect_to payment_result_path
  end

  private

  def payment_result_path
    if params[:cancelled].present?
      '/pricing?payment=cancelled'
    else
      '/pricing?payment=success'
    end
  end
end
