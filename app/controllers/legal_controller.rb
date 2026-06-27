class LegalController < ApplicationController
  layout 'legal'

  helper_method :legal_site_url

  def privacy; end

  def terms; end

  private

  def legal_site_url
    ENV.fetch('FRONTEND_URL', request.base_url)
  end
end
