class Archetype < ApplicationRecord
  has_many :archetype_impacts, dependent: :destroy
end
