class UpgradePlanner
  def self.call(snapshot, archetype, general_issues, archetype_issues, gear_analysis)
    focus = snapshot.constraints&.dig("problem_focus").to_s.downcase

    plan = []

    if should_prioritize_weapon?(snapshot, archetype, general_issues, archetype_issues, focus)
      plan << {
        priority_score: weapon_priority_score(focus),
        slot: "weapon",
        reason: weapon_reason(archetype, focus),
        target_stats: GearEvaluator.target_stats_for("weapon", archetype)
      }
    end

    gear_analysis[:weakest_slots].each do |slot_data|
      slot = slot_data[:slot]
      next if slot == "weapon" && plan.any? { |item| item[:slot] == "weapon" }

      score = base_priority_for(slot, general_issues, archetype, focus)

      plan << {
        priority_score: score,
        slot: slot,
        reason: slot_reason(slot, general_issues, archetype, focus),
        target_stats: slot_data[:target_stats]
      }
    end

    plan
      .uniq { |item| item[:slot] }
      .sort_by { |item| -item[:priority_score] }
      .first(3)
      .each_with_index
      .map do |item, index|
        {
          priority: index + 1,
          slot: item[:slot],
          reason: item[:reason],
          target_stats: item[:target_stats]
        }
      end
  end

  def self.weapon_priority_score(focus)
    case focus
    when "damage"
      140
    when "bossing"
      145
    when "clear"
      120
    else
      100
    end
  end

  def self.should_prioritize_weapon?(snapshot, archetype, general_issues, archetype_issues, focus)
    return true if %w[damage bossing clear].include?(focus)
    return true if general_issues.any? { |i| i[:message].include?("Weapon looks weak") }
    return true if archetype_issues.any? { |i| i[:message].downcase.include?("weapon") }

    weapon = (snapshot.gear || {})["weapon"] || {}
    weapon_score = weapon["dps_score"].to_i

    case archetype&.name
    when "Lightning Bow Deadeye"
      weapon_score < 120
    when "Poison Pathfinder"
      weapon_score < 100
    else
      false
    end
  end

  def self.weapon_reason(archetype, focus)
    return "Weapon is the top priority because your current focus is #{focus}." if %w[damage bossing clear].include?(focus)

    case archetype&.name
    when "Lightning Bow Deadeye"
      "Largest immediate damage upgrade for this bow build."
    when "Poison Pathfinder"
      "Weapon upgrade improves core offensive consistency."
    when "Minion Infernalist"
      "Weapon should support minion progression and scaling."
    else
      "Weapon is one of the highest-impact upgrade slots right now."
    end
  end

  def self.base_priority_for(slot, general_issues, archetype, focus)
    score = 20

    if %w[ring1 ring2 belt boots gloves helmet chest].include?(slot) &&
       general_issues.any? { |i| i[:message].include?("Elemental resistances are not capped") }
      score += 25
    end

    if %w[ring1 ring2 belt boots gloves helmet chest].include?(slot) &&
       general_issues.any? { |i| i[:message].include?("Life is low") }
      score += 15
    end

    if slot == "quiver" && archetype&.name == "Lightning Bow Deadeye"
      score += 18
    end

    if %w[ring1 ring2].include?(slot) && archetype&.name == "Lightning Bow Deadeye"
      score += 12
    end

    case focus
    when "damage"
      score += 20 if %w[quiver ring1 ring2 amulet gloves].include?(slot)
      score -= 10 if %w[boots helmet chest belt].include?(slot)
    when "bossing"
      score += 22 if %w[quiver amulet ring1 ring2].include?(slot)
      score -= 8 if %w[boots helmet chest belt].include?(slot)
    when "survivability"
      score += 35 if %w[helmet chest gloves boots belt ring1 ring2].include?(slot)
    when "clear"
      score += 20 if %w[quiver boots gloves].include?(slot)
    when "mana"
      score += 30 if %w[amulet ring1 ring2 belt].include?(slot)
    end

    score
  end

  def self.slot_reason(slot, general_issues, archetype, focus)
    if %w[ring1 ring2 belt boots gloves helmet chest].include?(slot) &&
       general_issues.any? { |i| i[:message].include?("Elemental resistances are not capped") }
      return "#{slot} is a strong slot for fixing resistances and survivability."
    end

    if %w[ring1 ring2 belt boots gloves helmet chest].include?(slot) &&
       general_issues.any? { |i| i[:message].include?("Life is low") }
      return "#{slot} can help stabilize life while improving overall gear quality."
    end

    return "#{slot} is being prioritized because your current focus is #{focus}." if focus.present?

    case [slot, archetype&.name]
    when ["quiver", "Lightning Bow Deadeye"]
      "Quiver can add meaningful projectile support and improve damage consistency."
    when ["ring1", "Lightning Bow Deadeye"], ["ring2", "Lightning Bow Deadeye"]
      "Ring slot can help patch defenses while still adding useful offensive value."
    else
      "#{slot} is one of the weaker current slots and is worth improving soon."
    end
  end
end