class CreateCharacterSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :character_snapshots do |t|
      t.string :name
      t.string :class_name
      t.string :ascendancy_name
      t.integer :level
      t.jsonb :skills, default: {}
      t.jsonb :stats, default: {}
      t.jsonb :defenses, default: {}
      t.jsonb :gear, default: {}
      t.jsonb :passives, default: {}
      t.jsonb :constraints, default: {}

      t.timestamps
    end
  end
end
