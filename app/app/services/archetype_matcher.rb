class ArchetypeMatcher
  def self.call(snapshot)
    Archetype.all.max_by do |archetype|
      score_for(snapshot, archetype)
    end
  end

  def self.score_for(snapshot, archetype)
    score = 0

    score += 3 if snapshot.class_name.to_s.downcase == archetype.class_name.to_s.downcase
    score += 4 if snapshot.ascendancy_name.to_s.downcase == archetype.ascendancy_name.to_s.downcase

    skill_names = extract_skill_names(snapshot.skills)

    score += 5 if skill_names.any? { |skill| skill.downcase == archetype.primary_skill.to_s.downcase }

    offense_tags = Array(archetype.offense_tags).map(&:downcase)
    core_mechanics = Array(archetype.core_mechanics).map(&:downcase)

    skill_blob = skill_names.join(" ").downcase

    offense_tags.each do |tag|
      score += 1 if skill_blob.include?(tag)
    end

    core_mechanics.each do |tag|
      score += 1 if skill_blob.include?(tag.gsub("_", " "))
    end

    score
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