# frozen_string_literal: true

class Api::V1::Accounts::ConverraBillingController < Api::V1::Accounts::BaseController
  before_action :ensure_converra_billing_enabled
  before_action :check_admin_authorization

  def status
    render json: {
      id: Current.account.id,
      limits: limit_service.limits_payload,
      plans: public_plans,
      billing_meta: billing_meta
    }
  end

  def payments
    render json: {
      payments: Current.account.converra_plan_payments.order(created_at: :desc).limit(20).map { |payment| payment_payload(payment) }
    }
  end

  def checkout
    result = Converra::Billing::InitiatePaymentService.new(
      account: Current.account,
      plan_slug: params.require(:plan_slug),
      user: current_user,
      billing_interval: params.fetch(:billing_interval, 'monthly')
    ).perform

    render json: { redirect_url: result[:redirect_url] }
  rescue Converra::Billing::InitiatePaymentService::Error, Converra::Billing::PesapalClient::Error => e
    render_could_not_create_error(e.message)
  end

  def schedule_downgrade
    Converra::Billing::ScheduleDowngradeService.new(account: Current.account).perform
    render json: { message: 'Subscription will move to Starter when the current period ends.' }
  rescue Converra::Billing::ScheduleDowngradeService::Error => e
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

  def billing_meta
    {
      pesapal_env: ENV.fetch('PESAPAL_ENV', 'sandbox'),
      cancel_at_period_end: ActiveModel::Type::Boolean.new.cast(
        Current.account.custom_attributes['cancel_at_period_end']
      )
    }
  end

  def public_plans
    Converra::Billing::PlanCatalog.plans.map do |slug, plan|
      {
        slug: slug,
        name: plan['name'],
        price_ugx: plan['price_ugx'],
        annual_price_ugx: plan['annual_price_ugx'],
        limits: plan['limits'],
        conversations_monthly: plan['conversations_monthly'],
        non_web_inboxes: plan['non_web_inboxes'],
        features: plan['features']
      }
    end
  end

  def payment_payload(payment)
    plan = Converra::Billing::PlanCatalog.find(payment.plan_slug)
    {
      id: payment.id,
      plan_slug: payment.plan_slug,
      plan_name: plan&.dig('name') || payment.plan_slug,
      amount: payment.amount,
      currency: payment.currency,
      status: payment.status,
      billing_interval: payment.billing_interval,
      completed_at: payment.completed_at,
      created_at: payment.created_at
    }
  end
end
