# frozen_string_literal: true

class Converra::Billing::RenewalReminderJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    return unless Converra::Billing::PlanCatalog.enabled?

    reminder_window = 7.days.from_now.beginning_of_day..7.days.from_now.end_of_day

    Account.where("custom_attributes ->> 'subscription_ends_on' IS NOT NULL").find_each do |account|
      ends_on = account.custom_attributes['subscription_ends_on']
      next if ends_on.blank?

      renewal_at = Time.zone.parse(ends_on)
      next unless reminder_window.cover?(renewal_at)
      next if account.custom_attributes['renewal_reminder_sent_at'] == renewal_at.to_date.iso8601

      Converra::BillingMailer.renewal_reminder(account: account).deliver_later
      account.update!(
        custom_attributes: account.custom_attributes.merge(
          'renewal_reminder_sent_at' => renewal_at.to_date.iso8601
        )
      )
    end
  end
end
