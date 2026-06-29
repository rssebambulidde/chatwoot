# frozen_string_literal: true

class AddBillingIntervalToConverraPlanPayments < ActiveRecord::Migration[7.1]
  def change
    add_column :converra_plan_payments, :billing_interval, :string, null: false, default: 'monthly'
  end
end
