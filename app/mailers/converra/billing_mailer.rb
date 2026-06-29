# frozen_string_literal: true

class Converra::BillingMailer < ApplicationMailer
  def payment_receipt(payment:)
    @payment = payment
    @account = payment.account
    @plan = Converra::Billing::PlanCatalog.find(payment.plan_slug)
    @billing_url = "#{frontend_url}/app/accounts/#{@account.id}/settings/billing"

    mail(
      to: payment.billing_email,
      subject: "Payment received — #{@plan&.dig('name') || payment.plan_slug} plan"
    )
  end

  def subscription_lapsed(account:)
    @account = account
    @previous_plan_name = account.custom_attributes['converra_previous_plan_name']
    @agents_count = account.users.count
    @agent_limit = account.limits['agents'].to_i
    @billing_url = "#{frontend_url}/app/accounts/#{@account.id}/settings/billing"

    mail(
      to: administrator_emails(account),
      subject: "Your #{installation_name} subscription has ended"
    )
  end

  def renewal_reminder(account:)
    @account = account
    @plan = Converra::Billing::PlanCatalog.find(account.custom_attributes['plan_name'])
    @renewal_date = account.custom_attributes['subscription_ends_on']
    @billing_url = "#{frontend_url}/app/accounts/#{@account.id}/settings/billing"

    mail(
      to: administrator_emails(account),
      subject: "Your #{installation_name} plan renews soon"
    )
  end

  private

  def administrator_emails(account)
    account.administrators.pluck(:email).presence || [account.users.first&.email].compact
  end

  def frontend_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000').chomp('/')
  end

  def installation_name
    GlobalConfig.get_value('INSTALLATION_NAME').presence || 'Converra'
  end
end
