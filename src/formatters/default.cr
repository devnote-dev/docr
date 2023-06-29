module Docr::Formatters::Default
  extend self

  def format(consts : Array(Models::Constant)) : String
    const = consts[0]

    String.build do |io|
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
  end

  def format(*, modules : Array(Models::Type)) : String
    mod = modules[0]

    String.build do |io|
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
  end

  def format(*, classes : Array(Models::Type)) : String
    cls = classes[0]

    String.build do |io|
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
  end

  def format(*, structs : Array(Models::Type)) : String
    _struct = structs[0]

    String.build do |io|
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
  end

  def format(*, enums : Array(Models::Type)) : String
    _enum = enums[0]

    String.build do |io|
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
  end

  def format(*, aliases : Array(Models::Type)) : String
    _alias = aliases[0]

    String.build do |io|
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
  end

  def format(*, annotations : Array(Models::Type)) : String
    ann = annotations[0]

    String.build do |io|
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
  end

  def format(*, defs : Array(Models::Def)) : String
    method = defs[0]

    String.build do |io|
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
  end

  def format(*, macros : Array(Models::Def)) : String
    method = macros[0]

    String.build do |io|
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
  end
end
