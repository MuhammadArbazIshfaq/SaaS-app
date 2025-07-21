class AddPlanToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_reference :organizations, :plan, null: true, foreign_key: true
    add_column :organizations, :status, :string, default: 'trial'
    add_column :organizations, :trial_ends_at, :datetime
    
    # Remove old columns if you don't need them
    # add_column :organizations, :plan, :string
    # add_column :organizations, :plan_price, :decimal
    # add_column :organizations, :plan_features, :text
  end
end
