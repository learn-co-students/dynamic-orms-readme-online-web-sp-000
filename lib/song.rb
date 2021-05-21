require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

# grabs the table name we want to query for column names
  def self.table_name
    self.to_s.downcase.pluralize
  end

  # To query a table for the names of its columns
  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')" #returns array of hashes describing the table itself
    # but we just need the name of each column 

    table_info = DB[:conn].execute(sql) #this is the array and we'll iterate and the shove into 
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact #compact to not get any nil info. We get the names tha we'll use for attr_accessor
  end

  # iterate over the column names and set an attr_accessor for each one,
  #  making sure to convert the column name string into a symbol with the #to_sym method, 
  # since attr_accessors must be named with symbols.
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

# We expect #new to be called with a hash, so when we refer to options inside the #initialize method, 
# we expect to be operating on a hash.
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  # to use a class method inside an instance method 'self.class'
  def table_name_for_insert
    self.class.table_name
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  # We need to remove id cuz the database will assign the id`
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



