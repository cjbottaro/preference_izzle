module Mumboe
module Izzle
module Preference
  
  class Preference < ActiveRecord::Base # :nodoc:
    def value=(v)
      method_missing(:value=, v.to_yaml)
    end
    def value
      YAML.load(method_missing(:value))
    end
  end
  
end
end
end