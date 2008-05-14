module Mumboe
module Izzle
module Preference
  
  class Definition # :nodoc:
    attr_accessor :name, :validation, :default, :caster
    
    def initialize(name)
      # TODO validation on name
      @name = name.to_s
    end
    
    def set_validation(validation)
      if validation.blank?
        nil
      elsif [Class, Proc, Symbol].include?(validation.class)
        nil
      elsif validation.instance_of?(Array) and validation.inject(true){ |memo, klass| memo && klass.instance_of?(Class) }
        nil
      else
        raise ArgumentError, ":validate option must be a Class, array of Classes, Proc or Symbol for preference '#{name}'"
      end
      @validation = validation
    end
    
    def set_default(value)
      @default = value
    end
    
    def set_caster(value)
      raise ArgumentError, ":cast or :typecast preference option must be a Symbol or a Proc" unless [Symbol, Proc].include?(value.class)
      @caster = value
    end
    
  end
  
end
end
end