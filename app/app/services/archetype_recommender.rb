class ArchetypeRecommender
  def self.call
    Archetype.all.map do |archetype|
      {
        name: archetype.name,
        class_name: archetype.class_name,
        ascendancy_name: archetype.ascendancy_name,
        primary_skill: archetype.primary_skill,
        summary: "#{archetype.name} scales with #{archetype.offense_tags.join(', ')}"
      }
    end
  end
end