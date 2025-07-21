class CleanupInvalidInvitations < ActiveRecord::Migration[8.0]
  def up
    # Remove invitations with missing required fields
    execute <<-SQL
      DELETE FROM invitations 
      WHERE email IS NULL 
         OR role IS NULL 
         OR token IS NULL 
         OR organization_id IS NULL 
         OR project_id IS NULL 
         OR invited_by_id IS NULL
    SQL
  end

  def down
    # This migration is irreversible since we're deleting invalid data
    raise ActiveRecord::IrreversibleMigration
  end
end
