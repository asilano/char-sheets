class CommandLineInterface
  attr_writer :character

  def prompt(prompt_str)
    puts prompt_str
  end

  def choose(field = nil, subfield = nil, from: [])
    puts "Please enter your character's #{field}." if field
    main_choices = from.map { |r| r.is_a?(Hash) ? r.keys.first : r }
    main_choice = get_choice(main_choices)
    @character.instance_variable_set("@#{field}", main_choice) if field

    if subfield &&
       !from.include?(main_choice) &&
       (sub_hash = from.detect { |c| c.is_a?(Hash) && c.keys.first == main_choice })
      puts
      puts "Please enter your character's #{subfield}."
      sub_choices = sub_hash[main_choice]
      sub_choice = get_choice(sub_choices)
      @character.instance_variable_set("@#{subfield}", sub_choice) if subfield
    end

    puts
    sub_choice ? [main_choice, sub_choice] : main_choice
  end

  def get_choice(choices)
    loop do
      print "(#{choices.join(' | ')}): "
      choice = gets.chomp
      break choice if choices.map(&:to_s).include? choice
      puts
      puts "Sorry, that was not a valid selection."
    end
  end

  def enter(field = nil)
    puts "Please enter your character's #{field}." if field
    value = gets.chomp
    @character.instance_variable_set("@#{field}", value) if field
    puts
    value
  end

  def choose_by_number(field = nil, from: [], allow_random: false, allow_free: false)
    puts "Please select your character's #{field}." if field
    from.each.with_index do |choice, number|
      puts "  #{number + 1}: #{choice}"
    end
    choices = (1..from.length).to_a.map(&:to_s)
    choices << 'random' if allow_random
    choices << 'free' if allow_free
    main_choice = get_choice(choices)

    case main_choice
    when 'random'
      value = from.sample
      puts "Selected: #{value}"
    when 'free'
      puts 'Please enter your own choice.'
      value = enter
    else
      value = from[main_choice.to_i - 1]
    end
    @character.instance_variable_set("@#{field}", value) if field
    puts
    value
  end
end
