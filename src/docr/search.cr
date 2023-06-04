module Docr::Search
  extend self

  struct Query
    PATH_RULE   = /\A(?:[\w:!?<>+\-*\/^=~%$&`\[|\]]+)(?:(?:\.|#|\s)(?:[\w!?<>+\-*\/^=~%$&`\[|\]]+))?\z/
    MODULE_RULE = /\A\w+\z/

    getter types : Array(String)
    getter symbol : String

    def self.parse(args : Array(String))
      str = args.join ' '
      raise "Invalid module or type path" unless str.matches? PATH_RULE

      symbols = parse_symbol str
      types = [] of String
      types = parse_types symbols[0] if symbols.size == 2

      new types, symbols.last
    end

    private def self.parse_symbol(str : String?) : Array(String)
      return [] of String if str.nil?

      parts = str.split '.'
      if parts.size == 1
        parts = parts[0].split '#'
      end

      if parts.size == 1
        parts = parts[0].split ' '
      end

      raise "Invalid symbol path" if parts.size > 2

      parts
    end

    private def self.parse_types(str : String) : Array(String)
      parts = str.split "::", remove_empty: true
      raise "Invalid module or type path" unless parts.all? &.matches? MODULE_RULE
      parts
    end

    def initialize(@types, @symbol)
    end
  end

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

    getter value : Array(String)
    getter scope : String?
    getter source : Models::Location?
    getter? instance : Bool

    def initialize(@value : Array(String), @scope : String?,
                   @source : Models::Location?, @instance : Bool = false)
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
        value = type.full_name.split("::", remove_empty: true)
        Result.new(value << const.name, nil, location)
      end
    end

    {% begin %}
      {% for name in %w[constructors class_methods instance_methods] %}
        if methods = filter_{{name.id}}(type, symbol)
          results[:def] = methods.map do |method|
            value = if type.full_name == "Top Level Namespace"
                      [] of String
                    else
                      type.full_name.split("::", remove_empty: true)
                    end

            value << method.name
            if args = method.args
              value << args
            end

            Result.new(value, nil, method.location, {{ name == "instance_methods" }})
          end
        end
      {% end %}
    {% end %}

    if macros = filter_macros(type, symbol)
      results[:macro] = macros.map do |_macro|
        value = if type.full_name == "Top Level Namespace"
                  [] of String
                else
                  type.full_name.split("::", remove_empty: true)
                end

        value << _macro.name
        if args = _macro.args
          value << args
        end

        Result.new(value, nil, _macro.location)
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
          Result.new([inner.name], type.name, location)
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

  private struct Entry(T)
    getter value : T
    getter dist : Int32

    def initialize(@value, @dist)
    end
  end

  private def sort_by(target : String, subjects : Array(T), & : T -> String) : Array(T) forall T
    t = target.size / 5
    best : Entry(T)? = nil
    res = [] of Entry(T)

    subjects.each do |subject|
      dist = Levenshtein.distance target, yield subject
      if dist <= t
        if best
          if dist < best.dist
            res << best
            best = Entry(T).new(subject, dist)
          end
        else
          best = Entry(T).new(subject, dist)
          res << best
        end
      end
    end

    return [] of T if best.nil?

    res.map &.value
  end

  def filter_constants(type : Models::Type, symbol : String) : Array(Models::Constant)?
    return nil unless constants = type.constants
    return nil if constants.empty?

    sort_by(symbol, constants, &.name)
  end

  {% for name in %w[constructors class_methods instance_methods macros] %}
    def filter_{{name.id}}(type : Models::Type, symbol : String) : Array(Models::Def)?
      return nil unless methods = type.{{name.id}}
      return nil if methods.empty?

      sort_by(symbol, methods, &.name)
    end
  {% end %}

  # TODO: so this doesn't actually work as intended,
  #       reverting back to the levenshtein implementation
  #       until this can be worked out properly.

  # def filter_constants(type : Models::Type, symbol : String) : Array(Models::Constant)?
  #   return nil unless constants = type.constants
  #   return nil if constants.empty?

  #   index = Index.new do |idx|
  #     constants.each { |c| idx.add c.name }
  #   end

  #   results = index.query symbol
  #   return nil if results.empty?

  #   results.map { |i| constants[i]? }.reject(Nil)
  # end

  # {% for name in %w[constructors class_methods instance_methods macros] %}
  #   def filter_{{name.id}}(type : Models::Type, symbol : String) : Array(Models::Def)?
  #     return nil unless methods = type.{{name.id}}
  #     return nil if methods.empty?

  #     index = Index.new do |idx|
  #       methods.each { |m| idx.add m.name }
  #     end

  #     results = index.query symbol
  #     return nil if results.empty?

  #     results.map { |i| methods[i]? }.reject(Nil)
  #   end
  # {% end %}
end
