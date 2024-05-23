module Docr::Commands
  class Search < Base
    def setup : Nil
      @name = "search"
      @summary = "search for a symbol or type"

      add_argument "library"
      add_argument "symbol"
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
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
      namespace, symbol, kind = Redoc.parse_query arguments.get("input").as_s

      if symbol.nil?
        if type = project.resolve?(namespace, nil, kind)
          pp type
          exit_program 0
        end

        if namespace.empty? && name == "crystal"
          namespace << "Object"
          if type = project.resolve?(namespace, nil, kind)
            pp type
            exit_program 0
          end
        end
      else
        methods = project.resolve_all(namespace, symbol, kind) rescue [] of Redoc::Type
        if methods.empty?
          if namespace.empty? && name == "crystal"
            namespace << "Object"
            methods = project.resolve_all(namespace, symbol, kind) rescue [] of Redoc::Type
          end
        end

        unless methods.empty?
          pp methods
          exit_program 0
        end
      end

      error "could not resolve types or symbols for input"
    end
  end
end
