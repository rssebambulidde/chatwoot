module Enterprise::ChatwootHub
  ENTERPRISE_BASE_URL = 'https://hub.2.chatwoot.com'.freeze
  SELF_HOSTED_PLAN = 'enterprise'.freeze
  SELF_HOSTED_PLAN_QUANTITY = 10_000

  def base_url
    return ENV.fetch('CHATWOOT_HUB_URL', ENTERPRISE_BASE_URL) if Rails.env.development?

    ENTERPRISE_BASE_URL
  end

  def pricing_plan
    return super if ChatwootApp.chatwoot_cloud?

    SELF_HOSTED_PLAN
  end

  def pricing_plan_quantity
    return super if ChatwootApp.chatwoot_cloud?

    SELF_HOSTED_PLAN_QUANTITY
  end
end
