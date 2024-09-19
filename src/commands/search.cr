module Docr::Commands
  class Search < Base
    def setup : Nil
      @name = "search"
      @summary = "search for a symbol or type"

      add_argument "library"
      add_argument "symbol"
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      super

      unless arguments.has? "input"
        arg = Cling::Argument.new "input"
        arg.value = arguments.get "library"

        arguments.hash["input"] = arg
        arguments.hash["library"].value = Cling::Value.new "crystal"
      end
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      name = arguments.get("library").as_s

      unless Library.exists? name
        error "library '#{name}' not imported"
        exit_program
      end

      version = Library.get_versions_for(name).sort.last
      project = Library.get name, version
      input = arguments.get("input").as_s
      query = Redoc.parse_query input
      namespace, symbol, kind = query

      if symbol.nil?
        types = [] of Redoc::Type

        {% for type in %w[modules classes structs enums aliases annotations] %}
          Fzy.search(input, project.{{type.id}}.map &.full_name).each do |match|
            next if match.score < 1.0
            types << project.{{type.id}}[match.index]
          end
        {% end %}

        {% for type in %w[modules classes structs] %}
          project.{{type.id}}.each do |type|
            recurse input, types, type
          end
        {% end %}
      else
        types = project.resolve_all(namespace, symbol, kind)
        if types.empty? && namespace.empty? && name == "crystal"
          namespace << "Object"
          types = project.resolve_all(namespace, symbol, kind)
        end
      end

      if types.empty?
        error "Could not resolve types or symbols for input"
        exit_program
      end

      stdout << types.size << " result"
      stdout << "s" if types.size > 1
      stdout << " found:\n\n"

      types.each do |type|
        Formatters::Default.format_signature stdout, type, false
      end
    end

    private def recurse(query : String, results : Array(Redoc::Type), namespace : Redoc::Namespace) : Nil
      {% for type in %w[modules classes structs enums aliases annotations] %}
        Fzy.search(query, namespace.{{type.id}}.map &.full_name).each do |match|
          next if match.score < 1.0
          results << namespace.{{type.id}}[match.index]
        end
      {% end %}

      {% for type in %w[modules classes structs] %}
        namespace.{{type.id}}.each do |type|
          recurse query, results, type
        end
      {% end %}
    end
  end
end
