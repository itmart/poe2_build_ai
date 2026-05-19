class ArchetypeMatcher
  def self.call(snapshot)
    scored = Archetype.all.map do |archetype|
      {
        archetype: archetype,
        score: score_for(snapshot, archetype)
      }
    end

    scored.max_by { |row| row[:score] }&.dig(:archetype)
  end

  def self.score_breakdown(snapshot, archetype)
    skill_names = extract_skill_names(snapshot.skills)
    skill_blob = skill_names.join(" ").downcase

    class_match = snapshot.class_name.to_s.downcase == archetype.class_name.to_s.downcase ? 3 : 0
    ascendancy_match = snapshot.ascendancy_name.to_s.downcase == archetype.ascendancy_name.to_s.downcase ? 4 : 0
    primary_skill_match = skill_names.any? { |skill| skill.downcase == archetype.primary_skill.to_s.downcase } ? 5 : 0

    offense_matches = tag_match_count(skill_blob, archetype.offense_tags)
    mechanic_matches = tag_match_count(skill_blob, archetype.core_mechanics)

    {
      class_match: class_match,
      ascendancy_match: ascendancy_match,
      primary_skill_match: primary_skill_match,
      offense_matches: offense_matches,
      mechanic_matches: mechanic_matches
    }
  end

  def self.score_for(snapshot, archetype)
    breakdown = score_breakdown(snapshot, archetype)

    breakdown[:class_match] +
      breakdown[:ascendancy_match] +
      breakdown[:primary_skill_match] +
      breakdown[:offense_matches] +
      breakdown[:mechanic_matches]
  end

  def self.tag_match_count(skill_blob, tags)
    Array(tags).map(&:to_s).sum do |tag|
      normalized = tag.downcase.gsub("_", " ")
      skill_blob.include?(normalized) ? 1 : 0
    end
  end

  def self.extract_skill_names(skills)
    case skills
    when Hash
      skills.values.flatten.compact.map(&:to_s)
    when Array
      skills.map(&:to_s)
    else
      []
    end
  end
end