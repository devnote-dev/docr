module Docr::Commands
  class Tree < Base
    def setup : Nil
      @name = "tree"

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
        error "Library '#{name}' not imported"
        exit_program
      end

      version = Library.get_versions_for(name).sort.last
      project = Library.get name, version
      query = Redoc.parse_query arguments.get("input").as_s

      if type = project.resolve? *query
        return Formatters::Default.format_tree stdout, type, 0
      end

      if query[0].empty? && name == "crystal"
        query[0] << "Object"
        if type = project.resolve? *query
          return Formatters::Default.format_tree stdout, type, 0
        end
      end

      error "Could not resolve types or symbols for input"
    end
  end
end
