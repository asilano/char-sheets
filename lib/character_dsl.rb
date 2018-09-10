module CharacterDSL
  def stat(name, type, options = {})
    attr_accessor name

    case type
    when :integer
      validates name, numericality: { only_integer: true }, allow_nil: true
    end

    options.each do |key, opt|
      case key
      when :one_of
        raise ArgumentError, "Expected array of valid values: #{name}" unless opt.is_a? Array

        validates name, inclusion: { in: opt }, allow_nil: true
      end
    end
  end

  def stat_block(name, &block)
    nested_class = const_set("Nested_#{name}", Class.new do
      extend CharacterDSL
      include ActiveModel::Validations
      instance_eval(&block)
    end)

    define_method(name) do
      instance_variable_set("@#{name}", nested_class.new) unless instance_variable_defined?("@#{name}")
      instance_variable_get("@#{name}")
    end
  end
end
