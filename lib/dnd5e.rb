require_relative './character'
require 'byebug'

class DnD5e < Character
  RACES = [
    'Kenku',
    'Dragonborn',
    {'Dwarf' => ['Hill', 'Mountain']},
    {'Elf' => ['Dark', 'High', 'Wood']},
    {'Gnome' => ['Forest', 'Rock']},
    'Half-Elf',
    {'Halfling' => ['Lightfoot', 'Stout']},
    'Half-Orc',
    'Human',
    'Tiefling',
  ]

  CHARACTER_CLASSES = %w[
    Barbarian
    Bard
    Cleric
    Druid
    Fighter
    Monk
    Paladin
    Ranger
    Rogue
    Sorcerer
    Warlock
    Wizard
  ]

  stat :background, :string
  stat :base_speed, :integer
  stat :alignment, :string, one_of: [
    'Lawful Good',
    'Lawful Neutral',
    'Lawful Evil',
    'Neutral Good',
    'True Neutral',
    'Neutral Evil',
    'Chaotic Good',
    'Chaotic Neutral',
    'Chaotic Evil'
  ]
  stat :race, :string, one_of: RACES.map { |r| r.is_a?(Hash) ? r.keys.first : r }
  stat :subrace, :string
  stat :character_class, :string, one_of: CHARACTER_CLASSES
  stat :level, :integer
  stat :inspiration, :boolean
  derived_stat(:proficiency_bonus) do
    case level
    when 1..4
      2
    when 5..8
      3
    when 9..12
      4
    when 13..16
      5
    when 17..20
      6
    end
  end
  stat :personality_traits, :string
  stat :ideals, :string
  stat :bonds, :string
  stat :flaws, :string

  stat_block :attributes do
    stat :strength, :integer
    stat :dexterity, :integer
    stat :constitution, :integer
    stat :intelligence, :integer
    stat :wisdom, :integer
    stat :charisma, :integer

    derived_stat(:str_mod) { (strength - 10) / 2 }
    derived_stat(:dex_mod) { (dexterity - 10) / 2 }
    derived_stat(:con_mod) { (constitution - 10) / 2 }
    derived_stat(:int_mod) { (intelligence - 10) / 2 }
    derived_stat(:wis_mod) { (wisdom - 10) / 2 }
    derived_stat(:cha_mod) { (charisma - 10) / 2 }
  end

  derived_stat(:initiative) { attributes.dex_mod }

  stat_block :saving_throws do
    derived_stat(:strength) { character.mod_with_proficiency(:str_mod, :str_save) }
    derived_stat(:dexterity) { character.mod_with_proficiency(:dex_mod, :dex_save) }
    derived_stat(:constitution) { character.mod_with_proficiency(:con_mod, :con_save) }
    derived_stat(:intelligence) { character.mod_with_proficiency(:int_mod, :int_save) }
    derived_stat(:wisdom) { character.mod_with_proficiency(:wis_mod, :wis_save) }
    derived_stat(:charisma) { character.mod_with_proficiency(:cha_mod, :cha_save) }
  end

  stat_block :abilities do
    derived_stat(:acrobatics) { character.mod_with_proficiency(:dex_mod, :acrobatics) }
    derived_stat(:animal_handling) { character.mod_with_proficiency(:wis_mod, :animal_handling) }
    derived_stat(:arcana) { character.mod_with_proficiency(:int_mod, :arcana) }
    derived_stat(:athletics) { character.mod_with_proficiency(:str_mod, :athletics) }
    derived_stat(:deception) { character.mod_with_proficiency(:cha_mod, :deception) }
    derived_stat(:history) { character.mod_with_proficiency(:int_mod, :history) }
    derived_stat(:insight) { character.mod_with_proficiency(:wis_mod, :insight) }
    derived_stat(:intimidation) { character.mod_with_proficiency(:cha_mod, :intimidation) }
    derived_stat(:investigation) { character.mod_with_proficiency(:int_mod, :investigation) }
    derived_stat(:medicine) { character.mod_with_proficiency(:wis_mod, :medicine) }
    derived_stat(:nature) { character.mod_with_proficiency(:int_mod, :nature) }
    derived_stat(:perception) { character.mod_with_proficiency(:wis_mod, :perception) }
    derived_stat(:performance) { character.mod_with_proficiency(:cha_mod, :performance) }
    derived_stat(:persuasion) { character.mod_with_proficiency(:cha_mod, :persuasion) }
    derived_stat(:religion) { character.mod_with_proficiency(:int_mod, :religion) }
    derived_stat(:sleight_of_hand) { character.mod_with_proficiency(:dex_mod, :sleight_of_hand) }
    derived_stat(:stealth) { character.mod_with_proficiency(:dex_mod, :stealth) }
    derived_stat(:survival) { character.mod_with_proficiency(:wis_mod, :survival) }
  end

  stat :proficiencies, :array
  derived_stat(:passive_perception) { abilities.perception + 10 }
  derived_stat(:hit_die) do
    case character_class
    when 'Barbarian'
      12
    when 'Fighter', 'Paladin', 'Ranger'
      10
    when 'Bard', 'Cleric', 'Druid', 'Monk', 'Rogue', 'Warlock'
      8
    when 'Sorcerer', 'Wizard'
      6
    end
  end
  derived_stat(:hit_point_maximum) do
    maximum = hit_die + (level - 1) * (1 + hit_die / 2) + (level * attributes.con_mod)
    maximum += level if race == 'Dwarf' && subrace == 'Hill'
  end

  def mod_with_proficiency(mod, skill)
    val = attributes.send(mod)
    val += proficiency_bonus if proficiencies.include? skill
    val
  end

  generate do
    choose :race, :subrace, from: RACES
    # Determine base speed
    @base_speed = case race
                  when 'Dragonborn', 'Half-Elf', 'Half-Orc', 'Human', 'Tiefling'
                    30
                  when 'Dwarf', 'Gnome', 'Halfling'
                    25
                  when 'Elf'
                    case subrace
                    when 'Wood'
                      35
                    else
                      30
                    end
                  end
    case race
    when 'Elf'
      @proficiencies << :perception
    when 'Half-Elf'
      #LOL
    end

    choose :character_class, from: CHARACTER_CLASSES
  end
end
