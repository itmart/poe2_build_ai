class CharacterSnapshot < ApplicationRecord
  has_many :recommendation_runs, dependent: :destroy
end
