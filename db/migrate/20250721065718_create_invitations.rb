class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.string :email
      t.string :role
      t.references :organization, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: true
      t.string :token
      t.datetime :accepted_at

      t.timestamps
    end
  end
end
