# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Archetype.find_or_create_by!(name: "Lightning Bow Deadeye") do |a|
  a.class_name = "Ranger"
  a.ascendancy_name = "Deadeye"
  a.primary_skill = "Lightning Arrow"
  a.offense_tags = %w[bow projectile lightning crit]
  a.defense_tags = %w[evasion mobility ranged]
  a.core_mechanics = %w[shock projectile_scaling attack_speed]
  a.leveling_notes = "Prioritize weapon upgrades and keep elemental resistances healthy."
  a.failure_modes = "Weak bow, low flat damage, poor single target, low defenses."
end

Archetype.find_or_create_by!(name: "Minion Infernalist") do |a|
  a.class_name = "Witch"
  a.ascendancy_name = "Infernalist"
  a.primary_skill = "Summon Raging Spirits"
  a.offense_tags = %w[minion fire summon]
  a.defense_tags = %w[es ranged]
  a.core_mechanics = %w[minion_scaling spirit_generation]
  a.leveling_notes = "Keep minion gem levels and support links on pace."
  a.failure_modes = "Weak minion levels, poor links, low survivability."
end

Archetype.find_or_create_by!(name: "Poison Pathfinder") do |a|
  a.class_name = "Ranger"
  a.ascendancy_name = "Pathfinder"
  a.primary_skill = "Poisonous Concoction"
  a.offense_tags = %w[poison chaos projectile]
  a.defense_tags = %w[evasion recovery]
  a.core_mechanics = %w[poison_scaling flask_value]
  a.leveling_notes = "Focus on poison scaling, consistency, and defensive upkeep."
  a.failure_modes = "Poor poison scaling, weak flask value, undercapped resists."
end