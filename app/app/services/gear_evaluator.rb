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
        score: score,
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
    stats_blob = item.to_s.downcase
    score = 0.0

    score += 5 if stats_blob.include?("life")
    score += 3 if stats_blob.include?("res")
    score += 2 if stats_blob.include?("attack speed")
    score += 2 if stats_blob.include?("cast speed")
    score += 2 if stats_blob.include?("minion")
    score += 2 if stats_blob.include?("chaos")
    score += 2 if stats_blob.include?("lightning")
    score += 2 if stats_blob.include?("projectile")

    if slot == "weapon"
      score += item["dps_score"].to_i / 20.0 if item.is_a?(Hash)
    end

    if archetype&.name == "Lightning Bow Deadeye"
      score += 3 if stats_blob.include?("lightning")
      score += 3 if stats_blob.include?("projectile")
      score += 2 if stats_blob.include?("attack speed")
    elsif archetype&.name == "Minion Infernalist"
      score += 4 if stats_blob.include?("minion")
      score += 2 if stats_blob.include?("spirit")
    elsif archetype&.name == "Poison Pathfinder"
      score += 3 if stats_blob.include?("chaos")
      score += 3 if stats_blob.include?("poison")
    end

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
        "ring2" => ["life", "resistances", "lightning damage"]
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
end