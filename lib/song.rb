require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

#Takes song class, referenced by self, to_s turns it into a string, and downcases, then pluralizes it.
  def self.table_name
    self.to_s.downcase.pluralize
  end

#Query the table for the names of its columns? Pragma line.
#PRAGMA will return an array of hashes describing the table.
#Each hash will contain information about one column.
  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    #Iterate over the resulting array of hashes to collect just the name of each column.
    table_info.each do |row|
      column_names << row["name"]
    end
    #call .compact on that to be safe and get rid of any nil values.
    column_names.compact
  end
  #returns ["id", "name", "album"], which we can use to create the attr_accessors.

#Iterate over column names class method (because of self)
#set an attr_accessor for each one
#column name -> symbol (to_sym)
#Metaprogramming (reader and writer method for each column name dynamically created)
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

#Takes in an argument of options, which defaults to an empty hash.
#Iterate over the options hash
#Use metaprogramming send method to interpolate the name of each hash key
#Each property must have a corresponding attr_accessor
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

#Save is an instance method, so self will refer to the instance of the class, not the class itself.
  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

#abstracting the table name to give us the table name
  def table_name_for_insert
    self.class.table_name
  end

#Grabbing the column names of the table associated with a class:
#column names class method have column names stored
#Send method = invoke a method without knowing the exact name of the method
#iterate ove rthe column names using send to capture the return value
#return value = string using join
#Abstract/flexible ways to grab each consitutent part of the SQL statement to save a record
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

#Column names into a comma separated list contained in a string (join)
#Need to remove id from the array of column names because id = nil
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

#Class method to find by name
#Dynamic because it uses the table_name class method we built that will return the table name associated with any given class.
#Does not reference the table name explicitly
  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end
