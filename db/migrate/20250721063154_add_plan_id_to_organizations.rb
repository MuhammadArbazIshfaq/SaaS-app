class AddPlanIdToOrganizations < ActiveRecord::Migration[8.0]
  def change
    # Add the plan_id column as nullable first
    add_reference :organizations, :plan, null: true, foreign_key: true
    
    # Set default plan for existing organizations
    reversible do |dir|
      dir.up do
        # Get or create a free plan
        free_plan = Plan.find_or_create_by!(name: 'Free') do |plan|
          plan.price = 0.00
          plan.billing_cycle = 'monthly'
          plan.max_users = 1
          plan.features = "Basic features\nEmail support\n1 user limit"
          plan.active = true
        end
        
        # Update existing organizations to use the free plan
        Organization.where(plan_id: nil).update_all(plan_id: free_plan.id)
      end
    end
  end
end
