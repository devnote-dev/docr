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

      version ||= Library.get_versions_for(name).last
      library = Library.get name, version
      input = arguments.get("query").as_s
      query = Redoc.parse_query input
      namespace, symbol, scope = query
      types = [] of {Float32, Redoc::Type}

      unless namespace.empty?
        full_name = namespace.join "::"

        {% for type in %w[modules classes structs enums aliases annotations] %}
          Fzy.search(full_name, library.{{type.id}}.map &.full_name).each do |match|
            types << {match.score, library.{{type.id}}[match.index]}
          end
        {% end %}

        {% for type in %w[modules classes structs] %}
          library.{{type.id}}.each do |type|
            recurse_types full_name, types, type
          end
        {% end %}
      end

      if symbol
        if namespace.empty?
          {% for type in %w[methods macros] %}
            Fzy.search(symbol, library.{{type.id}}.map &.name).each do |match|
              types << {match.score, library.{{type.id}}[match.index]}
            end
          {% end %}

          {% for type in %w[modules classes structs] %}
            library.{{type.id}}.each do |type|
              recurse_methods symbol, types, type, :all
            end
          {% end %}
        else
          types.each_with_index do |type, index|
            methods = [] of {Float32, Redoc::Type}

            if scope.class?
              if type.responds_to?(:constructors)
                Fzy.search(symbol, type.constructors.map &.name).each do |match|
                  methods << {match.score, type.constructors[match.index]}
                end
              end

              if type.responds_to?(:class_methods)
                Fzy.search(symbol, type.class_methods.map &.name).each do |match|
                  methods << {match.score, type.class_methods[match.index]}
                end
              end
            else
              if type.responds_to?(:instance_methods)
                Fzy.search(symbol, type.instance_methods.map &.name).each do |match|
                  methods << {match.score, type.instance_methods[match.index]}
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

      types.sort_by! do |(score, type)|
        if type.responds_to?(:full_name)
          {score, type.full_name}
        else
          {score, type.name}
        end
      end

      stdout << types.size << " result"
      stdout << "s" if types.size > 1
      stdout << " found:\n\n"

      if options.has? "debug"
        types.reverse_each do |score, type|
          Colorize.with.dark_gray.surround(stdout) do
            stdout << '[' << score << "] "
          end
          Formatters::Default.signature stdout, type, true, false
        end
      else
        types.reverse_each do |_, type|
          Formatters::Default.signature stdout, type, true, false
        end
      end
    end

    private def recurse_types(query : String, results : Array({Float32, Redoc::Type}),
                              namespace : Redoc::Namespace) : Nil
      {% for type in %w[modules classes structs enums aliases annotations] %}
        Fzy.search(query, namespace.{{type.id}}.map &.full_name).each do |match|
          next if match.score < 1.0
          results << {match.score, namespace.{{type.id}}[match.index]}
        end
      {% end %}

      {% for type in %w[modules classes structs] %}
        namespace.{{type.id}}.each do |type|
          recurse_types query, results, type
        end
      {% end %}
    end

    private def recurse_methods(query : String, results : Array({Float32, Redoc::Type}),
                                namespace : Redoc::Namespace, scope : Redoc::QueryScope) : Nil
      if scope.all? || scope.class?
        if namespace.responds_to?(:constructors)
          Fzy.search(query, namespace.constructors.map &.name).each do |match|
            next if match.score < 2.0
            results << {match.score, namespace.constructors[match.index]}
          end
        end

        if namespace.responds_to?(:class_methods)
          Fzy.search(query, namespace.class_methods.map &.name).each do |match|
            next if match.score < 2.0
            results << {match.score, namespace.class_methods[match.index]}
          end
        end
      end

      if (scope.all? || scope.instance?) && namespace.responds_to?(:instance_methods)
        Fzy.search(query, namespace.instance_methods.map &.name).each do |match|
          next if match.score < 2.0
          results << {match.score, namespace.instance_methods[match.index]}
        end
      end

      {% for type in %w[modules classes structs] %}
        namespace.{{type.id}}.each do |type|
          recurse_methods query, results, type, scope
        end
      {% end %}
    end
  end
end
