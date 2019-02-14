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
      puts 'Please enter two languages to be proficient in.'
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
    when 'Charlatan'
      @proficiencies << :deception
      @proficiencies << :sleight_of_hand
      personality_options = [
        %q{I fall in and out of love easily, and am always pursuing someone.},
        %q{I have a joke for every occasion, especially occasions where humor is inappropriate.},
        %q{Flattery is my preferred trick for getting what I want.},
        %q{I'm a born gambler who can't resist taking a risk for a potential payoff.},
        %q{I lie about almost everything, even when there's no good reason to.},
        %q{Sarcasm and insults are my weapons of choice.},
        %q{I keep multiple holy symbols on me and invoke whatever deity might come in useful at any given moment.},
        %q{I pocket anything I see that might have some value.}
      ]
      ideal_options = [
        %q{Independence. I am a free spirit - no-one tells me what to do. (Chaotic)},
        %q{Fairness. I never target people who can't afford to lose a few coins. (Lawful)},
        %q{Charity. I distribute the money I acquire to the people who really need it. (Good)},
        %q{Creativity. I never run the same con twice. (Chaotic)},
        %q{Friendship. Material goods come and go. Bonds of friendship last forever. (Good)},
        %q{Aspiration. I'm determined to make something of myself. (Any)}
      ]
      bond_options = [
        %q{I fleeced the wrong person and must work to ensure that this individual never crosses paths with me or those I care about.},
        %q{I owe everything to my mentor - a horrible person who's probably rotting in jail somewhere.},
        %q{Somewhere out there, I have a child who doesn't know me. I'm making the world better for him or her.},
        %q{I come frem a noble family, and one day I'll reclaim my lands and title from those who stole them from me.},
        %q{A powerful person killed someone I love. Some day soon, I'll have my revenge.},
        %q{I swindled and ruined a person who didn't deserve it. I seek to atone for my misdeeds but might never be able to forgive myself.}
      ]
      flaw_options = {
        %q{I can't resist a pretty face.},
        %q{I'm always in debt. I spend my ill-gotten gains on decadent luxuries faster than I bring them in.},
        %q{I'm convinced that no one could ever fool me the way I fool others.},
        %q{I'm too greedy for my own good. I can't resist taking a risk if there's money involved.},
        %q{I can't resist swindling people who are more powerful than me.},
        %q{I hate to admit it and will hate myself for it, but I'll run and preserve my own hide if the going gets tough.}
      }
    when 'Criminal'
      @proficiencies << :deception
      @proficiencies << :stealth
      personality_options = [
        %q{I always have a plan for what to do when things go wrong.},
        %q{I am always calm, no matter what the situation. I never raise my voice ar let my emotions control me.},
        %q{The first thing I do in a new place is note the locations of everything valuable - or where such things could be hidden.},
        %q{I would rather make a new friend than a new enemy.},
        %q{I am incredibly slow to trust. Those who seem the fairest often have the most to hide.},
        %q{I don't pay attention to the risks in a situation. Never tell me the odds.},
        %q{The best way to get me to do something is to tell me I can't do it.},
        %q{I blow up at the slightest insult.}
      ]
      ideal_options = [
        %q{Honor. I don't steal from others in the trade. (Lawful)},
        %q{Freedom. Chains are meant to be broken, as are those who would forge them. (Chaotic)},
        %q{Charity. I steal from the wealthy so that I can help people in need. (Good)},
        %q{Greed. I will do whatever it takes to become wealthy. (Evil)},
        %q{People. I'm loyal to my friends, not to any ideals, and everyone else can take a trip down the Styx for all I care. (Neutral)},
        %q{Redemption. There's a spark of good in everyone. (Good)}
      ]
      bond_options = [
        %q{I'm trying to pay off an old debt I owe to a generous benefactor.},
        %q{My ill-gotten gains go to support my family.},
        %q{Something important was taken from me, and I aim to steal it back.},
        %q{I will become the greatest thief that ever lived.},
        %q{I'm guilty of a terrible crime. I hope I can redeem myself for it.},
        %q{Someone I loved died because of I mistake I made. That will never happen again.}
      ]
      flaw_options = [
        %q{When I see something valuable, I can't think about anything but how to steal it.},
        %q{When faced with a choice between money and my friends, I usually choose the money.},
        %q{If there's a plan, I'll forget it. If I don't forget it, I'll ignore it.},
        %q{I have a "tell" that reveals when I'm lying.},
        %q{I turn tail and run when things look bad.},
        %q{An innocent person is in prison for a crime that I committed. I'm okay with that.}
      ]
    when 'Entertainer'
      @proficiencies << :acrobatics
      @proficiencies << :performance
      personality_options = [
        %q{I know a story relevant to almost every situation.},
        %q{Whenever I come to a new place, I collect local rumors and spread gossip.},
        %q{I'm a hopeless romantic, always searching for that "special someone."},
        %q{Nobody stays angry at me or around me for long, since I can defuse any amount of tension.},
        %q{I love a good insult, even one directed at me.},
        %q{I get bitter if I'm not the center of attention.},
        %q{I'll settle for nothing less than perfection.},
        %q{I change my mood or my mind as quickly as I change key in a song.}
      ]
      ideal_options = [
        %q{Beauty. When I perform, I make the world better than it was. (Good)},
        %q{Tradition. The stories, legends, and songs of the past must never be forgotten, for they teach us who we are. (Lawful)},
        %q{Creativity. The world is in need of new ideas and bold action. (Chaotic)},
        %q{Greed. I'm only in it for the money and fame. (Evil)},
        %q{People. I like seeing the smiles on people's faces when I perform. That's all that matters. (Neutral)},
        %q{Honesty. Art should reflect the soul; it should come from within and reveal who we really are. (Any)}
      ]
      bond_options = [
        %q{My instrument is my most treasured possession, and it reminds me of someone I love.},
        %q{Someone stole my precious instrument, and someday I'll get it back.},
        %q{I want to be famous, whatever it takes.},
        %q{I idolize a hero of the old tales and measure my deeds against that person's.},
        %q{I will do anything to prove myself superior to my hated rival.},
        %q{I would do anything for the other members of my old troupe.}
      ]
      flaw_options = [
        %q{I'll do anything to win fame and renown.},
        %q{I'm a sucker for a pretty face.},
        %q{A scandal prevents me from ever going home again. That kind of trouble seems to follow me around.},
        %q{I once satirized a noble who still wants my head. It was a mistake that I will likely repeat.},
        %q{I have trouble keeping my true feelings hidden. My sharp tongue lands me in trouble.},
        %q{Despite my best efforts, I am unreliable to my friends.}
      ]
    when 'Folk Hero'
      @proficiencies << :animal_handling
      @proficiencies << :survival
      personality_options = [
        %q{I judge people by their actions, not their words.},
        %q{If someone is in trouble, I'm always ready to lend help.},
        %q{When I set my mind to something, I follow through no matter what gets in my way.},
        %q{I have a strong sense of fair play and always try to find the most equitable solution to arguments.},
        %q{I'm confident in my own abilities and do what I can to instill confidence in others.},
        %q{Thinking is for other people. I prefer action.},
        %q{I misuse long words in an attempt to sound smarter.},
        %q{I get bored easily. When am I going to get on with my destiny?}
      ]
      ideal_options = [
        %q{Respect. People deserve to be treated with dignity and respect. (Good)},
        %q{Fairness. No one should get preferential treatment before the law, and no one is above the law. (Lawful)},
        %q{Freedom. Tyrants must not be allowed to oppress the people. (Chaotic)},
        %q{Might. If I become strong, I can take what I want - what I deserve. (Evil)},
        %q{Sincerity. There's no good in pretending to be something I'm not. (Neutral)},
        %q{Destiny. Nothing and no one can steer me away from my higher calling. (Any)}
      ]
      bond_options = [
        %q{I have a family, but I have no idea where they are. One day, I hope to see them again.},
        %q{I worked the land, I love the land, and I will protect the land.},
        %q{A proud noble once gave me a horrible beating, and I will take my revenge on any bully I encounter.},
        %q{My tools are symbols of my past life, and I carry them so that I will never forget my roots.},
        %q{I protect those who cannot protect themselves.},
        %q{I wish my childhood sweetheart had come with me to pursue my destiny.}
      ]
      flaw_options = [
        %q{The tyrant who rules my land will stop at nothing to see me killed.},
        %q{I'm convinced of the significance of my destiny, and blind to my shortcomings and the risk of failure.},
        %q{The people who knew me when I was young know my shameful secret, so I can never go home again.},
        %q{I have a weakness for the vices of the city, especially hard drink.},
        %q{Secretly, I believe that things would be better if I were a tyrant lording over the land.},
        %q{I have trouble trusting in my allies.}
      ]
    when 'Guild Artisan'
      @proficiencies << :insight
      @proficiencies << :persuasion
      puts 'Please enter a language to be proficient in.'
      @languages << choose(from: LANGUAGES - @languages)
      personality_options = [
        %q{I believe that anything worth doing is worth doing right. I can't help it - I'm a perfectionist.},
        %q{I'm a snob who looks down on those who can't appreciate fine art.},
        %q{I always want to know how things work and what makes people tick.},
        %q{I'm full of witty aphorisms and have a proverb for every occasion.},
        %q{I'm rude to people who lack my commitment to hard work and fair play.},
        %q{I like to talk at length about my profession.},
        %q{I don't part with my money easily and will haggle tirelessly to get the best deal possible.},
        %q{I'm well known for my work, and I want to make sure everyone appreciates it. I'm always taken aback when people haven't heard of me.}
      ]
      ideal_options = [
        %q{Community. It is the duty of all civilized people to strengthen the bonds of community and the security of civilization. (Lawful)},
        %q{Generosity. My talents were given to me so that I could use them to benefit the world. (Good)},
        %q{Freedom. Everyone should be free to pursue his or her own livelihood. (Chaotic)},
        %q{Greed. I'm only in it for the money. (Evil)},
        %q{People. I'm committed to the people I care about, not to ideals. (Neutral)},
        %q{Aspiration. I work hard to be the best there is at my craft. (Any)}
      ]
      bond_options = [
        %q{The workshop where I learned my trade is the most important place in the world to me.},
        %q{I created a great work for someone, and then found them unworthy to receive it. I'm still looking for someone worthy.},
        %q{I owe my guild a great debt for forging me into the person I am today.},
        %q{I pursue wealth to secure someone's love.},
        %q{One day I will return to my guild and prove that I am the greatest artisan of them all.},
        %q{I will get revenge on the evil forces that destroyed my place of business and ruined my livelihood.}
      ]
      flaw_options = [
        %q{I'll do anything to get my hands on something rare or priceless.},
        %q{I'm quick to assume that someone is trying to cheat me.},
        %q{No one must ever learn that I once stole money from guild coffers.},
        %q{I'm never satisfied with what I have - I always want more.},
        %q{I would kill to acquire a noble title.},
        %q{I'm horribly jealous of anyone who can outshine my handiwork. Everywhere I go, I'm surrounded by rivals.}
      ]
    when 'Hermit'
      @proficiencies << :medicine
      @proficiencies << :religion
      puts 'Please enter a language to be proficient in.'
      @languages << choose(from: LANGUAGES - @languages)
      personality_options = [
        %q{I've been isolated for so long that I rarely speak, preferring gestures and the occasional grunt.},
        %q{I am utterly serene, even in the face of disaster.},
        %q{The leader of my community had something wise to say on every topic, and I am eager to share that wisdom.},
        %q{I feel tremendous empathy for all who suffer.},
        %q{I'm oblivious to etiquette and social expectations.},
        %q{I conneet everything that happens to me to a grand, cosmic plan.},
        %q{I often get lost in my own thoughts and contemplation, becoming oblivious to my surroundings.},
        %q{I am working on a grand philosophical theory and love sharing my ideas.}
      ]
      ideal_options = [
        %q{Greater Good. My gifts are meant to be shared with all, not used for my own benefit. (Good)},
        %q{Logic. Emotions must not cloud our sense of what is right and true, or our logical thinking. (Lawful)},
        %q{Free Thinking. Inquiry and curiosity are the pillars of progress. (Chaotic)},
        %q{Power. Solitude and contemplation are paths toward mystical or magical power. (Evil)},
        %q{Live and Let Live. Meddling in the affairs of others only causes trouble. (Neutral)},
        %q{Self-Knowledge. If you know yourself, there's nothing left to know. (Any)}
      ]
      bond_options = [
        %q{Nothing is more important than the other members of my hermitage, order, or association.},
        %q{I entered seclusion to hide from the ones who might still be hunting me. I must someday confront them.},
        %q{I'm still seeking the enlightenment I pursued in my seclusion, and it still eludes me.},
        %q{I entered seclusion because I loved someone I could not have.},
        %q{Should my discovery come to light, it could bring ruin to the world.},
        %q{My isolation gave me great insight into a great evil that only I can destroy.}
      ]
      flaw_options = [
        %q{Now that I've returned to the world, I enjoy its delights a little too much.},
        %q{I harbor dark, bloodthirsty thoughts that my isolation and meditation failed to quell.},
        %q{I am dogmatic in my thoughts and philosophy.},
        %q{I let my need to win arguments overshadow friendships and harmony.},
        %q{I'd risk too much to uncover a lost bit of knowledge.},
        %q{I like keeping secrets and won't share them with anyone.}
      ]
    when 'Noble'
      @proficiencies << :history
      @proficiencies << :persuasion
      puts 'Please enter a language to be proficient in.'
      @languages << choose(from: LANGUAGES - @languages)
      personality_options = [
        %q{My eloquent flattery makes everyone I talk to feel like the most wonderful and important person in the world.},
        %q{The common folk love me for my kindness and generosity.},
        %q{No-one could doubt by looking at my regal bearing that I am a cut above the unwashed masses.},
        %q{I take great pains to always look my best and follow the latest fashions.},
        %q{I don't like to get my hands dirty, and I won't be caught dead in unsuitable accommodations.},
        %q{Despite my noble birth, I do not place myself above other folk. We all have the same blood.},
        %q{My favor, once lost, is lost forever.},
        %q{If you do me an injury, I will crush you, ruin your name, and salt your fields.}
      ]
      ideal_options = [
        %q{Respect. Respect is due to me because of my position, but all people regardless of station deserve to be treated with dignity. (Good)},
        %q{Responsibility. It is my duty to respect the authority of those above me, just as those below me must respect mine. (Lawful)},
        %q{Independence. I must prove that I can handle myself without the coddling of my family. (Chaotic)},
        %q{Power. If I can obtain more power, no one will tell me what to do. (Evil)},
        %q{Family. Blood runs thicker than water. (Any)},
        %q{Noble Obligation. It is my duty to protect and care for the people beneath me. (Good)}
      ]
      bond_options = [
        %q{I will face any challenge to win the approval of my family.},
        %q{My house's alliance with another noble family must be sustained at all costs.},
        %q{Nothing is more important than the other members of my family.},
        %q{I am in love with the heir of a family that my family despises.},
        %q{My loyalty to my sovereign is unwavering.},
        %q{The common folk must see me as a hero of the people.}
      ]
      flaw_options = [
        %q{I secretly believe that everyone is beneath me.},
        %q{I hide a truly scandalous secret that could ruin my family forever.},
        %q{I too often hear veiled insults and threats in every word addressed to me, and I'm quick to anger.},
        %q{I have an insatiable desire for carnal pleasures.},
        %q{In fact, the world does revolve around me.},
        %q{By my words and actions, I often bring shame to my family.}
      ]
    when 'Outlander'
      @proficiencies << :athletics
      @proficiencies << :survival
      puts 'Please enter a language to be proficient in.'
      @languages << choose(from: LANGUAGES - @languages)
      personality_options = [
        %q{I'm driven by a wanderlust that led me away from home.},
        %q{I watch over my friends as if they were a litter of newborn pups.},
        %q{I once ran twenty-five miles without stopping to warn my clan of an approaching orc horde. I'd do it again if I had to.},
        %q{I have a lesson for every situation, drawn from observing nature.},
        %q{I place no stock in wealthy or well-mannered folk. Money and manners won't save you from a hungry owlbear.},
        %q{I'm always picking things up, absently fiddling with them, and sometimes accidentally breaking them.},
        %q{I feel far more comfortable around animals than people.},
        %q{I was, in fact, raised by wolves.}
      ]
      ideal_options = [
        %q{Change. Life is like the seasons, in constant change, and we must change with it. (Chaotic)},
        %q{Greater Good. It is each person's responsibility to make the most happiness for the whole tribe. (Good)},
        %q{Honor. If I dishonor myself, I dishonor my whole clan. (Lawful)},
        %q{Might. The strongest are meant to rule. (Evil)},
        %q{Nature. The natural world is more important than all the constructs of civilization. (Neutral)},
        %q{Glory. I must earn glory in battle, for myself and my clan. (Any)}
      ]
      bond_options = [
        %q{My family, clan, or tribe is the most important thing in my life, even when they are far from me.},
        %q{An injury to the unspoiled wilderness of my home is an injury to me.},
        %q{I will bring terrible wrath down on the evildoers who destroyed my homeland.},
        %q{I am the last of my tribe, and it is up to me to ensure their names enter legend.},
        %q{I suffer awful visions of a coming disaster and will do anything to prevent it.},
        %q{It is my duty to provide children to sustain my tribe.}
      ]
      flaw_options = [
        %q{I am too enamored of ale, wine, and other intoxicants.},
        %q{There's no room for caution in a life lived to the fullest.},
        %q{I remember every insult I've received and nurse a silent resentment toward anyone who's ever wronged me.},
        %q{I am slow to trust members of other races, tribes, and societies.},
        %q{Violence is my answer to almost any ehallenge.},
        %q{Don't expect me to save those who can't save themselves. It is nature's way that the strong thrive and the weak perish.}
      ]
    when 'Sage'
      @proficiencies << :arcana
      @proficiencies << :history
      puts 'Please enter two languages to be proficient in.'
      2.times { @languages << choose(from: LANGUAGES - @languages) }
      personality_options = [
        %q{I use polysyllabic words that convey the impression of greal erudition.},
        %q{I've read every book in the world's greatest libraries - or I like to boast that I have.},
        %q{I'm used to helping out those who aren't as smart as I am, and I patiently explain anything and everything to others.},
        %q{There's nothing I like more than a good mystery.},
        %q{I'm willing to listen to every side of an argument before I make my own judgment.},
        %q{I ... speak ... slowly ... when talking to idiots, which ... almost ... everyone ... is compared ... to me.},
        %q{I am horribly, horribly awkward in social situations.},
        %q{I'm convinced that people are always trying to steal my secrets.}
      ]
      ideal_options = [
        %q{Knowledge. The path to power and self-improvement is through knowledge. (Neutral)},
        %q{Beauty. What is beautiful points us beyond itself toward what is true. (Good)},
        %q{Logic. Emotions must not cloud our logical thinking. (Lawful)},
        %q{No Limits. Nothing should fetter the infinite possibility inherent in all existence. (Chaotic)},
        %q{Power. Knowledge is the path to power and domination. (Evil)},
        %q{Self-improvement. The goal of a life of study is the betterment of oneself. (Any)}
      ]
      bond_options = [
        %q{It is my duty to protect my students.},
        %q{I have an ancient text that holds terrible secrets that must not fall into the wrong hands.},
        %q{I work to preserve a library, university, scriptorium, or monastery.},
        %q{My life's work is a series of tomes related to a speeific field of lore.},
        %q{I've been searching my whole life for the answer to a certain question.},
        %q{I sold my soul for knowledge. I hope to do great deeds and win it back.}
      ]
      flaw_options = [
        %q{I am easily distracted by the promise of information.},
        %q{Most people scream and run when they see a demon. I stop and take notes on its anatomy.},
        %q{Unlocking an ancient mystery is worth the price of a civilization.},
        %q{I overlook obvious solutions in favor of complicated ones.},
        %q{I speak without really thinking through my words, invariably insulting others.},
        %q{I can't keep a seeret to save my life, or anyone else's.}
      ]
    when 'Sailor'
      @proficiencies << :athletics
      @proficiencies << :perception
      personality_options = [
        %q{My friends know they can rely on me, no matter what.},
        %q{I work hard so that I can play hard when the work is done.},
        %q{I enjoy sailing into new ports and making new friends over a flagon of ale.},
        %q{I stretch the truth for the sake of a good story.},
        %q{To me, a tavern brawl is a nice way to get to know a new city.},
        %q{I never pass up a friendly wager.},
        %q{My language is as foul as an otyugh nest.},
        %q{I like a job well done, especially if I can convince someone else to do it.}
      ]
      ideal_options = [
        %q{Respect. The thing that keeps a ship together is mutual respect between captain and crew. (Good)},
        %q{Fairness. We all do the work, so we all share in the rewards. (Lawful)},
        %q{Freedom. The sea is freedom - The freedom to go anywhere and do anything. (Chaotic)},
        %q{Mastery. I'm a predator, and the other ships on the sea are my prey. (Evil)},
        %q{People. I'm committed to my crewmates, not to ideals. (Neutral)},
        %q{Aspiration. Someday I'll own my own ship and chart my own destiny. (Any)}
      ]
      bond_options = [
        %q{I'm loyal to my captain first, everything else second.},
        %q{The ship is most important - crewmates and captains come and go.},
        %q{I'll always remember my first ship.},
        %q{In a harbor town, I have a paramour whose eyes nearly stole me from the sea.},
        %q{I was cheated out of my fair share of the profits, and I want to get my due.},
        %q{Ruthless pirates murdered my captain and crewmates, plundered our ship, and left me to die. Vengeance will be mine.}
      ]
      flaw_options = [
        %q{I follow orders, even if I think they're wrong.},
        %q{I'll say anything to avoid having to do extra work.},
        %q{Once someone questions my courage, I never back down no matter how dangerous the situation.},
        %q{Once I start drinking, it's hard for me to stop.},
        %q{I can't help but pocket loose coins and other trinkets I come across.},
        %q{My pride will probably lead to my destruction.}
      ]
    when 'Soldier'
      @proficiencies << :athletics
      @proficiencies << :intimidation
      personality_options = [
        %q{I'm always polite and respectful.},
        %q{I'm haunted by memories of war. I can't get the images of violence out of my mind.},
        %q{I've lost too many friends, and I'm slow to make new ones.},
        %q{I'm full of inspiring and cautionary tales from my military experience relevant to almost every combat situation.},
        %q{I can stare down a hell hound without flinching.},
        %q{I enjoy being strong and like breaking things.},
        %q{I have a crude sense of humor.},
        %q{I face problems head on. A simple, direct solution is the best path to success.},
      ]
      ideal_options = [
        %q{Greater Good. Our lot is to lay down our lives in defense of others. (Good)},
        %q{Responsibility. I do what I must and obey just authority. (Lawful)},
        %q{Independence. When people follow orders blindly, they embrace a kind of tyranny. (Chaotic)},
        %q{Might. In life as in war, the stronger force wins. (Evil)},
        %q{Live and Let Live. Ideals aren't worth killing over or going to war for. (Neutral)},
        %q{Nation. My city, nation, or people are all that matter. (Any)}
      ]
      bond_options = [
        %q{I would still lay down my life for the people I served with.},
        %q{Someone saved my life on the battlefield. To this day, I will never leave a friend behind.},
        %q{My honor is my life.},
        %q{I'll never forget the crushing defeat my company suffered or the enemies who dealt it.},
        %q{Those who fight beside me are those worth dying for.},
        %q{I fight for those who cannot fight for themselves.}
      ]
      flaw_options = [
        %q{The monstrous enemy we faced in battle still leaves me quivering with fear.},
        %q{I have little respect for anyone who is not a proven warrior.},
        %q{I made a terrible mistake in battle, cost many lives and I would do anything to keep that mistake secret.},
        %q{My hatred of my enemies is blind and unreasoning.},
        %q{I obey the law, even if the law causes misery.}
        %q{I'd rather eat my armor than admit when I'm wrong.}
      ]
    when 'Urchin'
      @proficiencies << :sleight_of_hand
      @proficiencies << :stealth
      personality_options = [
        %q{I hide scraps of food and trinkets away in my pockets.},
        %q{I ask a lot of questions.},
        %q{I like to squeeze into small places where no one else can get to me.},
        %q{I sleep with my back to a wall or tree, with everything I own wrapped in a bundle in my arms.},
        %q{I eat like a pig and have bad manners.},
        %q{I think anyone who's nice to me is hiding evil intent.},
        %q{I don't like to bathe.},
        %q{I bluntly say what other people are thinking at or hiding.}
      ]
      ideal_options = [
        %q{Respect. All people, rich or poor, deserve respect. (Good)},
        %q{Community. We have to take care of each other, because no one else is going to do it. (Lawful)},
        %q{Change. The low are lifted up, and the high and mighty are brought down. Change is the nature of things. (Chaotic)},
        %q{Retribution. The rich need to be shown what life and death are like in the gutters. (Evil)},
        %q{People. I help the people who help me - that's what keeps us alive. (Neutral)},
        %q{Aspiration. I'm going to prove that I'm worthy of a better life.}
      ]
      bond_options = [
        %q{My town or city is my home, and I'll fight to defend it.},
        %q{I sponsor an orphanage to keep others from enduring what I was forced to endure.},
        %q{I owe my survival to another urchin who taught me to live on the streets.},
        %q{I owe a debt I can never repay to the person who took pity on me.},
        %q{I escaped my life of poverty by robbing an important person, and I'm wanted for it.},
        %q{No one else should have to endure the hardships I've been through.}
      ]
      flaw_options = [
        %q{If I'm outnumbered, I will run away from a fight.},
        %q{Gold seems like a lot of money to me, and I'll do just about anything for more of it.},
        %q{I will never fully trust anyone other than myself.},
        %q{I'd rather kill someone in their sleep then fight fair.},
        %q{It's not stealing if I need it more than someone else.},
        %q{People who can't take care of themselves get what they deserve.}
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
