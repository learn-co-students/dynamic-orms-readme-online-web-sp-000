require 'sqlite3'

#Creating the database.
#Drop 'songs' to avoid an error.
#Creating the 'songs' table.

DB = {:conn => SQLite3::Database.new("db/songs.db")}
DB[:conn].execute("DROP TABLE IF EXISTS songs")

sql = <<-SQL
  CREATE TABLE IF NOT EXISTS songs (
  id INTEGER PRIMARY KEY,
  name TEXT,
  album TEXT,
  artist TEXT,
  genre TEXT
  )
SQL

DB[:conn].execute(sql)
DB[:conn].results_as_hash = true    

#results_as_hash method says that when a SELECT statement is executed
#return it as a hash with the column names as keys - 
#rather than returning a database row as an array. 


#So, instead of DB[:conn].execute("SELECT * FROM songs LIMIT 1") returning :
#[[1, "Hello", "25"]] 

#it returns something like this:
#{"id"=>1, "name"=>"Hello", "album"=>"25", 0 => 1, 1 => "Hello", 2 => "25"}

