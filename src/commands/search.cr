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

      add_usage "docr search [library] <symbol|type> [options]"
      add_usage "docr search [library] <type> <symbol> [options]"

      add_argument "library", description: "the name of the library"
      add_argument "symbol"
      add_argument "type"
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool
      return false unless super
      return on_missing_arguments(%w[symbol]) unless arguments.has?("library")

      library = arguments.get("library").as_s
      symbol = arguments.get?("symbol").try &.as_s
      type = arguments.get?("type").try &.as_s

      if library.matches? /\A[a-z0-9_-]+\z/
        if symbol.nil?
          arg = Cling::Argument.new("symbol")
          arg.value = arguments.get("library")
          arguments.hash["symbol"] = arg
          arguments.hash["library"].value = nil
        end
      else
        if symbol.nil?
          arguments.hash["symbol"] = Cling::Argument.new("symbol")
        end

        if type.nil?
          arg = Cling::Argument.new("type")
          arg.value = arguments.get?("symbol")
          arguments.hash["type"] = arg
        end

        arguments.hash["symbol"].value = arguments.get("library")
        arguments.hash["library"].value = nil
      end

      true
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      stdout.puts [arguments.get?("library"), arguments.get("symbol"), arguments.get?("type")]
    end
  end
end
