# frozen_string_literal: true

namespace :branding do
  desc 'Apply installation branding from ENV and unlock enterprise features on self-hosted installs'
  task apply: :environment do
    if ENV['INSTALLATION_NAME'].present? || ENV['BRAND_NAME'].present?
      Branding::ConfigApplier.apply!
      puts "Branding applied for #{GlobalConfig.get_value('INSTALLATION_NAME')}."
    else
      puts 'Skipping branding config — set INSTALLATION_NAME or BRAND_NAME to apply logos and names.'
    end

    Branding::EnterpriseUnlock.apply!
    puts 'Enterprise features unlocked for self-hosted install.' if ChatwootApp.enterprise? && !ChatwootApp.chatwoot_cloud?
  end
end
