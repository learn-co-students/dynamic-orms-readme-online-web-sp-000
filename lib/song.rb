require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class Song


  def self.table_name
    self.to_s.downcase.pluralize
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
  end

  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def save
    binding.pry
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    sql2 = "SELECT * FROM #{table_name_for_insert} WHERE #{self.class.column_names[1]} AND #{col_names_for_insert[2]}"
    DB[:conn].execute(sql) unless 
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  def values_for_insert
    # binding.pry
    values = []
    self.class.column_names.each do |name|
      values << "'#{send(name)}'" unless send(name).nil?
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



