# == Schema Information
#
# Table name: archetypes
#
#  id              :bigint           not null, primary key
#  ascendancy_name :string
#  class_name      :string
#  core_mechanics  :jsonb
#  defense_tags    :jsonb
#  failure_modes   :text
#  leveling_notes  :text
#  name            :string
#  offense_tags    :jsonb
#  primary_skill   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Archetype < ApplicationRecord
  has_many :archetype_impacts, dependent: :destroy
end
