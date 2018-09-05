require_relative './character'

class DnD5e < Character
  stat :background, :string
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
end
