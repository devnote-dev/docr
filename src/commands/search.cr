module Docr::Commands
  class Search < Base
    def setup : Nil
      @name = "search"
      @summary = "searches for a symbol or type"
      @description = <<-DESC
        Searches for types/namespaces and symbols in a given library. If no library is
        specified, the latest version of the Crystal standard library documentation is
        used instead.
        DESC

      add_usage "docr search [library] <type|symbol> [options]"
      add_usage "docr search [library] <type> <symbol> [options]"

      add_argument "library", description: "the name of the library"
      add_argument "type"
      add_argument "symbol"
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool
      return false unless super
      return on_missing_arguments(%w[symbol]) unless arguments.has?("library")

      library = arguments.get("library").as_s
      type = arguments.get?("type").try &.as_s
      symbol = arguments.get?("symbol").try &.as_s

      if library.matches? /\A[a-z0-9_-]+\z/
        if type.nil?
          arg = Cling::Argument.new("symbol")
          arg.value = arguments.get("library")
          arguments.hash["symbol"] = arg
          arguments.hash["library"].value = Cling::Value.new("crystal")
        end
      else
        if type.nil?
          arguments.hash["type"] = Cling::Argument.new("type")
        end

        if symbol.nil?
          arg = Cling::Argument.new("symbol")
          arg.value = arguments.get?("type")
          arguments.hash["symbol"] = arg
        end

        arguments.hash["type"].value = arguments.get("library")
        arguments.hash["library"].value = Cling::Value.new("crystal")
      end

      true
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      lib_name = arguments.get("library").as_s
      type = arguments.get?("type").try &.as_s
      symbol = arguments.get?("symbol").try &.as_s

      debug "library: #{lib_name.inspect}"
      debug "type: #{type.inspect}"
      debug "symbol: #{symbol.inspect}"

      query = Query.parse [type, symbol].reject(Nil)
      versions = Library.get_versions_for lib_name
      if versions.empty?
        format = "docr add #{lib_name} <source>".colorize.blue
        error "no documentation is available for this library"
        error "to import a version of this library, run '#{format}'"
        return
      end

      # TODO: support --version

      library = Library.fetch lib_name
      data = library.data.program
      unless query.types.empty?
        data = resolve_type data, query.types
        if data.nil? && lib_name != "crystal"
          data = resolve_type library.data.program.types.not_nil![0], query.types
        end

        if data.nil?
          return error "could not resolve types or namespaces for that symbol"
        end
      end

      results = Docr::Search.filter_types data, query.symbol
      if results.empty?
        return error "no documentation found for symbol '#{query.symbol}'"
      end

      str = String.build do |io|
        io << "Search Results:\n\n"

        results.each do |kind, result|
          case kind
          when .constant?
            result.each do |const|
              parts = const.value
              io << parts[0].colorize.blue
              parts[1..].each do |part|
                io << "::"
                io << part.colorize.blue
              end

              if source = const.source
                io << " (" << source.file << ':' << source.line << ')'
              else
                io << " (top level)"
              end

              io << '\n'
            end

            io << '\n'
          when .module?
            result.each do |mod|
              io << "module ".colorize.red
              io << mod.value[0].colorize.blue

              if source = mod.source
                io << " (" << source.file << ':' << source.line << ')'
              else
                io << " (top level)"
              end

              io << '\n'
            end
          when .class?
            result.each do |cls|
              io << "class ".colorize.red
              io << cls.value[0].colorize.blue

              if source = cls.source
                io << " (" << source.file << ':' << source.line << ')'
              else
                io << " (top level)"
              end

              io << '\n'
            end
          when .struct?
            result.each do |strct|
              io << "struct ".colorize.red
              io << strct.value[0].colorize.blue

              if source = strct.source
                io << " (" << source.file << ':' << source.line << ')'
              else
                io << " (top level)"
              end

              io << '\n'
            end
          when .enum?
            result.each do |_enum|
              io << "enum ".colorize.red
              io << _enum.value[0].colorize.blue

              if source = _enum.source
                io << " (" << source.file << ':' << source.line << ')'
              else
                io << " (top level)"
              end

              io << '\n'
            end
          when .alias?
            result.each do |_alias|
              io << "alias ".colorize.red
              io << _alias.value[0].colorize.blue

              if source = _alias.source
                io << " (" << source.file << ':' << source.line << ')'
              else
                io << " (top level)"
              end

              io << '\n'
            end
          when .def?
            result.each do |method|
              io << "def ".colorize.red
              io << method.value[0].colorize.blue

              if source = method.source
                io << " (" << source.file << ':' << source.line << ')'
              else
                io << " (unknown source)"
              end

              io << '\n'
            end
          end
        end
      end

      stdout.puts str
    end

    private def resolve_type(top : Models::Type, names : Array(String)) : Models::Type?
      return nil unless types = top.types

      types.each do |type|
        if type.name == names[0] || type.full_name == names[0]
          if names.size - 1 != 0
            return resolve_type type, names[1..]
          end

          return type
        end
      end
    end
  end

  private struct Query
    PATH_RULE   = /\A(?:[\w:!?<>+\-*\/^=~%$&`\[|\]]+)(?:(?:\.|#|\s)(?:[\w!?<>+\-*\/^=~%$&`\[|\]]+))?\z/
    MODULE_RULE = /\A\w+\z/

    getter types : Array(String)
    getter symbol : String

    def self.parse(args : Array(String))
      str = args.join ' '
      raise "invalid module or type path" unless str.matches? PATH_RULE

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

      raise "invalid symbol path" if parts.size > 2

      parts
    end

    private def self.parse_types(str : String) : Array(String)
      parts = str.split "::", remove_empty: true
      raise "invalid module or type path" unless parts.all? &.matches? MODULE_RULE
      parts
    end

    def initialize(@types, @symbol)
    end
  end
end
