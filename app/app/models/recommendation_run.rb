# == Schema Information
#
# Table name: recommendation_runs
#
#  id                    :bigint           not null, primary key
#  input_payload         :jsonb
#  mode                  :string
#  output_payload        :jsonb
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  character_snapshot_id :bigint           not null
#
# Indexes
#
#  index_recommendation_runs_on_character_snapshot_id  (character_snapshot_id)
#
# Foreign Keys
#
#  fk_rails_...  (character_snapshot_id => character_snapshots.id)
#
class RecommendationRun < ApplicationRecord
  belongs_to :character_snapshot
end
