# frozen_string_literal: true

module Branding
  module TextReplacer
    module_function

    def replace(text, installation_name:, captain_name: 'Captain')
      return text if text.blank?

      result = replace_installation_name(text, installation_name: installation_name)
      replace_captain_name(result, captain_name: captain_name)
    end

    def replace_installation_name(text, installation_name:)
      return text if text.blank? || installation_name.blank?

      text
        .gsub('Chatwoot AI', "#{installation_name} AI")
        .gsub('CHATWOOT', installation_name.upcase)
        .gsub('Chatwoot', installation_name)
        .gsub('chatwoot', installation_name.downcase)
    end

    def replace_captain_name(text, captain_name:)
      return text if text.blank? || captain_name.blank? || captain_name == 'Captain'

      text
        .gsub('Captain AI', captain_name)
        .gsub('CAPTAIN', captain_name.upcase)
        .gsub('Captain', captain_name)
    end
  end
end
