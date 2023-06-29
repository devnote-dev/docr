module Docr::Commands
  class Info < Base
    def setup : Nil
      @name = "info"
      @summary = "gets information about a symbol"
      @description = <<-DESC
        Gets information about a specified type/namespace or symbol. This supports
        Crystal path syntax, meaning the following commands are valid:

        • docr info JSON::Any.as_s
        • docr info JSON::Any#as_s
        • docr info JSON::Any as_s

        However, the following commands are not valid:

        • docr info JSON Any as_s
        • docr info JSON Any.as_s
        • docr info JSON Any#as_s

        This is because the first argument is parsed as the base type or namespace to
        look in, and the second argument is parsed as the symbol to look for. In the
        first example, JSON::Any is the namespace and as_s the symbol, whereas in the
        second example, JSON is the namespace and Any as_s is the symbol, which is
        invalid. This doesn't mean you have to specify the namespace of a symbol, Docr
        can determine whether an argument is a type/namespace or symbol and handle
        it accordingly.
        DESC

      add_argument "library"
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

      query = Docr::Search::Query.parse [type, symbol].reject(Nil)
      versions = Library.get_versions_for lib_name

      if versions.empty?
        format = "docr add #{lib_name} <source>".colorize.blue
        error "No documentation is available for this library"
        error "To import a version of this library, run '#{format}'"
        return
      end

      # TODO: support --version

      library = Library.fetch lib_name
      data = res = library.data.program

      unless query.types.empty?
        res = resolve_type data, query.types
        if res.nil? && lib_name != "crystal"
          res = resolve_type(data.types.as(Array)[0], query.types)
        end

        if res.nil?
          return error "Could not resolve types or namespaces for that symbol"
        end
      end

      tree = Docr::Search.filter_type_tree(res.as(Models::Type), query.symbol)

      case
      when tree.constants.any?
        stdout.puts Formatters::Default.format tree.constants
      when tree.modules.any?
        stdout.puts Formatters::Default.format modules: tree.modules
      when tree.classes.any?
        stdout.puts Formatters::Default.format classes: tree.classes
      when tree.structs.any?
        stdout.puts Formatters::Default.format structs: tree.structs
      when tree.enums.any?
        stdout.puts Formatters::Default.format enums: tree.enums
      when tree.aliases.any?
        stdout.puts Formatters::Default.format aliases: tree.aliases
      when tree.annotations.any?
        stdout.puts Formatters::Default.format annotations: tree.annotations
      when tree.defs.any?
        stdout.puts Formatters::Default.format defs: tree.defs
      when tree.macros.any?
        stdout.puts Formatters::Default.format macros: tree.macros
      else
        error "No documentation found for symbol '#{query.symbol}'"
      end
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
end
