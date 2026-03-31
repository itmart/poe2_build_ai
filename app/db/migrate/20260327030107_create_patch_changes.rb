class CreatePatchChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :patch_changes do |t|
      t.references :patch_document, null: false, foreign_key: true
      t.string :entity_name
      t.string :entity_type
      t.string :change_type
      t.text :before_text
      t.text :after_text
      t.text :summary
      t.jsonb :tags, default: []
      t.jsonb :numeric_data, default: {}
      t.float :confidence

      t.timestamps
    end
  end
end
