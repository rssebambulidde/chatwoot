# frozen_string_literal: true

namespace :branding do
  desc 'Apply installation branding from ENV (INSTALLATION_NAME, BRAND_NAME, LOGO, etc.)'
  task apply: :environment do
    if ENV['INSTALLATION_NAME'].blank? && ENV['BRAND_NAME'].blank?
      puts 'Skipping branding:apply — set INSTALLATION_NAME or BRAND_NAME to apply branding.'
      next
    end

    Branding::ConfigApplier.apply!
    puts "Branding applied for #{GlobalConfig.get_value('INSTALLATION_NAME')}."
  end
end
