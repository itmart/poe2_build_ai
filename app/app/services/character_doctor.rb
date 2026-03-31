class CharacterDoctor
  def self.call(snapshot)
    issues = []
    recommendations = []

    defenses = snapshot.defenses || {}
    gear = snapshot.gear || {}
    level = snapshot.level.to_i

    fire_res = defenses["fire_res"].to_i
    cold_res = defenses["cold_res"].to_i
    lightning_res = defenses["lightning_res"].to_i
    life = defenses["life"].to_i

    if [fire_res, cold_res, lightning_res].min < 75
      issues << "Elemental resistances are not capped."
      recommendations << "Replace rings, boots, gloves, or belt with rares that add missing resistances."
    end

    if level >= 30 && life > 0 && life < (level * 20)
      issues << "Life is low for your current level."
      recommendations << "Take nearby efficient life nodes and replace weak rare gear with life + resist pieces."
    end

    weapon = gear["weapon"] || {}
    weapon_score = weapon["dps_score"].to_i

    if weapon_score > 0 && weapon_score < (level * 3)
      issues << "Weapon looks weak for your level."
      recommendations << "Upgrade your weapon first. Prioritize higher base damage and stats matching your main skill."
    end

    {
      issues: issues.uniq,
      recommendations: recommendations.uniq
    }
  end
end