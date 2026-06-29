# frozen_string_literal: true

class ConverraPlanPayment < ApplicationRecord
  belongs_to :account

  enum status: { pending: 0, completed: 1, failed: 2 }

  validates :merchant_reference, presence: true, uniqueness: true
  validates :plan_slug, :amount, :currency, presence: true

  def complete!
    update!(status: :completed, completed_at: Time.current)
  end

  def completed?
    status == 'completed'
  end
end
