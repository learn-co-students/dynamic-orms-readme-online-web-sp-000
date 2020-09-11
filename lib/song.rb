require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song


  def self.table_name
    self.to_s.downcase.pluralize
    #Song -> turns it into a string -> lowers all the letters -> makes it plural
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"
  #example of a return
  #   [{"cid"=>0,
  #   "name"=>"id",
  #   "type"=>"INTEGER",
  #   "notnull"=>0,
  #   "dflt_value"=>nil,
  #   "pk"=>1,
  #   0=>0,
  #   1=>"id",
  #   2=>"INTEGER",
  #   3=>0,
  #   4=>nil,
  #   5=>1},
  #  {"cid"=>1,
  #   "name"=>"name",
  #   "type"=>"TEXT",
  #   "notnull"=>0,
  #   "dflt_value"=>nil,
  #   "pk"=>0,
  #   0=>1,
  #   1=>"name",
  #   2=>"TEXT",
  #   3=>0,
  #   4=>nil,
  #   5=>0}]
  # That's a lot of information! The only thing we need to grab out of this hash
  #  is the name of each column. Each hash has a "name" key that points to a value of the column name.
  #let's name this return as table_info
    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
    #We call #compact on that just to be safe and get rid 
    #of any nil values that may end up in our collection.
    #The return value of calling Song.column_names will therefore be:
    #["id", "name", "album"]
  end

  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end
  #Above, we iterate over the column names stored in the column_names class method and set an attr_accessor for each one,
  #making sure to convert the column name string into a symbol with the 
  #to_sym method, since attr_accessors must be named with symbols.

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end
  #use our fancy metaprogramming #send method 
  #to interpolate the name of each hash key as a method 
  #that we set equal to that key's value.


  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end
  #Following table_name_for_insert code inside of a method we can do
  #self.class.column_names
  #and the return would be
  #["id", "name", "album"]
  #There's one problem though. When we INSERT a row into a database table for the first time,
  # we don't INSERT the id attribute. 
  #In fact, our Ruby object has an id of nil before it is inserted into the table. 
  #The magic of our SQL database handles the creation of an ID for a given table row 
  #and then we will use that ID to assign a value to the original object's id attribute.

  #So, when we save our Ruby object, we should not include the id column name or insert a value for the id column. 
  #Therefore, we need to remove "id" from the array of column names returned from the method call above:
  #This will return:
  #["name", "album"]
  #then we write .join(", ")
  #will return "name, album"


  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end
  #we are getting value items from column_names(the attr_accessor)
  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end
 # Recall, however, that the conventional #save is an instance method.
 # So, inside a #save method, self will refer to the instance of the class,
 # and not the class itself. In order to use a class method inside an instance method,
 # we need to do the following:

   def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end
  def self.drop_table
    sql = "DROP TABLE IF EXISTS #{self.table_name}"
    DB[:conn].execute(sql)
  end

end



