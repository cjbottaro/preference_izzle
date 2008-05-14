require 'active_record/errors'
require 'definition'
require 'helper'
require 'options'
require 'preference'
require 'proxy'

# PreferenceIzzle
module Mumboe # :nodoc:
module Izzle # :nodoc:
module Preference # :nodoc:
      
  def self.included(mod)
    mod.extend ClassMethods
  end
  
  class PreferencesInvalid < RuntimeError # :nodoc:
  end

  module ClassMethods
  
    # Sets the options used by this model for preferences.
    #  preference_options :autovivify => true,
    #                     :alias => 'prefs'
    # :autovivify means you don't have to define preferences before using them.  It defaults to false.
    # :alias (or :shorthand) defines an alternate way to access the preferences. In this example, you can do both
    #  user.preferences.something
    #  user.prefs.something
    def preference_options(options = {})
      Helper.init(self)
    
      options.each do |name, value|
        name = name.to_s
        case name.to_s
        when 'autovivify'
          preference_options.autovivify = value
        when 'alias', 'shorthand'
          raise ArgumentError, "preference alias already specified '#{preference_options.alias}'" unless preference_options.alias.blank?
          preference_options.alias = value.to_s
          alias_method preference_options.alias, :preferences if preference_options.alias?
        else
          raise ArgumentError, "unrecognized preference option '#{value}'"
        end
      end
    end
    
    # Define a preference.  Call this method multiple times to define more than one preference.
    #  preference_definition :something, :default => 'hello world',
    #                                    :validate => String,
    #                                    :cast => Proc.new{ |value| value.to_s }
    # <tt>:default</tt> specifies what value should be returned when asking for a preference that hasn't been set yet.
    #
    # <tt>:validate</tt> specifies a means to ensure that a preference value is valid.  It can be a Class, an Array of Classes, a Proc or an Symbol denoting a method on the model that has the preferences.
    #
    # <tt>:cast</tt> transforms a preferences value when setting.
    def preference_definition(name, options = {})
      Helper.init(self)
    
      name = name.to_s
      options = options.stringify_keys
    
      raise ArgumentError, "preference '#{name}' already defined" if preference_definitions.has_key?(name)
      options.assert_valid_keys(*%w[validate default cast typecast])
    
      preference_definition = Definition.new(name)
      %w[validate default cast typecast].each do |k|
        next unless options.has_key?(k)
        v = options[k]
        case k
        when 'validate'
          preference_definition.set_validation(v)
        when 'default'
          preference_definition.set_default(v)
        when 'cast', 'typecast'
          preference_definition.set_caster(v)
        end
      end
    
      Helper.define_accessors(self, name, preference_options)
    
      preference_definitions[name] = preference_definition
    end
    
    alias_method :preference, :preference_definition
  
  end

  module InstanceMethods
    
    # Returns the proxy object through which you interact with the preferences.
    #   user.preferences.some_preference
    def preferences
      @preference_proxy ||= Proxy.new(self)
    end
  end
      
end
end
end