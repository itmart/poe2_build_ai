class CreatePatchDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :patch_documents do |t|
      t.string :title
      t.string :source_url
      t.string :version
      t.string :document_type
      t.datetime :published_at
      t.text :raw_text
      t.jsonb :metadata, default: {}

      t.timestamps
    end
  end
end
