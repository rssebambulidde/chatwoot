# frozen_string_literal: true

class Webhooks::PesapalController < ActionController::API
  def process_payload
    return head :not_found unless Converra::Billing::PlanCatalog.enabled?

    order_tracking_id = params[:OrderTrackingId].presence || params[:orderTrackingId]
    merchant_reference = params[:OrderMerchantReference].presence || params[:orderMerchantReference]

    if order_tracking_id.blank?
      head :bad_request
      return
    end

    Converra::Billing::ProcessNotificationService.new(
      order_tracking_id: order_tracking_id,
      merchant_reference: merchant_reference
    ).perform

    head :ok
  rescue Converra::Billing::PesapalClient::Error => e
    Rails.logger.error("Pesapal webhook error: #{e.message}")
    head :bad_request
  end
end
