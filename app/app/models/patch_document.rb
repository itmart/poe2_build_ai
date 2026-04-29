# == Schema Information
#
# Table name: patch_documents
#
#  id            :bigint           not null, primary key
#  document_type :string
#  metadata      :jsonb
#  published_at  :datetime
#  raw_text      :text
#  source_url    :string
#  title         :string
#  version       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class PatchDocument < ApplicationRecord
  has_many :patch_changes, dependent: :destroy
end
