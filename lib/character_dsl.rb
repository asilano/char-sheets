module CharacterDSL
  def stat(name, type, options = {})
    attr_accessor name

    options.each do |key, opt|
      case key
      when :one_of
        raise ArgumentError, "Expected array of valid values: #{name}" unless opt.is_a? Array
        define_method("#{name}=") do |new_val|
          unless opt.include?(new_val)
            puts "Bad value for #{name}: #{new_val}."
            return
          end
          instance_variable_set("@#{name}", new_val)
        end
      end
    end
  end
end
