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

      add_argument "query"
      add_option 'i', "include", type: :multiple
      add_option 'x', "exclude", type: :multiple
      add_option 'f', "format", type: :single
      add_option "location"
      add_option 'l', "library", type: :single, default: "crystal"
      add_option 'v', "version", type: :single
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      super

      if format = options.get?("format").try(&.as_s)
        unless format.in?("default", "signature") # TODO: impl json, csv
          error "Invalid format (valid: default, signature)"
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

      if arguments.has? "query"
        query = Redoc.parse_query arguments.get("query").as_s

        unless type = library.resolve? *query
          if query[0].empty? && name == "crystal"
            query[0] << "Object"
            type = library.resolve? *query
          end
        end

        unless type
          error "Could not resolve types or symbols for input"
          exit_program
        end
      else
        type = library
      end

      case options.get?("format").try(&.as_s)
      when Nil, "default"
        Formatters::Default.tree(stdout, type, types, options.has?("location"))
      when "signature"
        Formatters::Signature.format(stdout, type, types, options.has?("location"))
      end
    end
  end
end
