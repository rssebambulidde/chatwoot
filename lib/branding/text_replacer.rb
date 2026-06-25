# frozen_string_literal: true

module Branding
  module TextReplacer
    module_function

    def replace(text, installation_name:)
      return text if text.blank? || installation_name.blank?

      text
        .gsub('Chatwoot AI', "#{installation_name} AI")
        .gsub('CHATWOOT', installation_name.upcase)
        .gsub('Chatwoot', installation_name)
        .gsub('chatwoot', installation_name.downcase)
    end
  end
end
