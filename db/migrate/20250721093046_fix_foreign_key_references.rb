class FixForeignKeyReferences < ActiveRecord::Migration[8.0]
  def change
    # Remove incorrect foreign keys
    remove_foreign_key "artifacts", "uploaded_bies" if foreign_key_exists?("artifacts", "uploaded_bies")
    remove_foreign_key "invitations", "invited_bies" if foreign_key_exists?("invitations", "invited_bies")
    remove_foreign_key "projects", "created_bies" if foreign_key_exists?("projects", "created_bies")
    
    # Add correct foreign keys pointing to users table
    add_foreign_key "artifacts", "users", column: "uploaded_by_id"
    add_foreign_key "invitations", "users", column: "invited_by_id"
    add_foreign_key "projects", "users", column: "created_by_id"
  end
end
