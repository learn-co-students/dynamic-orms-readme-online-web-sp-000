require_relative "../config/environment.rb"
require 'active_support/inflector'
require"pry"
class Song


  def self.table_name
    self.to_s.downcase.pluralize
    #this method returns the name of the table givin a particular class
    #so it takes the Song class in this instence in refrence too the self keyword
    #turns it into a string using to_s downcases that string and then pluralizes it Song becomes songs 
    #in refrence to our table !!!!remember that we always want to name our db table as a plural form of our class
    # A Bird Class would have birds as the table name in order for plural command to work however we must utilize
    # require 'active_support/inflector' in order for this to work. 
  end

  def self.column_names
    # start by turn our info from array format to hash format 
    DB[:conn].results_as_hash = true
    sql = "pragma table_info('#{table_name}')"
#Pragma along with the results as a  hash return a comprehinsive 
#list of the values in the db and additiol information on the column    
table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    #the .compact get ride of any nil values from are returned collection
    column_names.compact
    # At this point if we where to call Song.column_names we would get ["id", "name", "album"]
  end

# Here with the self.columns.each do whe are interating over we are setting a attr acessor for each name stored 
# frome the the previouse colums name class method  and convert every one of the sting names into a symbol 
# using to_sym this is considerd metaprogramming because we are wrighting code that wrights code for use and our attr read and wright is
# being dynamiclly created
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

# in this portion of code we are creating a INtilize method that like everything else in this code is dynamic(wrights code for us)
# i will break this portion down as detailed as I can to provied better clearity   
def initialize(options={})
#In this we def or intitialize with a enpty options hash option={}
   options.each do |property, value|
# next we  interate  over everything in our options hash which write this code
# assuming the the .new method will becaould and data from this .new witll be 
 #inserted into the the empty options hash    
    self.send("#{property}=", value)
  # finally we use the send method to insert the name of each hash key (from the key value pais created earlier by the column name method)
  #  As long as each property has a corresponding attr_accessor, this #initialize method will work.
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
     # Here, we push the return value of invoking a method via the #send method, unless that value is nil
     #(as it would be for the id method before a record is saved, for instance).

      values << "'#{send(col_name)}'" unless send(col_name).nil?
     # Notice that we are wrapping the return value in a string. That is because we are trying to craft
     # a string of SQL. Also notice that each individual value will be enclosed in single quotes, ' ', 
     #inside that string. That is because the final SQL string will need to look like this:

    #INSERT INTO songs (name, album)
     #VALUES 'Hello', '25';
    end
    #We need comma separated values for our SQL statement. Let's join this array into a string: so we use 
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



