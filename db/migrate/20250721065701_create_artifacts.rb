class CreateArtifacts < ActiveRecord::Migration[8.0]
  def change
    create_table :artifacts do |t|
      t.string :name
      t.text :description
      t.string :artifact_type
      t.references :project, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: true

      t.timestamps
    end
  end
end
