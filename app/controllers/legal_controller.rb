class LegalController < ApplicationController
  layout 'legal'

  GUIDE_PAGES = %w[
    workspace-setup
    conversations
    agents
    contacts-companies
    admin
    teams-labels
    channels
    channel-email
    channel-website
    channel-whatsapp
    channel-social
    channel-sms
    captain
    macros-canned
    automations-bots
    campaigns
    reports
    help-center
    integrations
    sla-workflow
    security-roles
    whatsapp-errors
    troubleshooting
  ].freeze

  helper_method :legal_site_url, :guide_page_active?, :converra_plans, :converra_billing_enabled?

  def home; end

  def about
    redirect_to '/', status: :moved_permanently
  end

  def privacy; end

  def terms; end

  def pricing
    @payment_notice = params[:payment]
  end

  def guide
    @guide_page = 'index'
    render 'guide/index', layout: 'guide'
  end

  def guide_page
    page = params[:page]
    unless GUIDE_PAGES.include?(page)
      redirect_to guide_path, status: :moved_permanently
      return
    end

    @guide_page = page
    render "guide/#{page}", layout: 'guide'
  end

  private

  def legal_site_url
    ENV.fetch('FRONTEND_URL', request.base_url)
  end

  def guide_page_active?(page)
    @guide_page == page
  end

  def converra_plans
    Converra::Billing::PlanCatalog.plans
  end

  def converra_billing_enabled?
    Converra::Billing::PlanCatalog.enabled?
  end
end
