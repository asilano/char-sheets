require_relative './character'

class Exalted < Character
  ALL_ABILITIES = %w[
    Archery
    Athletics
    Awareness
    Brawl
    Bureaucracy
    Craft
    Dodge
    Integrity
    Investigation
    Larceny
    Linguistics
    Lore
    Martial\ Arts
    Medicine
    Melee
    Occult
    Performance
    Presence
    Resistance
    Ride
    Sail
    Socialise
    Stealth
    Survival
    Thrown
    War
  ].freeze

  stat_block :attributes do
    stat :strength, :integer
    stat :dexterity, :integer
    stat :stamina, :integer
    stat :charisma, :integer
    stat :manipulation, :integer
    stat :appearance, :integer
    stat :perception, :integer
    stat :intelligence, :integer
    stat :wits, :integer
  end

  stat_block :abilities do
    Exalted::ALL_ABILITIES.each do |abil|
      stat abil.parameterize(separator: '_').to_sym, :integer
    end
  end
end
