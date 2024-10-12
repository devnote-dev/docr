module Docr::Commands
  class Tree < Base
    def setup : Nil
      @name = "tree"

      add_argument "library", required: true
      add_argument "symbol"
      add_option 'v', "version", type: :single
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
      library = Library.get name, version

      unless arguments.has? "symbol"
        return Formatters::Default.format_all stdout, library
      end

      query = Redoc.parse_query arguments.get("symbol").as_s
      if type = library.resolve? *query
        return Formatters::Default.format_tree stdout, type, 0
      end

      if query[0].empty? && name == "crystal"
        query[0] << "Object"
        if type = library.resolve? *query
          return Formatters::Default.format_tree stdout, type, 0
        end
      end

      error "Could not resolve types or symbols for input"
    end
  end
end
