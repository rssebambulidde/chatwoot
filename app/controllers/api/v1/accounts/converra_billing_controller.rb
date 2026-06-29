# frozen_string_literal: true

class Api::V1::Accounts::ConverraBillingController < Api::V1::Accounts::BaseController
  before_action :ensure_converra_billing_enabled
  before_action :check_admin_authorization

  def status
    render json: {
      id: Current.account.id,
      limits: limit_service.limits_payload,
      plans: public_plans
    }
  end

  def checkout
    result = Converra::Billing::InitiatePaymentService.new(
      account: Current.account,
      plan_slug: params.require(:plan_slug),
      user: current_user
    ).perform

    render json: { redirect_url: result[:redirect_url] }
  rescue Converra::Billing::InitiatePaymentService::Error, Converra::Billing::PesapalClient::Error => e
    render_could_not_create_error(e.message)
  end

  private

  def ensure_converra_billing_enabled
    render json: { error: 'Not found' }, status: :not_found unless Converra::Billing::PlanCatalog.enabled?
  end

  def check_admin_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end

  def limit_service
    @limit_service ||= Converra::Billing::LimitService.new(account: Current.account)
  end

  def public_plans
    Converra::Billing::PlanCatalog.plans.map do |slug, plan|
      {
        slug: slug,
        name: plan['name'],
        price_ugx: plan['price_ugx'],
        limits: plan['limits'],
        conversations_monthly: plan['conversations_monthly']
      }
    end
  end
end
