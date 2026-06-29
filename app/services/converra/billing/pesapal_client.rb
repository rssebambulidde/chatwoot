# frozen_string_literal: true

module Converra
  module Billing
    class PesapalClient
      class Error < StandardError; end

      SANDBOX_BASE_URL = 'https://cybqa.pesapal.com/pesapalv3'
      LIVE_BASE_URL = 'https://pay.pesapal.com/v3'

      def initialize
        @consumer_key = ENV.fetch('PESAPAL_CONSUMER_KEY', nil)
        @consumer_secret = ENV.fetch('PESAPAL_CONSUMER_SECRET', nil)
        raise Error, 'Pesapal credentials are not configured' if @consumer_key.blank? || @consumer_secret.blank?
      end

      def submit_order(payment:)
        token = request_token
        body = {
          id: payment.merchant_reference,
          currency: payment.currency,
          amount: payment.amount,
          description: payment.description,
          callback_url: payment_callback_url,
          redirect_mode: 'TOP_WINDOW',
          notification_id: ipn_notification_id,
          billing_address: {
            email_address: payment.billing_email,
            first_name: payment.billing_name,
            country_code: ENV.fetch('PESAPAL_COUNTRY_CODE', 'UG')
          }
        }

        response = post_json('/api/Transactions/SubmitOrderRequest', body, token)
        {
          redirect_url: response['redirect_url'],
          order_tracking_id: response['order_tracking_id']
        }
      end

      def transaction_status(order_tracking_id)
        token = request_token
        response = get_json("/api/Transactions/GetTransactionStatus?orderTrackingId=#{CGI.escape(order_tracking_id)}", token)
        response['payment_status_description'] || response['status']
      end

      def register_ipn
        token = request_token
        body = {
          url: ipn_callback_url,
          ipn_notification_type: 'GET'
        }
        response = post_json('/api/URLSetup/RegisterIPN', body, token)
        response['ipn_id']
      end

      private

      def base_url
        ENV.fetch('PESAPAL_ENV', 'sandbox') == 'live' ? LIVE_BASE_URL : SANDBOX_BASE_URL
      end

      def request_token
        response = RestClient::Request.execute(
          method: :post,
          url: "#{base_url}/api/Auth/RequestToken",
          payload: { consumer_key: @consumer_key, consumer_secret: @consumer_secret }.to_json,
          headers: { content_type: :json, accept: :json }
        )
        JSON.parse(response.body)['token']
      rescue RestClient::ExceptionWithResponse => e
        raise Error, "Pesapal auth failed: #{e.response}"
      end

      def post_json(path, body, token)
        response = RestClient::Request.execute(
          method: :post,
          url: "#{base_url}#{path}",
          payload: body.to_json,
          headers: json_headers(token)
        )
        JSON.parse(response.body)
      rescue RestClient::ExceptionWithResponse => e
        raise Error, "Pesapal request failed: #{e.response}"
      end

      def get_json(path, token)
        response = RestClient::Request.execute(
          method: :get,
          url: "#{base_url}#{path}",
          headers: json_headers(token)
        )
        JSON.parse(response.body)
      rescue RestClient::ExceptionWithResponse => e
        raise Error, "Pesapal request failed: #{e.response}"
      end

      def json_headers(token)
        { content_type: :json, accept: :json, Authorization: "Bearer #{token}" }
      end

      def ipn_notification_id
        ENV.fetch('PESAPAL_IPN_NOTIFICATION_ID') do
          raise Error, 'PESAPAL_IPN_NOTIFICATION_ID is not configured'
        end
      end

      def payment_callback_url
        "#{frontend_url}/billing/payment/callback"
      end

      def ipn_callback_url
        "#{frontend_url}/webhooks/pesapal"
      end

      def frontend_url
        ENV.fetch('FRONTEND_URL', 'http://localhost:3000').chomp('/')
      end
    end
  end
end
