require 'yaml'
require 'active_model'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/delegation'
require_relative '../cli-ui/cli-ui'
require_relative './character_dsl'

CHARACTER_PATH = File.join(__dir__, '..', 'characters')

class Character
  include CharacterDSL
  include ActiveModel::Validations
  delegate :prompt, :choose, :choose_by_number, :enter, to: :@interface

  stat :character_name, :string

  def initialize(interface: nil)
    setup
    @interface = interface
    @interface&.character = self
  end

  def character
    self
  end

  def template_name
    self.class.name.downcase
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
    character.send(:setup)
    character
  end

  private

  def setup
    self.class.initializable.each do |i, v|
      instance_variable_set("@#{i}", v) unless instance_variable_defined?("@#{i}")
    end
  end
end
