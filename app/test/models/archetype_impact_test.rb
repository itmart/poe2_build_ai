# == Schema Information
#
# Table name: archetype_impacts
#
#  id              :bigint           not null, primary key
#  impact_kind     :string
#  impact_score    :float
#  reasoning       :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  archetype_id    :bigint           not null
#  patch_change_id :bigint           not null
#
# Indexes
#
#  index_archetype_impacts_on_archetype_id     (archetype_id)
#  index_archetype_impacts_on_patch_change_id  (patch_change_id)
#
# Foreign Keys
#
#  fk_rails_...  (archetype_id => archetypes.id)
#  fk_rails_...  (patch_change_id => patch_changes.id)
#
require "test_helper"

class ArchetypeImpactTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
