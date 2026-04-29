# == Schema Information
#
# Table name: character_snapshots
#
#  id              :bigint           not null, primary key
#  ascendancy_name :string
#  class_name      :string
#  constraints     :jsonb
#  defenses        :jsonb
#  gear            :jsonb
#  level           :integer
#  name            :string
#  passives        :jsonb
#  skills          :jsonb
#  stats           :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require "test_helper"

class CharacterSnapshotTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
