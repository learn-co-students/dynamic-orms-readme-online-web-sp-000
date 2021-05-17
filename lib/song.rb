require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

  #method converts class name to table name
  def self.table_name
    self.to_s.downcase.pluralize
  end

  #method reads table for and stores column names
  #compact gets rid of any nil values that may appear
  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  #tells the class to have an attr_accessor for every column name
  #metaprogramming example (code that writes code for us)
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  #we expect #new to be called with a hash, so we default to an empty hash "options"
  #send method allows you to set the keys in the option hash
  #property will correlate to an attr_accessor
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  #instance method using class methods
  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  #grabs table names from the Song class
  def table_name_for_insert
    self.class.table_name
  end


  #return value is a string for SQL
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  #grabs column names from Song class. removes id since it is nil as a ruby object (assigned via sql)
  #join takes it from comma separated array to a string
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



