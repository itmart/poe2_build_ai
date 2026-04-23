class ArchetypeRecommender
  def self.call
    Archetype.all.map do |archetype|
      impacts = archetype.archetype_impacts.includes(:patch_change)
      score = impacts.sum(:impact_score)

      {
        name: archetype.name,
        class_name: archetype.class_name,
        ascendancy_name: archetype.ascendancy_name,
        primary_skill: archetype.primary_skill,
        score: score,
        status: status_for(score),
        reasons: impacts.order(created_at: :desc).limit(5).map do |impact|
          {
            kind: impact.impact_kind,
            score: impact.impact_score,
            reasoning: impact.reasoning,
            change: impact.patch_change.summary
          }
        end
      }
    end.sort_by { |row| -row[:score].to_f }
  end

  def self.status_for(score)
    return "buffed" if score.positive?
    return "nerfed" if score.negative?

    "neutral"
  end
end