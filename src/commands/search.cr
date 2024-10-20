module Docr::Commands
  class Search < Base
    def setup : Nil
      @name = "search"
      @summary = "search for a symbol or type"

      add_argument "query", required: true
      add_option 'l', "library", type: :single, default: "crystal"
      add_option 'v', "version", type: :single
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      name = options.get("library").as_s
      version = options.get?("version").try &.as_s

      unless Library.exists?(name, version)
        if version
          if Library.exists?(name)
            error "Version '#{version}' of #{name} not found or imported"
            exit_program
          end
        end

        error "Library '#{name}' not imported"
        exit_program
      end

      version ||= Library.get_versions_for(name).sort.last
      library = Library.get name, version
      input = arguments.get("query").as_s
      query = Redoc.parse_query input
      namespace, symbol, scope = query
      types = [] of Redoc::Type

      unless namespace.empty?
        full_name = namespace.join "::"

        {% for type in %w[modules classes structs enums aliases annotations] %}
          Fzy.search(full_name, library.{{type.id}}.map &.full_name).each do |match|
            # types << {match.score, library.{{type.id}}[match.index]}
            types << library.{{type.id}}[match.index]
          end
        {% end %}

        {% for type in %w[modules classes structs] %}
          library.{{type.id}}.each do |type|
            recurse full_name, types, type
          end
        {% end %}
      end

      if symbol
        if namespace.empty?
          {% for type in %w[methods macros] %}
            Fzy.search(symbol, library.{{type.id}}.map &.name).each do |match|
              # types << {match.score, library.{{type.id}}[match.index]}
              types << library.{{type.id}}[match.index]
            end
          {% end %}

          {% for type in %w[modules classes structs] %}
            library.{{type.id}}.each do |type|
              recurse symbol, types, type
            end
          {% end %}
        else
          types.each_with_index do |type, index|
            methods = [] of Redoc::Type

            if scope.class?
              if type.responds_to?(:constructors)
                Fzy.search(symbol, type.constructors.map &.name).each do |match|
                  # methods << {match.score, type.constructors[match.index]}
                  methods << type.constructors[match.index]
                end
              end

              if type.responds_to?(:class_methods)
                Fzy.search(symbol, type.class_methods.map &.name).each do |match|
                  # methods << {match.score, type.class_methods[match.index]}
                  methods << type.class_methods[match.index]
                end
              end
            else
              if type.responds_to?(:instance_methods)
                Fzy.search(symbol, type.instance_methods.map &.name).each do |match|
                  # methods << {match.score, type.instance_methods[match.index]}
                  methods << type.instance_methods[match.index]
                end
              end
            end

            unless methods.empty?
              types.insert_all index + 1, methods
            end
            types.delete_at index
          end
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
        Formatters::Default.signature stdout, type, true, false
      end
    end

    # TODO: sort by score
    private def recurse(query : String, results : Array(Redoc::Type), namespace : Redoc::Namespace) : Nil
      {% for type in %w[modules classes structs enums aliases annotations] %}
        Fzy.search(query, namespace.{{type.id}}.map &.full_name).each do |match|
          next if match.score < 1.0
          # results << {match.score, namespace.{{type.id}}[match.index]}
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
