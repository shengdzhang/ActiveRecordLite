require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where (params)
    tb = self.table_name
    value_arr = params.values
    param_string = params.keys.map! {|key| "#{key.to_s} = ?"}.join(" AND ")
    # params.each do |key, value|
    #   param_string += " AND " unless param_string == ""
    #   key_s = key.to_s
    #   param_string += "#{key_s} = ?"
    #   value_arr << value
    # end
    arr = DBConnection.execute(<<-SQL, *value_arr)
      SELECT
        *
      FROM
        #{tb}
      WHERE
        #{param_string}
    SQL
    self.parse_all(arr)
  end
end

class SQLObject
  extend Searchable
  # Mixin Searchable here...
end
