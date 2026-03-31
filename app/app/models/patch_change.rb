class PatchChange < ApplicationRecord
  belongs_to :patch_document
  has_many :archetype_impacts, dependent: :destroy
end
