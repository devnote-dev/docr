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
          arguments.hash["library"].value = nil
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
        arguments.hash["library"].value = nil
      end

      true
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      library = arguments.get?("library").try &.as_s
      type = arguments.get?("type").try &.as_s
      symbol = arguments.get?("symbol").try &.as_s

      debug "library: #{library.inspect}"
      debug "type: #{type.inspect}"
      debug "symbol: #{symbol.inspect}"

      query = Query.parse [type, symbol].reject(Nil)

      pp query
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
