class CreateArchetypeImpacts < ActiveRecord::Migration[8.1]
  def change
    create_table :archetype_impacts do |t|
      t.references :archetype, null: false, foreign_key: true
      t.references :patch_change, null: false, foreign_key: true
      t.float :impact_score
      t.string :impact_kind
      t.text :reasoning

      t.timestamps
    end
  end
end
