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
      input_payload: {
        class_name: snapshot.class_name,
        ascendancy_name: snapshot.ascendancy_name,
        level: snapshot.level,
        skills: snapshot.skills,
        defenses: snapshot.defenses,
        gear: snapshot.gear,
        passives: snapshot.passives,
        constraints: snapshot.constraints
      },
      output_payload: result
    )

    render json: result
  end
end