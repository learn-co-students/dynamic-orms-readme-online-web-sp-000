require_relative "../config/environment.rb"
require 'active_support/inflector'
# #pluralize method is provided to us by the active_support/inflector code library

class Song
  #note how everything is extremely abstract. nothign particular to song class. 
  #thats exactly the point
  #we can copy and paste these methods to ANY other class of objects and it would work


  def self.table_name
    self.to_s.downcase.pluralize
    #to string and pluralize. like cat class become cats. 

  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    #this return an array of hashes with a lot of stuff we dont need
    #[ {} {} {}]. how many hashes depend how many columns
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end #this grab each value of the key called "name" of each hash. 
      #process it, add it to an array

      #the compact merthod just get rid of values that are nil. we dont expect any but this is an extra step to ensure
    column_names.compact

  end # the end of the method. and the next block is a free block outside of any methods? i think so


  self.column_names.each do |col_name|
    #self.column_names is a method. it returns something.
    # we take that something and run the each method on that
    attr_accessor col_name.to_sym
  end #this is outside methods. just "out in the open"


  def initialize(options={})
  #if nothing is passed, it's an empty hash
    options.each do |property, value|
      self.send("#{property}=", value)
    end
    #this works together with the attributes. the attributes are already created with attr_accessor...
    #now u just assign values to these attributes
    #send does that(but can do other things). 
    #ex: x.send("name=", "beyonce") sets the attribute name to beyonce
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
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    #that was super cool
    #send is cool
    #how do u invoke a method if you don't know its name. cause the name is diff every time?
    #send to the rscue
    #ex: send(name) invokes song.name. we're adding the values of the attributes
    values.join(", ")
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    #ex: ["id", "name", "album"] becomes "name, album"
    end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



