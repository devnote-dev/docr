module Docr::Search
  extend self

  struct Result
    enum Kind
      Constant
      Module
      Class
      Struct
      Enum
      Alias
      Def
      Macro
    end

    getter name : String
    getter scope : String?
    getter source : Models::Location?

    def initialize(@name : String, @scope : String?, @source : Models::Location?)
    end
  end

  def filter_types(type : Models::Type, symbol : String) : Hash(Result::Kind, Array(Result))
    results = {} of Result::Kind => Array(Result)

    if constants = filter_constants(type, symbol)
      location : Models::Location? = nil
      if type.name != "Top Level Namespace" && !type.locations.empty?
        location = type.locations.first
      end

      results[:constant] = constants.map do |const|
        Result.new(const.name, nil, location)
      end
    end

    {% begin %}
      {% for name in %w[constructors class_methods instance_methods] %}
        if methods = filter_{{name.id}}(type, symbol)
          results[:def] = methods.map do |method|
            Result.new(method.name, nil, method.location)
          end
        end
      {% end %}
    {% end %}

    if macros = filter_macros(type, symbol)
      results[:macro] = macros.map do |_macro|
        Result.new(_macro.name, nil, _macro.location)
      end
    end

    return results unless types = type.types
    return results if types.empty?

    types.each do |inner|
      if inner.name == symbol || inner.full_name == symbol
        kind = case inner.kind
               when "module" then Result::Kind::Module
               when "class"  then Result::Kind::Class
               when "struct" then Result::Kind::Struct
               when "enum"   then Result::Kind::Enum
               when "alias"  then Result::Kind::Alias
               else               raise "unknown type '#{inner.kind}'"
               end

        results[kind] = inner.locations.map do |location|
          Result.new(inner.name, type.name, location)
        end

        next
      end

      filter_types(inner, symbol).each do |k, v|
        if results.has_key? k
          results[k] += v
        else
          results[k] = v
        end
      end
    end

    results
  end

  def filter_constants(type : Models::Type, symbol : String) : Array(Models::Constant)?
    return nil unless constants = type.constants
    return nil if constants.empty?

    index = Index.new do |index|
      constants.each { |c| index.add c.name }
    end

    results = index.query symbol
    return nil if results.empty?

    results.map { |i| constants[i] }
  end

  {% for name in %w[constructors class_methods instance_methods macros] %}
    def filter_{{name.id}}(type : Models::Type, symbol : String) : Array(Models::Def)?
      return nil unless methods = type.{{name.id}}
      return nil if methods.empty?

      index = Index.new do |index|
        methods.each { |m| index.add m.name }
      end

      results = index.query symbol
      return nil if results.empty?

      results.map { |i| methods[i]? }.reject(Nil)
    end
  {% end %}
end
