module Mumboe
module Izzle
module Preference
module Helper # :nodoc:
  
  def self.init(klass)
    klass.class_eval do
      unless included_modules.include?(InstanceMethods)
        class_inheritable_accessor :preference_options
        class_inheritable_accessor :preference_definitions
        self.preference_options = Options.new
        self.preference_definitions = {}
        after_save 'self.preferences.save'
        validate 'self.preferences.validate'
        include InstanceMethods
      end
    end
  end
  
  def self.define_accessors(klass, key, options)
    
    method_name = "prefers_#{key}?"
    method_definition = <<-end_eval
      def #{method_name}
        !!preferences['#{key}']
      end
    end_eval
    klass.class_eval(method_definition) unless klass.method_defined?(method_name)
  
    method_name = "prefers_#{key}="
    method_definition = <<-end_eval
      def #{method_name}(value)
        preferences['#{key}'] = value
      end
    end_eval
    klass.class_eval(method_definition) unless klass.method_defined?(method_name)
    
    method_name = "preferred_#{key}"
    method_definition = <<-end_eval
      def #{method_name}
        preferences['#{key}']
      end
    end_eval
    klass.class_eval(method_definition) unless klass.method_defined?(method_name)
    
    method_name = "preferred_#{key}="
    method_definition = <<-end_eval
      def #{method_name}(value)
        preferences['#{key}'] = value
      end
    end_eval
    klass.class_eval(method_definition) unless klass.method_defined?(method_name)
  end
  
end
end
end
end