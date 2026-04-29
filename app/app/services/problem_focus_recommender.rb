class ProblemFocusRecommender
  def self.call(snapshot, archetype, gear_analysis)
    focus = extract_focus(snapshot)
    return [] if focus.blank?

    case focus
    when "damage"
      damage_recommendations(archetype, gear_analysis)
    when "survivability"
      survivability_recommendations(archetype, gear_analysis)
    when "bossing"
      bossing_recommendations(archetype, gear_analysis)
    when "clear"
      clear_recommendations(archetype, gear_analysis)
    when "mana"
      mana_recommendations(archetype, gear_analysis)
    else
      []
    end
  end

  def self.extract_focus(snapshot)
    constraints = snapshot.constraints || {}
    constraints["problem_focus"].to_s.downcase.presence
  end

  def self.damage_recommendations(archetype, gear_analysis)
    recs = []
    weakest = gear_analysis[:weakest_slots].find { |slot| slot[:slot] == "weapon" }

    recs << "Your priority should be increasing damage output first." if archetype.present?
    recs << "Weapon is usually the highest-value damage upgrade and should be prioritized next." if weakest

    case archetype&.name
    when "Lightning Bow Deadeye"
      recs << "Prioritize stronger bow base damage, lightning scaling, attack speed, and projectile-friendly stats."
      recs << "Make sure your quiver and rings are helping offense rather than only patching minor stats."
    when "Minion Infernalist"
      recs << "Prioritize minion gem progression, support links, and minion-friendly scaling over marginal defensive luxury."
      recs << "A minion build with weak gem progression often feels like a damage problem even when gear is acceptable."
    when "Poison Pathfinder"
      recs << "Prioritize poison/chaos scaling and consistency rather than generic hit damage."
      recs << "Make sure your gear and setup are aligned with poison scaling instead of split priorities."
    else
      recs << "Focus on your main damage slot first, then supporting slots that amplify your core scaling."
    end

    recs
  end

  def self.survivability_recommendations(archetype, gear_analysis)
    recs = []
    defensive_slots = gear_analysis[:weakest_slots].select { |slot| %w[helmet chest gloves boots belt ring1 ring2].include?(slot[:slot]) }

    recs << "Your priority should be stabilizing defenses before chasing more damage."
    recs << "Focus on life and resistance upgrades in your weakest defensive slots first." if defensive_slots.any?

    case archetype&.name
    when "Lightning Bow Deadeye"
      recs << "Bow builds often feel worse when defenses are neglected, so fix life and resistance coverage before greedier upgrades."
    when "Minion Infernalist"
      recs << "Even if minions do the fighting, your own survivability still needs to stay on pace."
    when "Poison Pathfinder"
      recs << "Poison progression feels much smoother when survivability is stable enough to keep uptime high."
    end

    recs
  end

  def self.bossing_recommendations(archetype, gear_analysis)
    recs = []
    recs << "Bossing issues usually point to weak single-target scaling, weak weapon progression, or an under-supported main skill."

    case archetype&.name
    when "Lightning Bow Deadeye"
      recs << "Look for better single-target support through weapon quality, projectile scaling, and stronger supporting gear."
      recs << "Do not let utility or clear-focused choices crowd out your boss damage setup."
    when "Minion Infernalist"
      recs << "Bossing on minion builds often improves the most from gem progression and better support links."
    when "Poison Pathfinder"
      recs << "Bossing improves when poison uptime and consistency are stable, not just peak hit values."
    else
      recs << "Focus on upgrades that improve sustained damage against tougher targets."
    end

    weapon_slot = gear_analysis[:weakest_slots].find { |slot| slot[:slot] == "weapon" }
    recs << "Your weapon still looks like one of the best next bossing upgrades." if weapon_slot

    recs
  end

  def self.clear_recommendations(archetype, gear_analysis)
    recs = []
    recs << "Clear issues usually come from weak damage pacing, poor mobility, or a setup that is too single-target focused."

    case archetype&.name
    when "Lightning Bow Deadeye"
      recs << "Bow clear usually benefits from better projectile scaling, faster attacks, and smoother movement between packs."
    when "Minion Infernalist"
      recs << "Minion clear often feels slow when summon pacing or support setup lags behind."
    when "Poison Pathfinder"
      recs << "Poison clear improves when application is consistent and movement/tempo stays smooth."
    else
      recs << "Focus on smoother pack-to-pack pacing rather than only peak damage."
    end

    boots_slot = gear_analysis[:weakest_slots].find { |slot| slot[:slot] == "boots" }
    recs << "Boots may be worth revisiting if movement and overall tempo feel sluggish." if boots_slot

    recs
  end

  def self.mana_recommendations(archetype, _gear_analysis)
    recs = []
    recs << "Mana problems usually come from support costs, poor sustain, or a setup that came online faster than the resource layer supporting it."

    case archetype&.name
    when "Lightning Bow Deadeye"
      recs << "Check whether your supports are pushing costs too high for your current progression."
    when "Minion Infernalist"
      recs << "Make sure your utility and summon setup are not overloading your current mana or spirit economy."
    when "Poison Pathfinder"
      recs << "Mana issues often smooth out when the setup is tightened around the core poison plan instead of carrying extra inefficiencies."
    end

    recs << "Review your skill links and remove low-value cost multipliers before making expensive gear changes."
    recs
  end
end