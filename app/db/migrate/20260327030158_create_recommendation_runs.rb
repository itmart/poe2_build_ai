class CreateRecommendationRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :recommendation_runs do |t|
      t.references :character_snapshot, null: false, foreign_key: true
      t.string :mode
      t.jsonb :input_payload, default: {}
      t.jsonb :output_payload, default: {}

      t.timestamps
    end
  end
end
