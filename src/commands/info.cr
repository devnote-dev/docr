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
        elsif symbol.nil?
          arg = Cling::Argument.new("symbol")
          arg.value = arguments.get?("type")
          arguments.hash["symbol"] = arg
          arguments.hash["type"].value = arguments.get("library")
        else
          value = arguments.get("library").as_s + " " + arguments.get("type").as_s
          arguments.hash["type"].value = Cling::Value.new(value)
        end

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
      when tree.constants.any?   then format tree.constants
      when tree.modules.any?     then format modules: tree.modules
      when tree.classes.any?     then format classes: tree.classes
      when tree.structs.any?     then format structs: tree.structs
      when tree.enums.any?       then format enums: tree.enums
      when tree.aliases.any?     then format aliases: tree.aliases
      when tree.annotations.any? then format annotations: tree.annotations
      when tree.defs.any?        then format defs: tree.defs
      when tree.macros.any?      then format macros: tree.macros
      else                            error "No documentation found for symbol '#{query.symbol}'"
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

    private def format(consts : Array(Models::Constant)) : Nil
      const = consts[0]

      str = String.build do |io|
        io << const.name.colorize.blue
        io << " = " << const.value << "\n\n"

        if summary = const.summary
          io << summary << "\n\n"
        end

        io << "Defined:\n"
        io << " (cannot resolve location)\n".colorize.light_gray # TODO

        if doc = const.doc
          io << '\n' << doc << '\n'
        end
      end

      stdout.puts str
    end

    private def format(*, modules : Array(Models::Type)) : Nil
      mod = modules[0]

      str = String.build do |io|
        io << "module ".colorize.red
        io << mod.full_name.colorize.blue << '\n'

        if included = mod.included
          included.each do |type|
            io << "  include ".colorize.red
            io << type.full_name << '\n'
          end
          io << "end".colorize.red
        end

        if summary = mod.summary
          io << '\n' << summary << '\n'
        end

        io << "\nDefined:\n"
        mod.locations.each do |loc|
          io << "• " << loc.file << ':' << loc.line << '\n'
        end

        if methods = mod.class_methods
          io << "\nMethods: " << methods.size << '\n'
        end

        if doc = mod.doc
          io << '\n' << doc << '\n'
        end
      end

      stdout.puts str
    end

    private def format(*, classes : Array(Models::Type)) : Nil
      cls = classes[0]

      str = String.build do |io|
        io << "abstract ".colorize.red if cls.abstract?
        io << "class ".colorize.red
        io << cls.full_name.colorize.blue

        if parent = cls.superclass
          io << " < " << parent.full_name.colorize.blue
        end

        io << '\n'
        if summary = cls.summary
          io << '\n' << summary << '\n'
        end

        io << "\nDefined:\n"
        cls.locations.each do |loc|
          io << "• " << loc.file << ':' << loc.line << '\n'
        end

        io << "\nConstructors: " << cls.constructors.try(&.size) || 0
        io << "\nClass Methods: " << cls.class_methods.try(&.size) || 0
        io << "\nInstance Methods: " << cls.instance_methods.try(&.size) || 0
        io << "\nMacros: " << cls.macros.try(&.size) || 0
        io << '\n'

        if doc = cls.doc
          io << '\n' << doc << '\n'
        end
      end

      stdout.puts str
    end

    private def format(*, structs : Array(Models::Type)) : Nil
      _struct = structs[0]

      str = String.build do |io|
        io << "abstract ".colorize.red if _struct.abstract?
        io << "struct ".colorize.red
        io << _struct.full_name.colorize.blue

        if parent = _struct.superclass
          io << " < " << parent.full_name.colorize.blue
        end

        io << '\n'
        if summary = _struct.summary
          io << '\n' << summary << '\n'
        end

        io << "\nDefined:\n"
        _struct.locations.each do |loc|
          io << "• " << loc.file << ':' << loc.line << '\n'
        end

        io << "\nConstructors: " << _struct.constructors.try(&.size) || 0
        io << "\nClass Methods: " << _struct.class_methods.try(&.size) || 0
        io << "\nInstance Methods: " << _struct.instance_methods.try(&.size) || 0
        io << "\nMacros: " << _struct.macros.try(&.size) || 0
        io << '\n'

        if doc = _struct.doc
          io << '\n' << doc << '\n'
        end
      end

      stdout.puts str
    end

    private def format(*, enums : Array(Models::Type)) : Nil
      _enum = enums[0]

      str = String.build do |io|
        io << "enum ".colorize.red
        io << _enum.full_name.colorize.blue << '\n'

        if summary = _enum.summary
          io << '\n' << summary << '\n'
        end

        io << "\nDefined:\n"
        _enum.locations.each do |loc|
          io << "• " << loc.file << ':' << loc.line << '\n'
        end

        io << "\nConstructors: " << _enum.constructors.try(&.size) || 0
        io << "\nClass Methods: " << _enum.class_methods.try(&.size) || 0
        io << "\nInstance Methods: " << _enum.instance_methods.try(&.size) || 0
        io << "\nMacros: " << _enum.macros.try(&.size) || 0
        io << '\n'

        if doc = _enum.doc
          io << '\n' << doc << '\n'
        end
      end

      stdout.puts str
    end

    private def format(*, aliases : Array(Models::Type)) : Nil
      _alias = aliases[0]

      str = String.build do |io|
        io << "alias ".colorize.red
        io << _alias.full_name.colorize.blue
        io << " = " << _alias.aliased << '\n'

        if summary = _alias.summary
          io << '\n' << summary << '\n'
        end

        io << "\nDefined:\n"
        _alias.locations.each do |loc|
          io << "• " << loc.file << ':' << loc.line << '\n'
        end

        if doc = _alias.doc
          io << '\n' << doc << '\n'
        end
      end

      stdout.puts str
    end

    private def format(*, annotations : Array(Models::Type)) : Nil
      ann = annotations[0]

      str = String.build do |io|
        io << "annotation ".colorize.red
        io << ann.full_name.colorize.blue << '\n'

        if summary = ann.summary
          io << '\n' << summary << '\n'
        end

        io << "\nDefined:\n"
        ann.locations.each do |loc|
          io << "• " << loc.file << ':' << loc.line << '\n'
        end

        if doc = ann.doc
          io << '\n' << doc << '\n'
        end
      end

      stdout.puts str
    end

    private def format(*, defs : Array(Models::Def)) : Nil
      method = defs[0]

      str = String.build do |io|
        io << "abstract ".colorize.red if method.abstract?
        io << "def ".colorize.red
        io << method.name.colorize.magenta
        io << method.args if method.args
        io << '\n'

        if summary = method.summary
          io << '\n' << summary << '\n'
        end

        io << "\nDefined:"
        if loc = method.location
          io << "\n• " << loc.file << ':' << loc.line << '\n'
        else
          io << "\n (cannot resolve location)\n".colorize.light_gray
        end

        if doc = method.doc
          io << '\n' << doc << '\n'
        end
      end

      stdout.puts str
    end

    private def format(*, macros : Array(Models::Def)) : Nil
      method = macros[0]

      str = String.build do |io|
        io << "macro ".colorize.red
        io << method.name.colorize.magenta
        io << method.args if method.args
        io << '\n'

        if summary = method.summary
          io << '\n' << summary << '\n'
        end

        io << "\nDefined:"
        if loc = method.location
          io << "\n• " << loc.file << ':' << loc.line << '\n'
        else
          io << "\n (cannot resolve location)\n".colorize.light_gray
        end

        if doc = method.doc
          io << '\n' << doc << '\n'
        end
      end

      stdout.puts str
    end
  end
end
