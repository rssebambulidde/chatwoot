# frozen_string_literal: true

class Converra::Billing::ResetExpiredCaptainUsageJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Converra::Billing::ResetExpiredCaptainUsageService.new.perform
  end
end
