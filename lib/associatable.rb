require_relative 'searchable'
require 'active_support/inflector'
require 'byebug'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize (name, options = {})
    @name = name
    @foreign_key = options[:foreign_key] || "#{name.to_s.singularize}_id".to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.camelcase

  end
end

class HasManyOptions < AssocOptions
  def initialize (name, self_class_name, options = {})
    @name = name
    @foreign_key = options[:foreign_key] || "#{self_class_name.to_s.downcase}_id".to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.singularize.camelcase
  end
end

module Associatable
  def belongs_to (name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

      define_method(name) do
        options = self.class.assoc_options[name]
        key = self.send(options.foreign_key)
        options.model_class.where(options.primary_key => key).first
      end

  end

  def has_many (name, options = {})
    # ...
    self.assoc_options[name] = HasManyOptions.new(name, self, options)

      define_method(name) do
        options = self.class.assoc_options[name]
        key = self.send(options.primary_key)
        options.model_class.where(options.foreign_key => key)
      end

  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
