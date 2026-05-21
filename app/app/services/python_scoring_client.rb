class PythonScoringClient
  include HTTParty

  def self.base_uri
    ENV.fetch("PYTHON_SERVICE_URL", "http://python_service:8001")
  end

  def self.score_upgrade_plan(archetype:, snapshot:, general_issues:, archetype_issues:, weakest_slots:, upgrade_plan:, problem_focus:)
    response = HTTParty.post(
      "#{base_uri}/score_upgrade_plan",
      headers: { "Content-Type" => "application/json" },
      body: {
        archetype: archetype,
        character_snapshot: snapshot,
        general_issues: general_issues,
        archetype_issues: archetype_issues,
        weakest_slots: weakest_slots,
        upgrade_plan: upgrade_plan,
        problem_focus: problem_focus
      }.to_json,
      timeout: 5
    )

    parsed_response(response)
  rescue => e
    {
      "error" => e.message,
      "upgrade_plan" => upgrade_plan,
      "confidence" => 0.0
    }
  end

  def self.score_archetype(archetype:, patch_impacts:, character_snapshot: nil)
    response = HTTParty.post(
      "#{base_uri}/score_archetype",
      headers: { "Content-Type" => "application/json" },
      body: {
        archetype: archetype,
        patch_impacts: patch_impacts,
        character_snapshot: character_snapshot
      }.to_json,
      timeout: 5
    )

    parsed_response(response)
  rescue => e
    {
      "error" => e.message,
      "league_start_score" => 0.0,
      "confidence" => 0.0
    }
  end

  def self.parsed_response(response)
    if response.success?
      response.parsed_response
    else
      {
        "error" => "Python service returned #{response.code}",
        "details" => response.body
      }
    end
  end
end