# == Schema Information
#
# Table name: patch_changes
#
#  id                :bigint           not null, primary key
#  after_text        :text
#  before_text       :text
#  change_type       :string
#  confidence        :float
#  entity_name       :string
#  entity_type       :string
#  numeric_data      :jsonb
#  summary           :text
#  tags              :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  patch_document_id :bigint           not null
#
# Indexes
#
#  index_patch_changes_on_patch_document_id  (patch_document_id)
#
# Foreign Keys
#
#  fk_rails_...  (patch_document_id => patch_documents.id)
#
class PatchChange < ApplicationRecord
  belongs_to :patch_document
  has_many :archetype_impacts, dependent: :destroy
end
