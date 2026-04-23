class Api::PatchDocumentsController < ApplicationController
  protect_from_forgery with: :null_session

  def index
    render json: PatchDocument.order(created_at: :desc).limit(20)
  end

  def show
    render json: PatchDocument.find(params[:id])
  end

  def create
    doc = PatchDocument.create!(
      title: params[:title].presence || params[:source_url],
      source_url: params[:source_url],
      version: params[:version],
      document_type: params[:document_type].presence || "patch_notes",
      raw_text: params[:raw_text],
      metadata: {}
    )

    render json: doc, status: :created
  end

  def parse
    doc = PatchDocument.find(params[:id])

    changes = BasicPatchParser.call(doc.raw_text)

    created = changes.map do |change|
      patch_change = doc.patch_changes.create!(change)
      ArchetypeImpactMapper.call(patch_change)
      patch_change
    end

    render json: {
      patch_document_id: doc.id,
      changes_created: created.count,
      changes: created
    }
  end
end