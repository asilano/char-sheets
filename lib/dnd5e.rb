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

  ABILITIES = %i[
    strength
    dexterity
    constitution
    charisma
    intelligence
    wisdom
  ]

  SKILLS = %i[
    acrobatics
    animal_handling
    arcana
    athletics
    deception
    history
    insight
    intimidation
    investigation
    medicine
    nature
    perception
    performance
    persuasion
    religion
    sleight_of_hand
    stealth
    survival
  ]

  LANGUAGES = %w[
    Common
    Dwarvish
    Elvish
    Giant
    Gnomish
    Goblin
    Halfling
    Orc
    Abyssal
    Celestial
    Draconic
    Deep\ Speech
    Infernal
    Primordial
    Sylvan
    Undercommon
  ]

  ALIGNMENTS = [
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

  BACKGROUNDS = %w[
    Acolyte
    Charlatan
    Criminal
    Entertainer
    Folk\ Hero
    Guild\ Artisan
    Hermit
    Noble
    Outlander
    Sage
    Sailor
    Soldier
    Urchin
  ]

  stat :background, :string
  stat :base_speed, :integer
  stat :alignment, :string, one_of: ALIGNMENTS
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
  stat :personality_traits, :array
  stat :ideal, :string
  stat :bond, :string
  stat :flaw, :string

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

  stat :languages, :array

  def mod_with_proficiency(mod, skill)
    val = attributes.send(mod)
    val += proficiency_bonus if proficiencies.include? skill
    val
  end

  generate do
    choose :race, :subrace, from: RACES
    # Determine base speed
    @base_speed = case race
                  when 'Dragonborn', 'Half-Elf', 'Half-Orc', 'Human', 'Kenku', 'Tiefling'
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
    @languages << 'Common'
    case race
    when 'Dragonborn'
      @languages << 'Draconic'
      race_ability_bonuses = { strength: 2,
                               charisma: 1 }
    when 'Dwarf'
      @languages << 'Dwarvish'
      race_ability_bonuses = { constitution: 2 }
      case subrace
      when 'Hill'
        race_ability_bonuses[:wisdom] = 1
      when 'Mountain'
        race_ability_bonuses[:strength] = 2
      end
    when 'Elf'
      @proficiencies << :perception
      @languages << 'Elvish'
      race_ability_bonuses = { dexterity: 2 }
      case subrace
      when 'Dark'
        race_ability_bonuses[:charisma] = 1
      when 'High'
        puts 'Please enter a language to be proficient in'
        language = choose(from: LANGUAGES - @languages)
        @languages << language
        race_ability_bonuses[:intelligence] = 1
      when 'Wood'
        race_ability_bonuses[:wisdom] = 1
      end
    when 'Gnome'
      @languages << 'Gnomish'
      race_ability_bonuses = { intelligence: 2 }
      case subrace
      when 'Forest'
        race_ability_bonuses[:dexterity] = 1
      when 'Rock'
        race_ability_bonuses[:constitution] = 1
      end
    when 'Half-Elf'
      puts 'Please enter two skill proficiencies'
      first_proficiency = choose(from: SKILLS).to_sym
      second_proficiency = choose(from: SKILLS - [first_proficiency]).to_sym
      @proficiencies += [first_proficiency, second_proficiency]

      puts 'Please enter a language to be proficient in'
      language = choose(from: LANGUAGES - @languages)
      @languages << language
      race_ability_bonuses = { charisma: 2 }
      puts 'Please enter two abilities to get +1 (Your charisma is already +2)'
      first_ability = choose(from: ABILITIES - [:charisma]).to_sym
      second_ability = choose(from: ABILITIES - [first_ability, :charisma]).to_sym
      race_ability_bonuses[first_ability] = 1
      race_ability_bonuses[second_ability] = 1
    when 'Half-Orc'
      @proficiencies << :intimidation
      @languages << 'Orc'
      race_ability_bonuses = { strength: 2,
                               constitution: 1 }
    when 'Halfling'
      @languages << 'Halfling'
      race_ability_bonuses = { dexterity: 2 }
      case subrace
      when 'Lightfoot'
        race_ability_bonuses[:charisma] = 1
      when 'Stout'
        race_ability_bonuses[:constitution] = 1
      end
    when 'Human'
      puts 'Please enter a language to be proficient in'
      language = choose(from: LANGUAGES - @languages)
      @languages << language
      race_ability_bonuses = ABILITIES.inject({}) { |h, a| h[a] = 1; h }
    when 'Kenku'
      @languages << 'Auran'
      kenku_proficiencies = %i[
        acrobatics
        deception
        sleight_of_hand
        stealth
      ]
      puts 'Please enter two skill proficiencies'
      first_proficiency = choose(from: kenku_proficiencies - @proficiencies).to_sym
      @proficiencies << first_proficiency
      second_proficiency = choose(from: kenku_proficiencies - @proficiencies).to_sym
      @proficiencies << second_proficiency
      race_ability_bonuses = { dexterity: 2, wisdom: 1 }
    when 'Tiefling'
      @languages << 'Infernal'
      race_ability_bonuses = { intelligence: 1,
                               charisma: 2 }
    end

    choose :character_class, from: CHARACTER_CLASSES

    case character_class
    when 'Barbarian'
      @proficiencies += [:str_save, :con_save]
      puts 'Please enter two skill proficiencies'
      barbarian_proficiencies = %i[
        animal_handling
        athletics
        intimidation
        nature
        perception
        survival
      ]
      first_proficiency = choose(from: barbarian_proficiencies - @proficiencies).to_sym
      @proficiencies << first_proficiency
      second_proficiency = choose(from: barbarian_proficiencies - @proficiencies).to_sym
      @proficiencies << second_proficiency
    when 'Bard'
      @proficiencies += [:dex_save, :cha_save]
      puts 'Please enter three skill proficiencies'
      first_proficiency = choose(from: SKILLS).to_sym
      second_proficiency = choose(from: SKILLS - [first_proficiency]).to_sym
      third_proficiency = choose(from: SKILLS - [first_proficiency] - [second_proficiency]).to_sym
      @proficiencies += [first_proficiency, second_proficiency, third_proficiency]
    when 'Cleric'
      @proficiencies += [:wis_save, :cha_save]
      puts 'Please enter two skill proficiencies'
      cleric_proficiencies = %i[
        history
        insight
        medicine
        persuasion
        religion
      ]
      first_proficiency = choose(from: cleric_proficiencies - @proficiencies).to_sym
      @proficiencies << first_proficiency
      second_proficiency = choose(from: cleric_proficiencies - @proficiencies).to_sym
      @proficiencies << second_proficiency
      # TODO Divine Domain goes here!
    when 'Druid'
      @proficiencies += [:int_save, :wis_save]
      puts 'Please enter two skill proficiencies'
      druid_proficiencies = %i[
        arcana
        animal_handling
        insight
        medicine
        nature
        perception
        religion
        survival
      ]
      first_proficiency = choose(from: druid_proficiencies - @proficiencies).to_sym
      @proficiencies << first_proficiency
      second_proficiency = choose(from: druid_proficiencies - @proficiencies).to_sym
      @proficiencies << second_proficiency
      @languages << 'Druidic'
    when 'Fighter'
      @proficiencies += [:str_save, :con_save]
      puts 'Please enter two skill proficiencies'
      fighter_proficiencies = %i[
        acrobatics
        animal_handling
        athletics
        history
        insight
        intimidation
        perception
        survival
      ]
      first_proficiency = choose(from: fighter_proficiencies - @proficiencies).to_sym
      @proficiencies << first_proficiency
      second_proficiency = choose(from: fighter_proficiencies - @proficiencies).to_sym
      @proficiencies << second_proficiency
      # TODO Fighting style
    when 'Monk'
      @proficiencies += [:str_save, :dex_save]
      puts 'Please enter two skill proficiencies'
      monk_proficiencies = %i[
        acrobatics
        athletics
        history
        insight
        religion
        stealth
      ]
      first_proficiency = choose(from: monk_proficiencies - @proficiencies).to_sym
      @proficiencies << first_proficiency
      second_proficiency = choose(from: monk_proficiencies - @proficiencies).to_sym
      @proficiencies << second_proficiency
    when 'Paladin'
      @proficiencies += [:wis_save, :cha_save]
      puts 'Please enter two skill proficiencies'
      paladin_proficiencies = %i[
        athletics
        insight
        intimidation
        medicine
        persuasion
        religion
      ]
      first_proficiency = choose(from: paladin_proficiencies - @proficiencies).to_sym
      @proficiencies << first_proficiency
      second_proficiency = choose(from: paladin_proficiencies - @proficiencies).to_sym
      @proficiencies << second_proficiency
    when 'Ranger'
      @proficiencies += [:str_save, :dex_save]
      puts 'Please enter three skill proficiencies'
      ranger_proficiencies = %i[
        animal_handling
        athletics
        insight
        investigation
        nature
        perception
        stealth
        survival
      ]
      first_proficiency = choose(from: ranger_proficiencies - @proficiencies).to_sym
      @proficiencies << first_proficiency
      second_proficiency = choose(from: ranger_proficiencies - @proficiencies).to_sym
      @proficiencies << second_proficiency
      third_proficiency = choose(from: ranger_proficiencies - @proficiencies).to_sym
      @proficiencies << third_proficiency
      # TODO Choose favoured enemy
    when 'Rogue'
      @proficiencies += [:dex_save, :int_save]
      puts 'Please enter four skill proficiencies'
      rogue_proficiencies = %i[
        acrobatics
        athletics
        deception
        insight
        intimidation
        investigation
        perception
        performance
        persuasion
        sleight_of_hand
        stealth
      ]
      first_proficiency = choose(from: rogue_proficiencies - @proficiencies).to_sym
      @proficiencies << first_proficiency
      second_proficiency = choose(from: rogue_proficiencies - @proficiencies).to_sym
      @proficiencies << second_proficiency
      third_proficiency = choose(from: rogue_proficiencies - @proficiencies).to_sym
      @proficiencies << third_proficiency
      fourth_proficiency = choose(from: rogue_proficiencies - @proficiencies).to_sym
      @proficiencies << fourth_proficiency
      @languages << "Theives' Cant"
      # TODO Choose expertise
    when 'Sorcerer'
      @proficiencies += [:con_save, :cha_save]
      puts 'Please enter two skill proficiencies'
      sorcerer_proficiencies = %i[
        arcana
        deception
        insight
        intimidation
        persuasion
        religion
      ]
      first_proficiency = choose(from: sorcerer_proficiencies - @proficiencies).to_sym
      @proficiencies << first_proficiency
      second_proficiency = choose(from: sorcerer_proficiencies - @proficiencies).to_sym
      @proficiencies << second_proficiency
      # TODO Choose sorcerous origin
    when 'Warlock'
      @proficiencies += [:wis_save, :cha_save]
      puts 'Please enter two skill proficiencies'
      warlock_proficiencies = %i[
        arcana
        deception
        history
        intimidation
        investigation
        nature
        religion
      ]
      first_proficiency = choose(from: warlock_proficiencies - @proficiencies).to_sym
      @proficiencies << first_proficiency
      second_proficiency = choose(from: warlock_proficiencies - @proficiencies).to_sym
      @proficiencies << second_proficiency
      # TODO Choose otherworldly patron
    when 'Wizard'
      @proficiencies += [:int_save, :wis_save]
      puts 'Please enter two skill proficiencies'
      wizard_proficiencies = %i[
        arcana
        history
        insight
        investigation
        medicine
        religion
      ]
      first_proficiency = choose(from: wizard_proficiencies - @proficiencies).to_sym
      @proficiencies << first_proficiency
      second_proficiency = choose(from: wizard_proficiencies - @proficiencies).to_sym
      @proficiencies << second_proficiency
    end

    # ABILITY SCORES
    ability_scores = [15, 14, 13, 12, 10, 8]
    ABILITIES.each do |ability|
      puts "Please enter a value from the list for #{ability}"
      if race_ability_bonuses.key?(ability)
        puts "Due to your character cheeses so far, you have a +#{race_ability_bonuses[ability]} bonus to this ability"
      end
      choice = choose(from: ability_scores).to_i
      attributes.send("#{ability}=", choice + (race_ability_bonuses[ability] || 0))
      ability_scores.delete(choice)
    end

    enter :character_name

    choose :alignment, from: ALIGNMENTS

    choose :background, from: BACKGROUNDS
    case @background
    #TODO: Add background feature
    when 'Acolyte'
      @proficiencies << :insight
      @proficiencies << :religion
      puts 'Please enter two languages to be proficient in'
      2.times { @languages << choose(from: LANGUAGES - @languages) }
      personality_options = [
        %q{I idolize a parlicular hero of my faith, and constantly refer to that person's deeds and example.},
        %q{I can find common ground between the fiercest enemies, empathizing with them and always working toward peace.},
        %q{I see omens in every event and action. The gods try to speak to us; we just need to listen.},
        %q{Nothing can shake my optimistic attitude.},
        %q{I quote (or misquote) sacred texts and proverbs in almost every situation.},
        %q{I am tolerant (or intolerant) of other faiths and respect (or condemn) the worship of other gods.},
        %q{I've enjoyed fine food, drink, and high society among my temple's elite. Rough living grates on me.},
        %q{I've spent so long in the temple that I have little practical experience dealing with people in the outside world.}
      ]
      ideal_options = [
        %q{Tradition. The ancient traditions of worship and sacrifice must be preserved and upheld. (Lawful)},
        %q{Charity. I always try to help those in need, no matter what the personal cost. (Good)},
        %q{Change. We must help bring about the changes the gods are constantly working in the world. (Chaotic)},
        %q{Power. I hope to one day rise to the top of my faith's religious hierarchy. (Lawful)},
        %q{Faith. I trust that my deity will guide my actions. I have faith that if I work hard, things will go well. (Lawful)},
        %q{Aspiration. I seek to prove myself worthy of my god's favor by matching my actions against his or her teachings. (Any)}
      ]
      bond_options = [
        %q{I would die to recover an ancient relic of my faith that was lost long ago.},
        %q{I will someday get revenge on the corrupt temple hierarchy which branded me a heretic.},
        %q{I owe my life to the priest who took me in when my parents died.},
        %q{Everything I do is for the common people.},
        %q{I will do anything to protect the temple in which I served.},
        %q{I seek to preserve a sacred text that my enemies consider heretical and seek to destroy.}
      ]
      flaw_options = [
        %q{I judge others harshly, and myself even more severely.},
        %q{I put too much trust in those who wield power within my temple's hierarchy.},
        %q{My piety sometimes leads me to blindly trust those that profess faith in my god.},
        %q{I am inflexible in my thinking.},
        %q{I am suspicious of strangers and expect the worst of them.},
        %q{Once I pick a goal, I become obsessed with it to the detriment of everything else in my life.}
      ]
    end

    puts 'Please select two personality traits for your character'
    2.times do
      @personality_traits <<
        choose_by_number(from: personality_options - @personality_traits, allow_random: true, allow_free: true)
    end

    choose_by_number(:ideal, from: ideal_options, allow_random: true, allow_free: true)
    choose_by_number(:bond, from: bond_options, allow_random: true, allow_free: true)
    choose_by_number(:flaw, from: flaw_options, allow_random: true, allow_free: true)
  end
end
