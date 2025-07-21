class AddProjectLimitToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :project_limit, :integer, default: 1
    
    # Update existing plans with appropriate project limits
    reversible do |dir|
      dir.up do
        # Set Free plan to 1 project, Premium to unlimited (0 = unlimited)
        execute "UPDATE plans SET project_limit = 1 WHERE name = 'Free'"
        execute "UPDATE plans SET project_limit = 0 WHERE name = 'Premium'"
      end
    end
  end
end
