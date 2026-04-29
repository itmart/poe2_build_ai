class Api::RecommendationsController < ApplicationController
  protect_from_forgery with: :null_session

  def league_starters
    render json: ArchetypeRecommender.call
  end

  def diagnose_build
    snapshot = CharacterSnapshot.create!(
      name: params[:name],
      class_name: params[:class_name],
      ascendancy_name: params[:ascendancy_name],
      level: params[:level],
      skills: params[:skills] || {},
      stats: params[:stats] || {},
      defenses: params[:defenses] || {},
      gear: params[:gear] || {},
      passives: params[:passives] || {},
      constraints: params[:constraints] || {}
    )

    result = CharacterDoctor.call(snapshot)

    RecommendationRun.create!(
      character_snapshot: snapshot,
      mode: "diagnose_build",
      input_payload: snapshot.attributes.slice(
        "name", "class_name", "ascendancy_name", "level",
        "skills", "stats", "defenses", "gear", "passives", "constraints"
      ),
      output_payload: result
    )

    render json: result
  end
end