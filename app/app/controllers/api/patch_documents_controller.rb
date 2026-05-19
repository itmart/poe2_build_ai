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

  def summary
    doc = PatchDocument.find(params[:id])
    changes = doc.patch_changes.includes(:archetype_impacts)

    render json: {
      patch_document: {
        id: doc.id,
        title: doc.title,
        version: doc.version,
        document_type: doc.document_type
      },
      totals: {
        changes: changes.count,
        buffs: changes.count { |c| c.change_type == "buff" },
        nerfs: changes.count { |c| c.change_type == "nerf" },
        added: changes.count { |c| c.change_type == "added" },
        removed: changes.count { |c| c.change_type == "removed" }
      },
      biggest_positive_impacts: summarize_impacts(changes, :desc),
      biggest_negative_impacts: summarize_impacts(changes, :asc)
    }
  end

  private

  def summarize_impacts(changes, direction)
    impacts = changes.flat_map(&:archetype_impacts)

    sorted =
      if direction == :desc
        impacts.sort_by { |impact| -impact.impact_score.to_f }
      else
        impacts.sort_by { |impact| impact.impact_score.to_f }
      end

    sorted.first(5).map do |impact|
      {
        archetype: impact.archetype.name,
        impact_score: impact.impact_score,
        impact_kind: impact.impact_kind,
        reasoning: impact.reasoning,
        patch_change_summary: impact.patch_change.summary
      }
    end
  end
end