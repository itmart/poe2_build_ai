class PatchDocument < ApplicationRecord
  has_many :patch_changes, dependent: :destroy
end
