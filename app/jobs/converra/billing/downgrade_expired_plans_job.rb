# frozen_string_literal: true

class Converra::Billing::DowngradeExpiredPlansJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Converra::Billing::DowngradeExpiredPlansService.new.perform
  end
end
