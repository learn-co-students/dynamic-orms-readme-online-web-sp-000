require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

  # creates table name dynamically
  def self.table_name
    self.to_s.downcase.pluralize
  end

  # use column_names of the songs table to create attr_accessors
  # query table for column names; PRAGMA returns array of hashes describing the table
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

  # telling our class that it should have attr_accessors named after each column name
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  # should take in a hash of named/keyword arguments
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  # abstracted to not call on any specific tables or columns
  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  # using a class method inside an instance method
  # calls table_name method on the class
  def table_name_for_insert
    self.class.table_name
  end

  # grabbing values via the column names 
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end
