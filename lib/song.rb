#the goal of our dynamic ORM is to define a series of methods that can be shared by any class.
# So, we need to avoid explicitly referencing table and column names.

require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song


  def self.table_name #method that returns the name of a table, given the name of a class
    # takes the name of the class, referenced by the self keyword, turns it into a string with #to_s, downcases
    # (or "un-capitalizes") that string and then "pluralizes" it, or makes it plural.
    self.to_s.downcase.pluralize #The #pluralize method is provided to us by the active_support/inflector code library,
                                  #  required at the top 
  end

  def self.column_names
    # attr_accessor methods were derived from the column names of the table associated to our class.
    # Those column names are stored in the #column_names class method.
    DB[:conn].results_as_hash = true
    # PRAGMA will return to us (thanks to our handy #results_as_hash method) an array of hashes describing the table itself
    # Each hash will contain information about one column and we need to grab out the name of each column.
    # Each hash has a "name" key that points to a value of the column name

    sql = "pragma table_info('#{table_name}')"
    # we write a SQL statement using the pragma keyword and the #table_name method to access the name of the table we are querying

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row| # We iterate over the resulting array of hashes to collect just the name of each column. 
      column_names << row["name"]
    end
    column_names.compact # call #compact on that to get rid of any nil values that may end up in our collection.
  end

  self.column_names.each do |col_name| # we can use array of column names to create the attr_accessors of our Song class.
    #we iterate over the column names stored in the column_names class method and set an attr_accessor for each one
    attr_accessor col_name.to_sym # to convert the column name string into a symbol with the #to_sym method,
    # since attr_accessors must be named with symbols
  end

  # we define our method to take in an argument of options, which defaults to an empty hash.
  # We expect #new to be called with a hash, so when we refer to options inside the #initialize method,
  # we expect to be operating on a hash.
  def initialize(options={})
    options.each do |property, value| # We iterate over the options hash and use #send method to interpolate the name of
      # each hash key as a method that we set equal to that key's value.
      self.send("#{property}=", value) #invoke a method, without knowing the exact name of the method, using the #send method.
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  #save is an instance method. So, inside a #save method, self will refer to the instance of the class, 
  #not the class itself. In order to use a class method inside an instance method, we need to do the following:
  def table_name_for_insert
    self.class.table_name
  end

  def values_for_insert
    # iterate over the column names stored in #column_names and use the #send method with each individual column name
    # to invoke the method by that same name and capture the return value
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
      # we push the return value of invoking a method via the #send method, unless that value is nil
      # (as it would be for the id method before a record is saved, for instance).
      # we are wrapping the return value in a string
      # each individual value will be enclosed in single quotes, ' ', inside that string. 
      # SQL expects us to pass in each column value in single quotes
      # The above code, however, will result in a values array ["'the name of the song'", "'the album of the song'"]
      # We need comma separated values for our SQL statement. Let's join this array into a string:
    end
    values.join(", ")
  end

  def col_names_for_insert
    # when we #save our Ruby object, we should not include the id column name or insert a value for the id column.
    # Therefore, we need to remove "id" from the array of column names
    # Our column names returned are in an array. Let's turn them into a comma separated list, contained in a string by .join(", ")
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    # Now we have all the code we need to grab a comma separated list of the column names of the table associated with any
    # given class.
  end

  def self.find_by_name(name)
    # This method is dynamic and abstract because it does not reference the table name explicitly.
    # Instead it uses the #table_name class method we built that will return the table name associated with any given class.
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end


