require 'yaml'
require 'active_model'
require 'active_support/core_ext/string/inflections'
require_relative './character_dsl'

CHARACTER_PATH = File.join(__dir__, '..', 'characters')

class Character
  include CharacterDSL
  include ActiveModel::Validations

  stat :character_name, :string

  def initialize(name = nil)
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
    character.send(:setup)
    character
  end

  # def init_with(coder)
  #   @character_name = coder[:name]
  # end

  private

  def setup
    self.class.initializable.each do |i, v|
      instance_variable_set("@#{i}", v) unless instance_variable_defined?("@#{i}")
    end
  end

  def choose(field, subfield=nil, from: [])
    puts "Please enter your character's #{field}."
    main_choices = from.map { |r| r.is_a?(Hash) ? r.keys.first : r }
    main_choice = get_choice(main_choices)
    instance_variable_set("@#{field}", main_choice)

    if subfield &&
       !from.include?(main_choice) &&
       sub_hash = from.detect { |c| c.is_a?(Hash) && c.keys.first == main_choice }
      puts
      puts "Please enter your character's #{subfield}."
      sub_choices = sub_hash[main_choice]
      sub_choice = get_choice(sub_choices)
      instance_variable_set("@#{subfield}", sub_choice)
    end
  end

  def get_choice(choices)
    loop do
      print "(#{choices.join(' | ')}): "
      choice = gets.chomp
      break choice if choices.include? choice
      puts
      puts "Sorry, that was not a valid selection."
    end
  end
end
