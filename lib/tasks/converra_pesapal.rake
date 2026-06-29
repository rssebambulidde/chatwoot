# frozen_string_literal: true

namespace :converra do
  namespace :pesapal do
    desc 'Register Pesapal IPN and print notification ID for PESAPAL_IPN_NOTIFICATION_ID'
    task register_ipn: :environment do
      ipn_id = Converra::Billing::PesapalClient.new.register_ipn
      puts "Pesapal IPN registered. Set PESAPAL_IPN_NOTIFICATION_ID=#{ipn_id}"
    end
  end
end
