module CharacterDSL
  # Boilerplate to cause addition of both instance and class methods
  def self.included(base)
    base.extend(ClassMethods)

    # Set up a record of the stats we need to save out
    base.instance_eval do
      class_attribute :stats_to_save, :initializable
      self.stats_to_save = []
      self.initializable = {}
    end
  end

  def encode_with(coder)
    stats_to_save.each do |stat|
      coder[stat.to_s] = instance_variable_get("@#{stat}")
    end
  end

  module ClassMethods
    def inherited(subclass)
      subclass.stats_to_save = stats_to_save.dup
      subclass.initializable = initializable.dup
    end

    def stat(name, type, options = {})
      # Allow stat to be read/written
      attr_accessor name

      # Validations based on data type
      case type
      when :integer
        validates name, numericality: { only_integer: true }, allow_nil: true
      when :boolean
        validates name, inclusion: { in: [ true, false ] }, allow_nil: true
      end

      case type
      when :array
        self.initializable[name] = []
        undef_method("#{name}=")
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
      # We need to produce a method (called <name>), which calls the passed block
      # We do this as we cannot alias define_method directly
      define_method(name, &block)
    end

    def stat_block(name, &block)
      # For the stat block passed, create a nested class for its content
      nested_class = const_set("Nested_#{name}", Class.new do
        # Include libraries required to evaluate the content of the passed block
        include CharacterDSL
        include ActiveModel::Validations

        # Make character readable and writable to the contents of the passed block
        attr_accessor :character

        # Evaluate the contents of the passed block
        instance_eval(&block)
      end)

      define_method(name) do
        # Set an instance variable for our new nested block of stats, if one doesn't already exist
        #instance_variable_set("@#{name}", nested_class.new) unless instance_variable_defined?("@#{name}")
        # Retrieve the instance variable
        nested = instance_variable_get("@#{name}")
        # Give the nested stat block access to the top-level character, if it doesn't already have it
        nested.character ||= character
        # Return the nested stat block
        nested
      end

      self.initializable[name] = nested_class.new
      self.stats_to_save << name
    end

    def generate(&block)
      define_method(:create_me, &block)
      define_singleton_method(:create) do |interface = CommandLineInterface.new|
        new_char = new(interface: interface)
        new_char.send(:create_me)
        new_char
      end
    end
  end
end
