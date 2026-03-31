class CreateArchetypes < ActiveRecord::Migration[8.1]
  def change
    create_table :archetypes do |t|
      t.string :name
      t.string :class_name
      t.string :ascendancy_name
      t.string :primary_skill
      t.jsonb :offense_tags, default: []
      t.jsonb :defense_tags, default: []
      t.jsonb :core_mechanics, default: []
      t.text :leveling_notes
      t.text :failure_modes

      t.timestamps
    end
  end
end
