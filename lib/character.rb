require 'yaml'
require_relative './character_dsl'

CHARACTER_PATH = File.join(__dir__, '..', 'characters')

class Character
  extend CharacterDSL

  attr_accessor :character_name

  def initialize(name:)
    @character_name = name
  end

  # Write a character to disk as YAML
  def save
    File.open(File.join(CHARACTER_PATH, "#{@character_name.downcase}.char"), 'w') do |file|
      file.write(YAML.dump(self))
    end
  end

  # Load a character from YAML on disk
  def self.load(charname)
    YAML.load(File.read(File.join(CHARACTER_PATH, "#{charname.downcase}.char")))
  end

  # def encode_with(coder)
  #   coder[:name] = @character_name
  # end

  # def init_with(coder)
  #   @character_name = coder[:name]
  # end
end
