class SuperAdmin::AccountsController < SuperAdmin::ApplicationController
  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, you may want to send an email after a foo is updated.
  #
  # def update
  #   super
  #   send_foo_updated_email(requested_resource)
  # end

  # Override this method to specify custom lookup behavior.
  # This will be used to set the resource for the `show`, `edit`, and `update`
  # actions.
  #
  # def find_resource(param)
  #   Foo.find_by!(slug: param)
  # end

  # The result of this lookup will be available as `requested_resource`

  # Override this if you have certain roles that require a subset
  # this will be used to set the records shown on the `index` action.
  #
  # def scoped_resource
  #   if current_user.super_admin?
  #     resource_class
  #   else
  #     resource_class.with_less_stuff
  #   end
  # end

  # Override `resource_params` if you want to transform the submitted
  # data before it's persisted. For example, the following would turn all
  # empty values into nil values. It uses other APIs such as `resource_class`
  # and `dashboard`:
  #
  def resource_params
    permitted_params = super
    permitted_params[:limits] = permitted_params[:limits].to_h.compact
    permitted_params[:selected_feature_flags] = params[:enabled_features].keys.map(&:to_sym) if params[:enabled_features].present?
    permitted_params
  end

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information

  def seed
    Internal::SeedAccountJob.perform_later(requested_resource)
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account seeding triggered')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def reset_cache
    requested_resource.reset_cache_keys
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Cache keys cleared')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def change_plan
    unless Converra::Billing::PlanCatalog.enabled?
      redirect_back(fallback_location: [namespace, requested_resource], alert: 'Converra billing is not enabled')
      return
    end

    plan_slug = params[:plan_slug].to_s
    current_plan_slug = requested_resource.custom_attributes['plan_name'].presence || 'starter'
    if plan_slug == current_plan_slug
      redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account is already on this plan')
      return
    end

    plan = Converra::Billing::PlanCatalog.find(plan_slug)
    if plan.blank?
      redirect_back(fallback_location: [namespace, requested_resource], alert: "Unknown plan: #{plan_slug}")
      return
    end

    current_plan = Converra::Billing::PlanCatalog.find(current_plan_slug)
    old_copilot_limit = current_plan&.dig('limits', 'captain_responses').to_i
    new_copilot_limit = plan.dig('limits', 'captain_responses').to_i

    Converra::Billing::ApplyPlanService.new(
      account: requested_resource,
      plan_slug: plan_slug,
      subscription_ends_on: subscription_ends_on_for(plan),
      clear_cancel_at_period_end: true
    ).perform

    if new_copilot_limit > old_copilot_limit
      Converra::Billing::ResetCaptainUsageService.new(account: requested_resource.reload).perform
    end

    redirect_back(
      fallback_location: [namespace, requested_resource],
      notice: "Account plan changed to #{plan['name']}"
    )
  rescue ArgumentError => e
    redirect_back(fallback_location: [namespace, requested_resource], alert: e.message)
  end

  def destroy
    account = Account.find(params[:id])

    DeleteObjectJob.perform_later(account) if account.present?
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account deletion is in progress.')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  private

  def subscription_ends_on_for(plan)
    return nil if plan['price_ugx'].to_i.zero?

    custom = params[:subscription_ends_on].presence
    if custom.present?
      parsed = Time.zone.parse(custom)
      return parsed.end_of_day if parsed.present?
    end

    existing = requested_resource.custom_attributes['subscription_ends_on']
    if existing.present?
      parsed = Time.zone.parse(existing)
      return parsed if parsed > Time.current
    end

    1.month.from_now
  end
end

SuperAdmin::AccountsController.prepend_mod_with('SuperAdmin::AccountsController')
