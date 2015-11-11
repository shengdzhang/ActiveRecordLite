require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    tb = self.table_name
    col_hash = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{tb}
    SQL
    col_arr = col_hash.first.map do |key|
      key.to_sym
    end
    col_arr
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        self.attributes[column]
      end

      define_method("#{column}=") do |value|
        self.attributes[column] = value
      end
    end
  end

  def self.table_name= (table_name)
    instance_variable_set("@table_name", table_name)
  end

  def self.table_name
    temp = instance_variable_get("@table_name")
    temp ||= self.to_s.tableize
  end

  def self.all
    tb = self.table_name
    all = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{tb}
    SQL

    self.parse_all(all)
  end

  def self.parse_all (results)
    arr = []
    results.each do |hash|
      arr << self.new(hash)
    end
    arr
  end

  def self.find (id)
    tb = self.table_name
    entry = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{tb}
      WHERE
        #{tb}.id = ?
    SQL

    self.parse_all(entry).first
  end

  def initialize (params = {})
    params.each do |attr_name, value|
      attr_sym = attr_name.to_sym
      c = self.class.columns
      raise "unknown attribute '#{attr_name}'" unless c.include?(attr_sym)
      self.send("#{attr_sym}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map{|column| self.send("#{column}")}
    # self.attributes.values
  end

  def insert
    tb = self.class.table_name
    col_names = self.class.columns.drop(1)
    cols = col_names.join(", ")
    question_marks = (["?"]*col_names.length).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO
        #{tb} (#{cols})
      VALUES
        (#{question_marks})
    SQL

    new_id = DBConnection.last_insert_row_id
    self.id = new_id

  end

  def update
    tb = self.class.table_name
    col_names = self.class.columns.drop(1)
    col_names.map! {|attr_name| "#{attr_name} = ?"}
    col_names = col_names.join(", ")
    idx = attribute_values.first
    fixed_attribute_values = attribute_values.drop(1) + [idx]
    DBConnection.execute(<<-SQL, *fixed_attribute_values)
      UPDATE
        #{tb}
      SET
        #{col_names}
      WHERE
        id = ?
    SQL

    new_id = DBConnection.last_insert_row_id
    self.id = new_id
  end

  def save
    if self.id
      self.update
    else
      self.insert
    end
  end
end
