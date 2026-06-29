module Enterprise::Captain::BaseTaskService
  def perform
    return { error: copilot_limit_message, error_code: 429 } if counts_toward_usage? && !responses_available?

    unless captain_tasks_enabled?
      return { error: I18n.t('captain.upgrade') } if ChatwootApp.chatwoot_cloud? || converra_billing_enabled?

      return { error: I18n.t('captain.disabled') }
    end

    result = super
    increment_usage if counts_toward_usage? && successful_result?(result)
    result
  end

  private

  def responses_available?
    return true unless ChatwootApp.chatwoot_cloud? || converra_billing_enabled?

    account.usage_limits[:captain][:responses][:current_available].positive?
  end

  def converra_billing_enabled?
    defined?(Converra::Billing::PlanCatalog) && Converra::Billing::PlanCatalog.enabled?
  end

  def copilot_limit_message
    if converra_billing_enabled?
      I18n.t('converra_billing.copilot_limit')
    else
      I18n.t('captain.copilot_limit')
    end
  end

  def successful_result?(result)
    result.is_a?(Hash) && result[:message].present? && !result[:error]
  end

  def increment_usage
    Rails.logger.info("[CAPTAIN][#{self.class.name}] Incrementing response usage for account #{account.id}")
    account.increment_response_usage
  end
end
