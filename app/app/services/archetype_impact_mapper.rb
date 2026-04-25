class ArchetypeImpactMapper
  def self.call(patch_change)
    Archetype.find_each.filter_map do |archetype|
      matched_tags = matching_tags(archetype, patch_change)
      next if matched_tags.empty?

      raw_score = score_match(archetype, matched_tags)
      signed_score = negative_change?(patch_change.change_type) ? -raw_score : raw_score

      impact = ArchetypeImpact.find_or_initialize_by(
        archetype: archetype,
        patch_change: patch_change
      )

      impact.impact_score = signed_score
      impact.impact_kind = classify_impact(signed_score)
      impact.reasoning = "Matched tags: #{matched_tags.join(', ')}"
      impact.save!

      impact
    end
  end

  def self.score_match(archetype, matched_tags)
    score = 0.0

    matched_tags.each do |tag|
      score += 1.5 if Array(archetype.core_mechanics).include?(tag)
      score += 1.0 if Array(archetype.offense_tags).include?(tag)
      score += 0.75 if Array(archetype.defense_tags).include?(tag)
    end

    score
  end

  def self.matching_tags(archetype, patch_change)
    change_tags = normalize_tags(patch_change.tags).map(&:to_s)
    archetype_tags =
      Array(archetype.offense_tags).map(&:to_s) +
      Array(archetype.defense_tags).map(&:to_s) +
      Array(archetype.core_mechanics).map(&:to_s)

    change_tags & archetype_tags
  end

  def self.negative_change?(change_type)
    %w[nerf removed].include?(change_type.to_s)
  end

  def self.classify_impact(score)
    return "direct_buff" if score >= 2
    return "indirect_buff" if score.positive?
    return "direct_nerf" if score <= -2
    return "indirect_nerf" if score.negative?

    "neutral"
  end

  def self.normalize_tags(tags)
    Array(tags).map(&:to_s).flat_map do |tag|
      case tag.downcase
      when "projectile_scaling" then ["projectile_scaling", "projectile"]
      when "minion_scaling" then ["minion_scaling", "minion"]
      when "attack_speed" then ["attack_speed", "attack"]
      else
        [tag.downcase]
      end
    end.uniq
  end
end