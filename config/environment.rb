require 'sqlite3'


DB = {:conn => SQLite3::Database.new("db/songs.db")}
#droping the table makes sure we avoid errors
DB[:conn].execute("DROP TABLE IF EXISTS songs")

sql = <<-SQL
  CREATE TABLE IF NOT EXISTS songs (
  id INTEGER PRIMARY KEY,
  name TEXT,
  album TEXT
  )
SQL

DB[:conn].execute(sql)
DB[:conn].results_as_hash = true
# the results tells the brogram that whe a select statment is executed 
#dont return it as and array but instead return it as a hash with column namesas keys 
# example as a array things would look somethin like this [[1, "Hello", "25"]]
# as a hash things will look more like this { "id"=>1, "name"=>"Hello", "album"=>"25", 0 => 1, 1 => "Hello", 2 => "25"}