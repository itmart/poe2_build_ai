class ArchetypeImpactMapper
  def self.call(patch_change)
    Archetype.find_each.filter_map do |archetype|
      matched_tags = matching_tags(archetype, patch_change)
      next if matched_tags.empty?

      raw_score = matched_tags.count.to_f
      signed_score = negative_change?(patch_change.change_type) ? -raw_score : raw_score

      ArchetypeImpact.create!(
        archetype: archetype,
        patch_change: patch_change,
        impact_score: signed_score,
        impact_kind: classify_impact(signed_score),
        reasoning: "Matched tags: #{matched_tags.join(', ')}"
      )
    end
  end

  def self.matching_tags(archetype, patch_change)
    change_tags = patch_change.tags || []
    archetype_tags =
      (archetype.offense_tags || []) +
      (archetype.defense_tags || []) +
      (archetype.core_mechanics || [])

    change_tags & archetype_tags
  end

  def self.negative_change?(change_type)
    %w[nerf removed].include?(change_type)
  end

  def self.classify_impact(score)
    return "direct_buff" if score >= 2
    return "indirect_buff" if score.positive?
    return "direct_nerf" if score <= -2
    return "indirect_nerf" if score.negative?

    "neutral"
  end
end