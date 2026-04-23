class BasicPatchParser
  BUFF_WORDS = %w[increased more improved added buff]
  NERF_WORDS = %w[reduced less decreased removed nerf]
  CHANGE_TYPE_KEYWORDS = %w[added removed buff nerf rework]
  ENTITY_TYPE_KEYWORDS = %w[support skill minion passive unique mechanic]
  TAG_KEYWORDS = %w[lightning fire cold minion bow projectile poison chaos support]

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

    CHANGE_TYPE_KEYWORDS.each do |keyword|
      return keyword if lower.include?(keyword)
    end

    "rework"
  end

  def self.guess_entity_type(line)
    lower = line.downcase

    ENTITY_TYPE_KEYWORDS.each do |keyword|
      return keyword if lower.include?(keyword)
    end

    "mechanic"
  end

  def self.guess_entity_name(line)
    line.split(/ now | has | have | deals | grants | causes |:|-/i).first.to_s.strip.presence || "Unknown"
  end

  def self.guess_tags(line)
    lower = line.downcase
    tags = []

    TAG_KEYWORDS.each do |tag|
      tags << tag if lower.include?(tag)
    end

    tags
  end

  def self.extract_numbers(line)
    {
      values: line.scan(/-?\d+(?:\.\d+)?%?/).uniq
    }
  end
end