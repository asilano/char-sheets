require_relative './character'

class DnD5e < Character
  stat :background, :string
  stat :speed, :integer
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
  stat :race, :string, one_of: %w[
    Kenku
    Dragonborn
    Dwarf
    Elf
    Gnome
    Half-Elf
    Halfling
    Half-Orc
    Human
    Tiefling
  ]

  stat_block :attributes do
    stat :strength, :integer
    stat :dexterity, :integer
    stat :constitution, :integer
    stat :intelligence, :integer
    stat :wisdom, :integer
    stat :charisma, :integer

    derived_stat :str_mod { (strength - 10) / 2 }
    derived_stat :dex_mod { (dexterity - 10) / 2 }
    derived_stat :con_mod { (constitution - 10) / 2 }
    derived_stat :int_mod { (intelligence - 10) / 2 }
    derived_stat :wis_mod { (wisdom - 10) / 2 }
    derived_stat :cha_mod { (charisma - 10) / 2 }
  end

  #derived_stat :initiative { attributes.dex_mod }

  # stat_block :abilities do
  #   derived_stat :acrobatics { character.attributes.dex_mod }
  # end
end
