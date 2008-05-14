module Mumboe
module Izzle
module Preference
  
  # This is the class through which you access preferences for a model.
  class Proxy
    
    def initialize(model) # :nodoc:
      @model = model
      @options = @model.class.preference_options
      @definitions = @model.class.preference_definitions
      @definitions.each{ |key, definition| define_accessor(key)  }
      reload
    end
    
    # Reload this model's preferences from the database.  You really shouldn't ever need to call this.
    #   user.preferences.reload
    def reload
      @dirty = []
      @cache = Preference.find_all_by_model_type_and_model_id(@model.class.name, @model.id).index_by(&:key)
    end
    
    # You can access preferences using array index notation.
    #   user.preferences[:favorite_color]
    def [](key)
      find_value(key)
    end
    
    # You can access preferences using array index notation.
    #   user.preferences[:favorite_color] = 'black'
    def []=(key, value)
      set(key, value)
    end
    
    def validate # :nodoc:
      @dirty.each do |key|
        preference = find_record(key)
        value = preference.value
        definition = @definitions[key]
        validation = definition.validation
        errors = @model.errors
        
        next if validation.blank?
        
        if validation.instance_of?(Class)
          errors.add :preferences, "validation failed for preference '#{key}' - #{value.class} is not #{validation.name}" unless value.instance_of?(validation)
        elsif validation.instance_of?(Array)
          valid_classes = validation.collect{ |klass| klass.name }.join(' or ')
          errors.add :preferences, "validation failed for preference '#{key}' - #{value.class} is not #{valid_classes}" unless validation.include?(value.class)
        elsif validation.instance_of?(Proc)
          begin
            validation.call(value)
          rescue Exception => e
            errors.add :preferences, "validation failed for preference '#{key}' - #{e}"
          end
        elsif validation.instance_of?(Symbol)
          begin
            @model.send(validation, value)
          rescue Exception => e
            errors.add :preferences,"validation failed for preference '#{key}' - #{e}"
          end
        end
      end
    end
    
    def save # :nodoc:
      @dirty.each do |key|
        @cache[key].model_id = @model.id
        @cache[key].save
      end
      @dirty = []
    end
    
    protected
    
    # If the :autovivify option is true, then method_missing with define accessors on the fly.
    #  user.public_methods.include?('preferred_favorite_color')     => false
    #  user.public_methods.include?('preferred_favorite_color=')    => false
    #  user.public_methods.include?('prefers_favorite_color?')      => false
    #  user.public_methods.include?('prefers_favorite_color=')      => false
    #  user.preferences.public_methods.include?('favorite_color')   => false
    #  user.preferences.public_methods.include?('favorite_color=')  => false
    #  
    #  user.preferences.favorite_color = 'black'
    #  
    #  user.public_methods.include?('preferred_favorite_color')     => true
    #  user.public_methods.include?('preferred_favorite_color=')    => true
    #  user.public_methods.include?('prefers_favorite_color?')      => true
    #  user.public_methods.include?('prefers_favorite_color=')      => true
    #  user.preferences.public_methods.include?('favorite_color')   => true
    #  user.preferences.public_methods.include?('favorite_color=')  => true
    def method_missing(key, *args)
      if @options.autovivify?
        define_accessor(key)
        self.send(key, *args)
      else
        super
      end
    end
    
    def find_record(key) # :nodoc:
      key = validate_key(key)
      @cache[key]
    end
    
    def find_value(key) # :nodoc:
      preference = find_record(key)
      if preference.blank?
        default(key)
      else
        preference.value
      end
    end
    
    def set(key, value) # :nodoc:
      key = validate_key(key)
      value = cast(key, value)
      if (preference = find_record(key))
        preference.value = value
      else
        @cache[key] = Preference.new :model_type => @model.class.name,
                                     :model_id => @model.id,
                                     :key => key,
                                     :value => value
      end
      @dirty << key unless @dirty.include?(key)
    end
    
    def default(key) # :nodoc:
      key = validate_key(key)
      return nil unless @definitions.has_key?(key)
      default = @definitions[key].default
      if default.instance_of?(Symbol) and @model.respond_to?(default)
        @model.send(default).preferences[key]
      else
        default
      end
    end
    
    def validate_key(key) # :nodoc:
      key = key.to_s
      raise ArgumentError, "preference '#{key}' needs to be defined when the :autovivify is false" \
        if @options.autovivify? == false and @definitions.has_key?(key) == false
      key
    end
    
    def cast(key, value) # :nodoc:
      definition = @definitions[key]
      return value if definition.blank? or definition.caster.blank?
      if definition.caster.instance_of?(Symbol)
        @model.send(definition.caster, value)
      elsif definition.caster.instance_of?(Proc)
        definition.caster.call(value)
      else
        raise ArgumentError, "preference :cast option for preference '#{key}' must be a Symbol or a Proc"
      end
    end
    
    def define_accessor(key) # :nodoc:
      
      method_name = key
      method_definition = <<-end_eval
        def #{method_name}
          find_value('#{key}')
        end
      end_eval
      self.class.class_eval(method_definition) unless self.class.method_defined?(method_name)
      
      method_name = "#{key}="
      method_definition = <<-end_eval
        def #{method_name}(value)
          set('#{key}', value)
        end
      end_eval
      self.class.class_eval(method_definition) unless self.class.method_defined?(method_name)
      
      Helper.define_accessors(@model.class, key, @options)
      
      # yes all this, including the body of Helper.define_accessors can be dry'ed out.
      
    end
    
  end
  
end
end
end