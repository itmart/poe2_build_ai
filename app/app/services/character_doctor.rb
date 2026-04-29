class CharacterDoctor
  def self.call(snapshot)
    archetype = ArchetypeMatcher.call(snapshot)

    general_issues = general_issues_for(snapshot)
    archetype_issues = archetype ? archetype_specific_issues_for(snapshot, archetype) : []
    gear_analysis = GearEvaluator.call(snapshot, archetype)
    focus_recommendations = ProblemFocusRecommender.call(snapshot, archetype, gear_analysis)
    recommendations = build_recommendations(
      snapshot,
      general_issues,
      archetype_issues,
      archetype,
      gear_analysis,
      focus_recommendations
    )

    {
      matched_archetype: archetype&.name,
      problem_focus: snapshot.constraints&.dig("problem_focus"),
      general_issues: general_issues,
      archetype_issues: archetype_issues,
      weakest_slots: gear_analysis[:weakest_slots],
      target_stats_by_slot: gear_analysis[:target_stats_by_slot],
      focus_recommendations: focus_recommendations,
      recommendations: recommendations.uniq
    }
  end

  def self.general_issues_for(snapshot)
    issues = []

    defenses = snapshot.defenses || {}
    gear = snapshot.gear || {}
    level = snapshot.level.to_i

    fire_res = defenses["fire_res"].to_i
    cold_res = defenses["cold_res"].to_i
    lightning_res = defenses["lightning_res"].to_i
    life = defenses["life"].to_i

    if [fire_res, cold_res, lightning_res].min < 75
      issues << {
        type: "defense",
        severity: "high",
        message: "Elemental resistances are not capped."
      }
    end

    if level >= 30 && life > 0 && life < (level * 20)
      issues << {
        type: "defense",
        severity: "medium",
        message: "Life is low for your current level."
      }
    end

    weapon = gear["weapon"] || {}
    weapon_score = weapon["dps_score"].to_i

    if weapon_score > 0 && weapon_score < (level * 3)
      issues << {
        type: "offense",
        severity: "high",
        message: "Weapon looks weak for your level."
      }
    end

    issues
  end

  def self.archetype_specific_issues_for(snapshot, archetype)
    case archetype.name
    when "Lightning Bow Deadeye"
      lightning_bow_deadeye_issues(snapshot)
    when "Minion Infernalist"
      minion_infernalist_issues(snapshot)
    when "Poison Pathfinder"
      poison_pathfinder_issues(snapshot)
    else
      generic_archetype_issues(archetype)
    end
  end

  def self.lightning_bow_deadeye_issues(snapshot)
    issues = []
    gear = snapshot.gear || {}
    skills = snapshot.skills || {}

    weapon = gear["weapon"] || {}
    weapon_score = weapon["dps_score"].to_i
    skill_blob = skills.to_s.downcase

    if weapon_score < 120
      issues << {
        type: "offense",
        severity: "high",
        message: "Bow weapon is likely too weak for a projectile attack build."
      }
    end

    unless skill_blob.include?("lightning")
      issues << {
        type: "setup",
        severity: "medium",
        message: "Current skill setup may not be strongly aligned with lightning scaling."
      }
    end

    issues
  end

  def self.minion_infernalist_issues(snapshot)
    issues = []
    skills = snapshot.skills || {}
    skill_blob = skills.to_s.downcase

    unless skill_blob.include?("minion") || skill_blob.include?("summon")
      issues << {
        type: "setup",
        severity: "high",
        message: "Skill setup does not clearly show core minion skills or supports."
      }
    end

    issues << {
      type: "offense",
      severity: "medium",
      message: "Minion builds often fall off when gem levels and support links lag behind progression."
    }

    issues
  end

  def self.poison_pathfinder_issues(snapshot)
    issues = []
    skills = snapshot.skills || {}
    defenses = snapshot.defenses || {}
    skill_blob = skills.to_s.downcase

    unless skill_blob.include?("poison") || skill_blob.include?("chaos")
      issues << {
        type: "setup",
        severity: "medium",
        message: "Current setup does not clearly show poison or chaos scaling."
      }
    end

    if defenses["life"].to_i < 500
      issues << {
        type: "defense",
        severity: "medium",
        message: "Poison pathfinder setup may be too fragile for smooth progression."
      }
    end

    issues
  end

  def self.generic_archetype_issues(archetype)
    failure_modes = if archetype.failure_modes.is_a?(Array)
      archetype.failure_modes
    else
      archetype.failure_modes.to_s.split(",").map(&:strip)
    end

    failure_modes.reject(&:blank?).map do |failure|
      {
        type: "archetype",
        severity: "low",
        message: failure
      }
    end
  end

  def self.build_recommendations(snapshot, general_issues, archetype_issues, archetype, gear_analysis, focus_recommendations)
    recommendations = []
    focus = snapshot.constraints&.dig("problem_focus").to_s.downcase

    recommendations.concat(focus_recommendations)

    if general_issues.any? { |i| i[:message].include?("Elemental resistances are not capped") }
      recommendations << "Replace weaker rare gear slots with life + resistance items until elemental resistances are capped."
    end

    if general_issues.any? { |i| i[:message].include?("Life is low") }
      recommendations << "Take efficient nearby life nodes and prioritize life on rare gear."
    end

    if general_issues.any? { |i| i[:message].include?("Weapon looks weak") }
      recommendations << "Upgrade your weapon first before making smaller gear changes."
    end

    weakest_slot = gear_analysis[:weakest_slots].first
    if weakest_slot
      recommendations << "Your weakest slot currently looks like #{weakest_slot[:slot]}. Prioritize replacing it next."
    end

    case archetype&.name
    when "Lightning Bow Deadeye"
      recommendations << "Prioritize bow upgrades with stronger base damage and lightning/projectile-friendly stats."
      recommendations << "Look for quiver, rings, and gloves that support attack damage, accuracy, and resist coverage."
    when "Minion Infernalist"
      recommendations << "Prioritize minion gem progression, support links, and survivability before luxury upgrades."
      recommendations << "Look for gear that improves defenses while keeping minion scaling on pace."
    when "Poison Pathfinder"
      recommendations << "Prioritize consistent poison/chaos scaling and avoid overinvesting in unrelated hit damage."
      recommendations << "Use rare gear upgrades to balance survivability with poison-focused offensive stats."
    end

    if archetype_issues.any? { |i| i[:type] == "setup" }
      recommendations << "Review your main skill and support setup so it matches the intended archetype scaling."
    end

    prioritize_recommendations(recommendations.uniq, focus)
  end

  def self.prioritize_recommendations(recommendations, focus)
    return recommendations if focus.blank?

    priorities =
      case focus
      when "damage"
        ["damage", "weapon", "offense", "projectile", "lightning", "poison", "minion"]
      when "survivability"
        ["life", "resistance", "defense", "survivability"]
      when "bossing"
        ["boss", "single-target", "weapon", "damage"]
      when "clear"
        ["clear", "movement", "tempo", "projectile"]
      when "mana"
        ["mana", "cost", "sustain", "links"]
      else
        []
      end

    recommendations.sort_by do |rec|
      text = rec.downcase
      matched = priorities.any? { |keyword| text.include?(keyword) }
      matched ? 0 : 1
    end
  end
end