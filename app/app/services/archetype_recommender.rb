class ArchetypeRecommender
  def self.call
    ranked = ranked_archetypes

    {
      biggest_winners: ranked.select { |row| row[:score] > 0 }.first(5),
      biggest_losers: ranked.select { |row| row[:score] < 0 }.sort_by { |row| row[:score] }.first(5),
      neutral_builds: ranked.select { |row| row[:score] == 0 }.first(5),
      archetypes: ranked
    }
  end

  def self.ranked_archetypes
    Archetype.includes(archetype_impacts: :patch_change).map do |archetype|
      impacts = archetype.archetype_impacts.to_a
      total_score = impacts.sum { |impact| impact.impact_score.to_f }

      {
        name: archetype.name,
        class_name: archetype.class_name,
        ascendancy_name: archetype.ascendancy_name,
        primary_skill: archetype.primary_skill,
        score: total_score,
        status: status_for(total_score),
        summary: summary_for(archetype, total_score),
        reasons: top_reasons_for(impacts)
      }
    end.sort_by { |row| -row[:score].to_f }
  end

  def self.status_for(score)
    return "buffed" if score > 0
    return "nerfed" if score < 0

    "neutral"
  end

  def self.summary_for(archetype, score)
    if score > 0
      "#{archetype.name} looks stronger after recent patch changes."
    elsif score < 0
      "#{archetype.name} looks weaker after recent patch changes."
    else
      "#{archetype.name} looks mostly unchanged so far."
    end
  end

  def self.top_reasons_for(impacts)
    impacts
      .sort_by { |impact| -impact.impact_score.to_f.abs }
      .first(5)
      .map do |impact|
        {
          impact_kind: impact.impact_kind,
          impact_score: impact.impact_score,
          reasoning: impact.reasoning,
          patch_change: {
            id: impact.patch_change.id,
            entity_name: impact.patch_change.entity_name,
            entity_type: impact.patch_change.entity_type,
            change_type: impact.patch_change.change_type,
            summary: impact.patch_change.summary,
            tags: impact.patch_change.tags
          }
        }
      end
  end
end