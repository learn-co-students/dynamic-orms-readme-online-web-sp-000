require_relative "../config/environment.rb"
require 'active_support/inflector' # => ruby gem that allows for .pluralize operator.
require 'pry'
class Song


  def self.table_name
    self.to_s.downcase.pluralize # => converts the class name into a table name... 'Song' turns into 'songs'.

  end

  def self.column_names
    DB[:conn].results_as_hash = true           # => converts the db row into a hash with key:value pairs matching column headers and cell values.

    sql = "pragma table_info('#{table_name}')" # => returns all the variables (in hash form), including column headers, data types, etc...
    table_info = DB[:conn].execute(sql)        # => saves the PRAGMA hash to the table_info variable.
    column_names = []
    table_info.each do |row|                   # => iterates over the table_info varibale and pushes the "name" key:value pair into the 'column_names' variable.
      column_names << row["name"]
    end
    binding.pry
    column_names.compact                       # => compact is called to ensure the column_names array is clean.
  end

  self.column_names.each do |col_name|         # => builds the attr_accessors by iterating over the column_names method array.
    attr_accessor col_name.to_sym
  end

  def initialize(options={})                  # => Is set to an empty hash, prompting the treatment of the initialize method to be with a hash.
    # binding.pry
    options.each do |property, value|         # => takes in a hash of keyword arguments from the 'options' hash input.
      self.send("#{property}=", value)        # => populates the attr_accessor's with the values from the options hash.
    end
  end

  def save                                    # => conventional save method for ORM, but uses the 'table_name_for_insert', 'values_for_insert', and 'col_names_for_insert' methods to load the variable data.
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert                   # => presents the table name in a method for agile use.
    # binding.pry
    self.class.table_name
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?  # => loads the values array with the associated values held in each col_name reader method (as per the attr_accessor method)
      binding.pry
    end
    values.join(", ")                         # => formats the values_for_insert to be compatible with the save method.
  end

  def col_names_for_insert                    # => formats the column names as a string WITHOUT THE ID for inputting into the database.
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end
