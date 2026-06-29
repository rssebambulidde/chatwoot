# frozen_string_literal: true

module Converra
  module Billing
    class PlanCatalog
      PREMIUM_FEATURES = %w[
        inbound_emails help_center campaigns team_management channel_facebook channel_email
        channel_instagram channel_tiktok captain_integration advanced_search_indexing advanced_search
        linear_integration channel_voice sla custom_roles csat_review_notes conversation_required_attributes
        advanced_assignment custom_tools companies audit_logs disable_branding saml
      ].freeze

      class << self
        def enabled?
          ActiveModel::Type::Boolean.new.cast(ENV.fetch('CONVERRA_BILLING_ENABLED', false))
        end

        def plans
          @plans ||= load_plans
        end

        def find(slug)
          plans[slug.to_s]
        end

        def paid_plans
          plans.reject { |_slug, plan| plan['price_ugx'].to_i.zero? }
        end

        def reload!
          @plans = nil
          plans
        end

        private

        def load_plans
          path = Rails.root.join('config/converra_plans.yml')
          return {} unless File.exist?(path)

          YAML.safe_load(File.read(path)) || {}
        end
      end
    end
  end
end
