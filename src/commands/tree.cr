module Docr::Commands
  class Tree < Base
    def setup : Nil
      @name = "tree"

      add_argument "library"
      add_argument "symbol"
      add_option 'v', "version", type: :single
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
