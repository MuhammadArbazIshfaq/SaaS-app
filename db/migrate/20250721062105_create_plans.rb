class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.decimal :price, precision: 8, scale: 2, default: 0.0
      t.text :features
      t.integer :max_users, default: 1
      t.string :billing_cycle, default: 'monthly'
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :plans, :name, unique: true
    add_index :plans, :active
  end
end
