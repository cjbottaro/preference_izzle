class <%= class_name.underscore.camelize %> < ActiveRecord::Migration
  def self.up
    create_table :preferences, :force => true do |t|
      t.string   :model_type,  :null => false
      t.integer  :model_id,    :null => false
      t.string   :on_type
      t.integer  :on_id
      t.string   :key,         :null => false
      t.string   :value
      t.timestamps
    end
  end

  def self.down
    drop_table :preferences
  end
end