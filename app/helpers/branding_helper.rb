# frozen_string_literal: true

module BrandingHelper
  def installation_brand_name
    @installation_brand_name ||= begin
      GlobalConfig.get_value('INSTALLATION_NAME').presence ||
        GlobalConfig.get_value('BRAND_NAME').presence ||
        ENV.fetch('INSTALLATION_NAME', 'Chatwoot')
    end
  end

  def installation_logo_url
    GlobalConfig.get_value('LOGO').presence || '/brand-assets/logo.png'
  end

  def installation_logo_dark_url
    GlobalConfig.get_value('LOGO_DARK').presence || '/brand-assets/logo_dark.png'
  end

  def installation_logo_thumbnail_url
    GlobalConfig.get_value('LOGO_THUMBNAIL').presence || '/brand-assets/logo_thumbnail.png'
  end

  def custom_branded_instance?
    installation_brand_name != 'Chatwoot'
  end

  def apply_installation_branding(text)
    Branding::TextReplacer.replace(text, installation_name: installation_brand_name)
  end
end
