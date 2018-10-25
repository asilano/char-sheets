require 'yaml'
require 'active_model'
require_relative './character_dsl'

CHARACTER_PATH = File.join(__dir__, '..', 'characters')

class Character
  include CharacterDSL
  include ActiveModel::Validations

  stat :character_name, :string

  def initialize(name)
    setup
    @character_name = name
  end

  def character
    self
  end

  # Write a character to disk as YAML
  def save
    return false unless valid?

    File.open(File.join(CHARACTER_PATH, "#{@character_name.downcase}.char"), 'w') do |file|
      file.write(YAML.dump(self))
    end

    true
  end

  # Load a character from YAML on disk
  def self.load(charname)
    character = YAML.load(File.read(File.join(CHARACTER_PATH, "#{charname.downcase}.char")))
    character.setup
    character
  end

  # def init_with(coder)
  #   @character_name = coder[:name]
  # end

  def setup
    self.class.initializable.each do |i, v|
      instance_variable_set("@#{i}", v) unless instance_variable_defined?("@#{i}")
    end
  end
end
