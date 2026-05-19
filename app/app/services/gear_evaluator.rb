class GearEvaluator
  SLOT_ORDER = %w[
    weapon offhand helmet chest gloves boots belt amulet ring1 ring2 quiver
  ].freeze

  def self.call(snapshot, archetype)
    gear = snapshot.gear || {}

    weakest_slots = SLOT_ORDER.filter_map do |slot|
      item = gear[slot] || gear[slot.to_sym]
      next unless item.present?

      score = slot_score(slot, item, archetype)

      {
        slot: slot,
        score: score.round(2),
        item: item,
        target_stats: target_stats_for(slot, archetype)
      }
    end.sort_by { |row| row[:score] }.first(3)

    target_stats_by_slot = weakest_slots.each_with_object({}) do |row, hash|
      hash[row[:slot]] = row[:target_stats]
    end

    {
      weakest_slots: weakest_slots,
      target_stats_by_slot: target_stats_by_slot
    }
  end

  def self.slot_score(slot, item, archetype)
    case slot
    when "weapon"
      weapon_score(item, archetype)
    when "quiver"
      quiver_score(item, archetype)
    when "ring1", "ring2", "amulet"
      jewelry_score(item, archetype)
    when "boots"
      boots_score(item, archetype)
    when "helmet", "chest", "gloves", "belt"
      armour_score(item, archetype)
    else
      generic_score(item, archetype)
    end
  end

  def self.weapon_score(item, archetype)
    score = 0.0
    mods = normalized_mods(item)

    score += item_value(item, "dps_score") / 8.0

    score += 20 if any_mod?(mods, "attack speed")
    score += 20 if any_mod?(mods, "cast speed")
    score += 25 if any_mod?(mods, "lightning")
    score += 20 if any_mod?(mods, "projectile")
    score += 20 if any_mod?(mods, "chaos")
    score += 20 if any_mod?(mods, "poison")
    score += 25 if any_mod?(mods, "minion")

    case archetype&.name
    when "Lightning Bow Deadeye"
      score += 30 if any_mod?(mods, "lightning")
      score += 30 if any_mod?(mods, "projectile")
      score += 25 if any_mod?(mods, "attack speed")
    when "Poison Pathfinder"
      score += 30 if any_mod?(mods, "chaos")
      score += 30 if any_mod?(mods, "poison")
      score += 20 if any_mod?(mods, "attack speed")
    when "Minion Infernalist"
      score += 40 if any_mod?(mods, "minion")
      score += 20 if any_mod?(mods, "spirit")
    end

    score
  end

  def self.quiver_score(item, archetype)
    score = 0.0
    mods = normalized_mods(item)

    score += 20 if any_mod?(mods, "accuracy")
    score += 20 if any_mod?(mods, "attack speed")
    score += 25 if any_mod?(mods, "projectile")
    score += 15 if any_mod?(mods, "life")
    score += 15 if any_mod?(mods, "resist")

    if archetype&.name == "Lightning Bow Deadeye"
      score += 30 if any_mod?(mods, "projectile")
      score += 20 if any_mod?(mods, "lightning")
    end

    score
  end

  def self.jewelry_score(item, archetype)
    score = 0.0
    mods = normalized_mods(item)

    score += 25 if any_mod?(mods, "life")
    score += 25 if any_mod?(mods, "resist")
    score += 15 if any_mod?(mods, "attributes")
    score += 15 if any_mod?(mods, "mana")

    case archetype&.name
    when "Lightning Bow Deadeye"
      score += 20 if any_mod?(mods, "lightning")
      score += 10 if any_mod?(mods, "attack")
    when "Poison Pathfinder"
      score += 20 if any_mod?(mods, "chaos")
      score += 20 if any_mod?(mods, "poison")
    when "Minion Infernalist"
      score += 25 if any_mod?(mods, "minion")
    end

    score
  end

  def self.boots_score(item, _archetype)
    score = 0.0
    mods = normalized_mods(item)

    score += 30 if any_mod?(mods, "movement speed")
    score += 25 if any_mod?(mods, "life")
    score += 25 if any_mod?(mods, "resist")

    score
  end

  def self.armour_score(item, archetype)
    score = 0.0
    mods = normalized_mods(item)

    score += 25 if any_mod?(mods, "life")
    score += 25 if any_mod?(mods, "resist")
    score += 15 if any_mod?(mods, "armour")
    score += 15 if any_mod?(mods, "evasion")
    score += 15 if any_mod?(mods, "energy shield")

    if archetype&.name == "Minion Infernalist"
      score += 20 if any_mod?(mods, "minion")
    end

    score
  end

  def self.generic_score(item, _archetype)
    mods = normalized_mods(item)
    score = 0.0

    score += 20 if any_mod?(mods, "life")
    score += 20 if any_mod?(mods, "resist")

    score
  end

  def self.target_stats_for(slot, archetype)
    base = case slot
    when "weapon"
      ["higher base damage", "build-aligned offensive stats"]
    when "helmet", "chest", "gloves", "boots", "belt"
      ["life", "resistances"]
    when "amulet", "ring1", "ring2"
      ["life", "resistances", "build-aligned offensive stats"]
    when "quiver"
      ["damage scaling", "accuracy", "life or resist support"]
    else
      ["life", "resistances"]
    end

    archetype_specific = case archetype&.name
    when "Lightning Bow Deadeye"
      {
        "weapon" => ["higher bow damage", "lightning damage", "attack speed", "projectile-friendly stats"],
        "quiver" => ["projectile damage", "attack speed", "accuracy", "life or resist support"],
        "gloves" => ["attack speed", "life", "resistances"],
        "ring1" => ["life", "resistances", "lightning damage"],
        "ring2" => ["life", "resistances", "lightning damage"],
        "boots" => ["movement speed", "life", "resistances"]
      }
    when "Minion Infernalist"
      {
        "weapon" => ["minion scaling", "gem or skill scaling support", "defensive value if needed"],
        "helmet" => ["life or ES", "resistances", "minion-friendly stats"],
        "amulet" => ["minion scaling", "life or ES", "resistances"]
      }
    when "Poison Pathfinder"
      {
        "weapon" => ["chaos or poison-friendly damage", "attack speed", "consistency"],
        "gloves" => ["life", "resistances", "chaos or poison support"],
        "ring1" => ["life", "resistances", "chaos or poison scaling"],
        "ring2" => ["life", "resistances", "chaos or poison scaling"]
      }
    else
      {}
    end

    archetype_specific.fetch(slot, base)
  end

  def self.normalized_mods(item)
    Array(item["mods"] || item[:mods]).map { |mod| mod.to_s.downcase }
  end

  def self.any_mod?(mods, text)
    mods.any? { |mod| mod.include?(text) }
  end

  def self.item_value(item, key)
    item[key].to_f || item[key.to_sym].to_f
  rescue
    0.0
  end
end