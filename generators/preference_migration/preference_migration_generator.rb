class PreferenceMigrationGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.migration_template "preference_migration.rb", "db/migrate"
    end
  end
end