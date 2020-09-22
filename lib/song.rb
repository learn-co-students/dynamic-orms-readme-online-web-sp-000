require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song


  def self.table_name
    self.to_s.downcase.pluralize
    #The #pluralize method is provided to us by the active_support/inflector code library
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
    #compact just to be safe and get rid of any nil values

    #return value: ["id", "name", "album"]
  end

  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
    #we tell our Song class that it should have an attr_accessor named after each column name
    #we iterate over the column names stored in the column_names class method and set an attr_accessor for each one, making sure to convert the column name string into a symbol with the #to_sym method, since attr_accessors must be named with symbols

  end

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def save #  **SELF will refer to instance of the class
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
    #in order to access the table name we want to INSERT into from inside save method
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    # when we INSERT a row into database table we don't INSERT id attribute

    # returns: "name", "album"
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



