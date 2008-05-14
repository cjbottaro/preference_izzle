require File.dirname(__FILE__) + '/../../../../test/test_helper'

ActiveRecord::Base.connection.create_table(:preference_clients, :force => true) do |t|
end
ActiveRecord::Base.connection.create_table(:preference_users, :force => true) do |t|
end

class Client < ActiveRecord::Base
  self.table_name = 'preference_clients'
  preference_options :autovivify => true
  preference_definition :min, :default => 1
  preference_definition :max, :default => 10
  preference_definition :boolean, :default => true
  preference_definition :valid_string, :validate => String
  preference_definition :valid_fixnum, :validate => Fixnum
  preference_definition :valid_boolean, :validate => [TrueClass, FalseClass]
  preference_definition :valid_number, :validate => Proc.new{ |value| Float(value) }
end

class User < ActiveRecord::Base
  self.table_name = 'preference_users'
  preference_options :autovivify  => false,
                     :alias       => :prefs
  preference_definition :min, :default => :client
                  
  belongs_to :client
end

class PreferenceIzzleTest < Test::Unit::TestCase
  
  def setup
    Client.delete_all
    User.delete_all
    Mumboe::Izzle::Preference::Preference.delete_all
    @client = Client.new
    @user = User.new :client => @client
  end
  
  def test_get_defaults
    assert_equal 1,  @client.preferences[:min]
    assert_equal 10, @client.preferences[:max]
  end
  
  def test_get_defaults_association
    assert_equal 1, @user.preferences[:min]
  end
  
  def test_get_non_declared
    assert_raises(ArgumentError) { @user.preferences[:something] }
    assert_nil @client.preferences[:something]
  end
  
  def test_set_basic
    @user.preferences[:min] = 2
    assert_equal 2, @user.preferences[:min]
  end
  
  def test_set_twice
    assert_equal 1, @user.preferences[:min]
    @user.preferences[:min] = 2
    assert_equal 2, @user.preferences[:min]
    @user.preferences[:min] = 3
    assert_equal 3, @user.preferences[:min]
  end
  
  def test_method_missing
    assert_raises(NoMethodError) { @user.preferences.something }
    
    assert_equal false, @client.public_methods.include?('prefers_something?')
    assert_equal false, @client.public_methods.include?('prefers_something=')
    assert_equal false, @client.public_methods.include?('preferred_something')
    assert_equal false, @client.public_methods.include?('preferred_something=')
    assert_equal false, @client.preferences.public_methods.include?('something')
    assert_equal false, @client.preferences.public_methods.include?('something=')
    assert_nil @client.preferences.something
    assert_equal true, @client.public_methods.include?('prefers_something?')
    assert_equal true, @client.public_methods.include?('prefers_something=')
    assert_equal true, @client.public_methods.include?('preferred_something')
    assert_equal true, @client.public_methods.include?('preferred_something=')
    assert_equal true, @client.preferences.public_methods.include?('something')
    assert_equal true, @client.preferences.public_methods.include?('something=')
  end
  
  def test_alias
    assert_equal @user.preferences[:min], @user.prefs[:min]
    assert_raise(NoMethodError){ @client.prefs }
  end
  
  def test_boolean
    assert_equal true, @client.preferences[:boolean]
    @client.preferences[:boolean] = false
    assert_equal false, @client.preferences[:boolean]
    @client.preferences[:boolean] = true
    assert_equal true, @client.preferences[:boolean]
  end
  
  def test_hash
    hash = { :one => 1, :two => 'two' }
    @client.preferences[:hash] = hash
    assert_equal hash, @client.preferences[:hash]
  end
  
  def test_array
    array = [1, 'two', :three]
    @client.preferences[:array] = array
    assert_equal array, @client.preferences[:array]
  end
  
  def test_dynamic_readers
    assert_equal 1, @client.preferred_min
    assert_equal 10, @client.preferred_max
    assert_equal true, @client.prefers_boolean?
    assert_equal 1, @user.preferred_min
  end
  
  def test_dynamic_writers
    @client.preferred_min = 2
    @client.preferred_max = 11
    @client.prefers_boolean = false
    @user.preferred_min = 3
    
    assert_equal 2, @client.preferred_min
    assert_equal 11, @client.preferred_max
    assert_equal false, @client.prefers_boolean?
    assert_equal 3, @user.preferred_min
  end
  
  def test_validation
    @client.preferred_valid_string = 'test'
    assert_equal 'test', @client.preferred_valid_string
    @client.preferred_valid_string = 1
    assert @client.valid? == false
    assert_equal %q[validation failed for preference 'valid_string' - Fixnum is not String], @client.errors.on(:preferences)
    @client.preferred_valid_string = 'test'
    assert @client.valid?
    
    @client.preferred_valid_number = 123
    assert @client.valid?
    @client.preferred_valid_number = "one two three"
    assert @client.valid? == false
    assert_equal %q[validation failed for preference 'valid_number' - invalid value for Float(): "one two three"], @client.errors.on(:preferences)
    @client.preferred_valid_number = 123
    assert @client.valid?
    
    @client.preferred_valid_boolean = true
    assert @client.valid?
    @client.preferred_valid_boolean = false
    assert @client.valid?
    @client.preferred_valid_boolean = "true"
    assert @client.valid? == false
    assert_equal %q[validation failed for preference 'valid_boolean' - String is not TrueClass or FalseClass], @client.errors.on(:preferences)
    @client.preferred_valid_boolean = true
    assert @client.valid?
  end
  
  def test_saving
    @client.preferred_min = 2
    @client.preferred_max = 11
    @client.preferred_boolean = false
    @client.preferred_valid_string = 'hello world'
    @client.preferred_valid_fixnum = 12345
    @client.preferred_valid_number = 12345.67
    @client.preferred_valid_boolean = true
    
    @client.save
    assert @client.errors.empty?
    
    assert_equal 2, Mumboe::Izzle::Preference::Preference.find_by_model_type_and_model_id_and_key('Client', @client.id, 'min').value
    assert_equal 11, Mumboe::Izzle::Preference::Preference.find_by_model_type_and_model_id_and_key('Client', @client.id, 'max').value
    assert_equal false, Mumboe::Izzle::Preference::Preference.find_by_model_type_and_model_id_and_key('Client', @client.id, 'boolean').value
    assert_equal 'hello world', Mumboe::Izzle::Preference::Preference.find_by_model_type_and_model_id_and_key('Client', @client.id, 'valid_string').value
    assert_equal 12345, Mumboe::Izzle::Preference::Preference.find_by_model_type_and_model_id_and_key('Client', @client.id, 'valid_fixnum').value
    assert_equal 12345.67, Mumboe::Izzle::Preference::Preference.find_by_model_type_and_model_id_and_key('Client', @client.id, 'valid_number').value
    assert_equal true, Mumboe::Izzle::Preference::Preference.find_by_model_type_and_model_id_and_key('Client', @client.id, 'valid_boolean').value
    
    assert_equal 2, @client.preferred_min
    assert_equal 11, @client.preferred_max
    assert_equal false, @client.preferred_boolean
    assert_equal 'hello world', @client.preferred_valid_string
    assert_equal 12345, @client.preferred_valid_fixnum
    assert_equal 12345.67, @client.preferred_valid_number
    assert_equal true, @client.preferred_valid_boolean
    
    @client.preferences.reload
    
    assert_equal 2, @client.preferred_min
    assert_equal 11, @client.preferred_max
    assert_equal false, @client.preferred_boolean
    assert_equal 'hello world', @client.preferred_valid_string
    assert_equal 12345, @client.preferred_valid_fixnum
    assert_equal 12345.67, @client.preferred_valid_number
    assert_equal true, @client.preferred_valid_boolean
  end
  
end
