module Mumboe
module Izzle
module Preference
  
  class Options # :nodoc:
    attr_accessor :autovivify, :alias
    alias_method :autovivify?, :autovivify
    
    def initialize
      @autovivify = false
      @alias = nil
    end
    
    def alias?
      !!@alias
    end
    
  end
  
end
end
end