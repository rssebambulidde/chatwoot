# frozen_string_literal: true

class CreateConverraPlanPayments < ActiveRecord::Migration[7.1]
  def change
    create_table :converra_plan_payments do |t|
      t.references :account, null: false, foreign_key: true
      t.string :plan_slug, null: false
      t.integer :amount, null: false
      t.string :currency, null: false, default: 'UGX'
      t.integer :status, null: false, default: 0
      t.string :merchant_reference, null: false
      t.string :order_tracking_id
      t.string :payment_status
      t.string :redirect_url
      t.string :description
      t.string :billing_email
      t.string :billing_name
      t.datetime :completed_at

      t.timestamps
    end

    add_index :converra_plan_payments, :merchant_reference, unique: true
    add_index :converra_plan_payments, :order_tracking_id
  end
end
