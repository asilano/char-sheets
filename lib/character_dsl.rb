module CharacterDSL
  def self.included(base)
    base.extend(ClassMethods)
    base.instance_eval do
      class_attribute :stats_to_save
      self.stats_to_save = []
    end
  end

  def encode_with(coder)
    stats_to_save.each do |stat|
      coder[stat] = instance_variable_get("@#{stat}")
    end
  end

  module ClassMethods
    def stat(name, type, options = {})
      # Allow stat to be read/written
      attr_accessor name

      # Validations based on data type
      case type
      when :integer
        validates name, numericality: { only_integer: true }, allow_nil: true
      end

      # Validations based on options
      options.each do |key, opt|
        case key
        when :one_of
          raise ArgumentError, "Expected array of valid values: #{name}" unless opt.is_a? Array

          validates name, inclusion: { in: opt }, allow_nil: true
        end
      end

      # Register stat for YAMLising
      self.stats_to_save << name
    end

    def derived_stat(name, &block)
    end

    def stat_block(name, &block)
      nested_class = const_set("Nested_#{name}", Class.new do
        include CharacterDSL
        include ActiveModel::Validations
        instance_eval(&block)
      end)

      define_method(name) do
        instance_variable_set("@#{name}", nested_class.new) unless instance_variable_defined?("@#{name}")
        instance_variable_get("@#{name}")
      end

      self.stats_to_save << name
    end
  end
end
