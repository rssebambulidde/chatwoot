# frozen_string_literal: true

module Branding
  class ConfigApplier
    BRANDING_KEYS = %w[
      INSTALLATION_NAME
      BRAND_NAME
      BRAND_URL
      WIDGET_BRAND_URL
      LOGO
      LOGO_DARK
      LOGO_THUMBNAIL
      TERMS_URL
      PRIVACY_URL
      DISPLAY_MANIFEST
    ].freeze

    def self.apply!
      new.apply!
    end

    def apply!
      return if branding_name.blank?

      updates = {
        'INSTALLATION_NAME' => branding_name,
        'BRAND_NAME' => env_value('BRAND_NAME', branding_name),
        'BRAND_URL' => env_value('BRAND_URL', frontend_url),
        'WIDGET_BRAND_URL' => env_value('WIDGET_BRAND_URL', frontend_url),
        'LOGO' => env_value('LOGO', '/brand-assets/logo.png'),
        'LOGO_DARK' => env_value('LOGO_DARK', '/brand-assets/logo_dark.png'),
        'LOGO_THUMBNAIL' => env_value('LOGO_THUMBNAIL', '/brand-assets/logo_thumbnail.png'),
        'TERMS_URL' => env_value('TERMS_URL', "#{frontend_url}/terms"),
        'PRIVACY_URL' => env_value('PRIVACY_URL', "#{frontend_url}/privacy"),
        'DISPLAY_MANIFEST' => env_value('DISPLAY_MANIFEST', 'false')
      }

      updates.each do |name, value|
        next if value.blank?

        record = InstallationConfig.find_or_initialize_by(name: name)
        record.value = cast_value(name, value)
        record.locked = false
        record.save!
      end

      GlobalConfig.clear_cache
    end

    private

    def branding_name
      env_value('INSTALLATION_NAME', env_value('BRAND_NAME', nil))
    end

    def frontend_url
      ENV.fetch('FRONTEND_URL', 'https://localhost:3000')
    end

    def env_value(key, default)
      ENV.fetch(key, default)
    end

    def cast_value(name, value)
      return value.to_s == 'true' if name == 'DISPLAY_MANIFEST'

      value
    end
  end
end
