class AddOrganizationToUsers < ActiveRecord::Migration[8.0]
  def change
    # First add the column as nullable
    add_reference :users, :organization, null: true, foreign_key: true
    
    # Create a default organization for existing users
    reversible do |dir|
      dir.up do
        # Create a default organization
        default_org = Organization.create!(
          name: 'Default Organization',
          subdomain: 'default'
        )
        
        # Update existing users to belong to the default organization
        User.where(organization_id: nil).update_all(organization_id: default_org.id)
        
        # Now make the column NOT NULL
        change_column_null :users, :organization_id, false
      end
      
      dir.down do
        # Make column nullable again before removing
        change_column_null :users, :organization_id, true
      end
    end
  end
end
