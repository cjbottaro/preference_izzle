module ActiveRecord # :nodoc:
  class Errors # :nodoc:
    def clear_on(attribute)
      @errors.delete(attribute.to_s)
    end
  end
end