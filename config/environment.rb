require 'sqlite3'

# Create the database
DB = {:conn => SQLite3::Database.new("db/songs.db")}

# Drop table to avoid errors
DB[:conn].execute("DROP TABLE IF EXISTS songs")

# Create the table
sql = <<-SQL
  CREATE TABLE IF NOT EXISTS songs (
  id INTEGER PRIMARY KEY,
  name TEXT,
  album TEXT
  )
SQL

# Use results_as_hash to return the database as a hash and not as an array
# DB[:conn].execute("SELECT * FROM songs LIMIT 1") will return [[1,"Hello",25]]
# We want something like {"id"=>1, "name"=>"Hello", "album"=>"25", 0 => 1, 1 => "Hello", 2 => "25"}
DB[:conn].execute(sql)
DB[:conn].results_as_hash = true
