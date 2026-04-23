class BasicPatchParser
  BUFF_WORDS = %w[increased more improved added buff]
  NERF_WORDS = %w[reduced less decreased removed nerf]

  def self.call(text)
    text.to_s.lines.filter_map do |line|
      clean = line.strip
      next if clean.blank?
      next unless balance_relevant?(clean)

      {
        entity_name: guess_entity_name(clean),
        entity_type: guess_entity_type(clean),
        change_type: guess_change_type(clean),
        before_text: nil,
        after_text: clean,
        summary: clean,
        tags: guess_tags(clean),
        numeric_data: extract_numbers(clean),
        confidence: 0.35
      }
    end
  end

  def self.balance_relevant?(line)
    lower = line.downcase
    (BUFF_WORDS + NERF_WORDS).any? { |word| lower.include?(word) }
  end

  def self.guess_change_type(line)
    lower = line.downcase

    return "added" if lower.include?("added")
    return "removed" if lower.include?("removed")
    return "buff" if BUFF_WORDS.any? { |word| lower.include?(word) }
    return "nerf" if NERF_WORDS.any? { |word| lower.include?(word) }

    "rework"
  end

  def self.guess_entity_type(line)
    lower = line.downcase

    return "support" if lower.include?("support")
    return "skill" if lower.include?("skill") || lower.include?("arrow") || lower.include?("spell")
    return "minion" if lower.include?("minion")
    return "passive" if lower.include?("passive")
    return "unique" if lower.include?("unique")

    "mechanic"
  end

  def self.guess_entity_name(line)
    line.split(/ now | has | have | deals | grants | causes |:|-/i).first.to_s.strip.presence || "Unknown"
  end

  def self.guess_tags(line)
    lower = line.downcase
    tags = []

    tags << "lightning" if lower.include?("lightning")
    tags << "fire" if lower.include?("fire")
    tags << "cold" if lower.include?("cold")
    tags << "minion" if lower.include?("minion")
    tags << "bow" if lower.include?("bow") || lower.include?("arrow")
    tags << "projectile" if lower.include?("projectile") || lower.include?("arrow")
    tags << "poison" if lower.include?("poison")
    tags << "chaos" if lower.include?("chaos")
    tags << "support" if lower.include?("support")

    tags
  end

  def self.extract_numbers(line)
    {
      values: line.scan(/-?\d+(?:\.\d+)?%?/).uniq
    }
  end
end