module Docr::Commands
  class Tree < Base
    private TYPES = %w[
      const constants
      modules classes structs
      enums
      aliases
      anno annotations
      defs macros
    ]

    def setup : Nil
      @name = "tree"

      add_argument "library", required: true
      add_argument "symbol"
      add_option 'i', "include", type: :multiple
      add_option 'x', "exclude", type: :multiple
      add_option 'f', "format", type: :single
      add_option 'l', "location"
      add_option 'v', "version", type: :single
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      super

      if format = options.get?("format").try(&.as_s)
        unless format.in?("default", "json") # TODO: impl json, csv, signature
          error "Invalid format (valid: default, json)"
          exit_program
        end
      end

      invalid = [] of String

      if includes = options.get?("include").try(&.as_a)
        invalid.concat includes.reject { |i| i.in?(TYPES) || i == "all" }
      end

      if excludes = options.get?("exclude").try(&.as_a)
        invalid.concat excludes.reject { |e| e.in?(TYPES) || e == "all" }
      end

      unless invalid.empty?
        warn "Ignoring unknown types:"
        warn " #{invalid.join(", ")}"
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
      library = Library.get name, version
      types = TYPES.dup

      if excludes = options.get?("exclude").try(&.as_a)
        if excludes.includes? "all"
          types.clear
        else
          types.reject! &.in? excludes
        end
      end

      if includes = options.get?("include").try(&.as_a)
        if includes.includes? "all"
          types.replace TYPES
        else
          types.concat TYPES.select &.in? includes
        end
      end

      unless arguments.has? "symbol"
        return Formatters::Default.tree(stdout, library, types)
      end

      query = Redoc.parse_query arguments.get("symbol").as_s
      if type = library.resolve? *query
        return Formatters::Default.tree(stdout, type, types)
      end

      if query[0].empty? && name == "crystal"
        query[0] << "Object"
        if type = library.resolve? *query
          return Formatters::Default.tree(stdout, type, types)
        end
      end

      error "Could not resolve types or symbols for input"
    end
  end
end
