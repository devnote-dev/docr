module Docr::Formatters
  class Default
    def self.format_path(path : String, color : Colorize::ColorANSI) : String
      path
        .gsub(/([^():|, ]+)/, &.colorize(color))
        .gsub(/(\*\*?)/, &.colorize.red)
    end

    def self.signature(io : IO, type : Redoc::Const, full : Bool, with_value : Bool) : Nil
      io << format_path type.name, :blue
      if with_value
        io << " = " << type.value
      end
      io << '\n'
    end

    {% for type in %w[Module Class Struct] %}
      def self.signature(io : IO, type : Redoc::{{type.id}}, full : Bool, with_parent : Bool) : Nil
        {% unless type == "Module" %}io << "abstract ".colorize.red if type.abstract?{% end %}
        io << {{type.downcase}}.colorize.red
        io << ' ' << format_path((full ? type.full_name : type.name), :magenta)

        {% unless type == "Module" %}
          if with_parent && (parent = type.parent)
            io << " < " << format_path parent.full_name, :magenta
          end
        {% end %}
        io << '\n'
      end
    {% end %}

    def self.signature(io : IO, type : Redoc::Enum, full : Bool, with_base : Bool) : Nil
      io << "enum ".colorize.red
      io << format_path((full ? type.full_name : type.name), :magenta)

      if with_base && (base = type.type)
        io << " : " << format_path base, :magenta
      end
      io << '\n'
    end

    def self.signature(io : IO, type : Redoc::Alias, full : Bool, with_value : Bool) : Nil
      io << "alias ".colorize.red
      io << format_path((full ? type.full_name : type.name), :magenta)

      if with_value
        io << " = " << format_path type.type, :blue
      end
      io << '\n'
    end

    def self.signature(io : IO, type : Redoc::Annotation, full : Bool, __) : Nil
      io << "annotation ".colorize.red
      io << format_path((full ? type.full_name : type.name), :magenta)
      io << '\n'
    end

    def self.signature(io : IO, type : Redoc::Def, with_parent : Bool, __) : Nil
      io << "abstract ".colorize.red if type.abstract?
      io << "def ".colorize.red

      if with_parent && (parent = type.parent)
        io << format_path parent.full_name, :blue
        io << '.'
      end
      io << type.name.colorize.magenta

      unless type.params.empty?
        io << '('
        format io, type.params[0]

        if type.params.size > 1
          type.params[1..].each do |param|
            io << ", "
            format io, param
          end
        end

        io << ')'
      end

      if ret = type.return_type
        io << " : " << format_path ret, :blue
      end

      if type.generic?
        io << " forall ".colorize.red
        type.free_vars.join(io, ", ") { |v, str| str << v.colorize.blue }
      end
      io << '\n'
    end

    def self.signature(io : IO, type : Redoc::Macro, with_parent : Bool, __) : Nil
      io << "macro ".colorize.red

      if with_parent && (parent = type.parent)
        io << format_path parent.full_name, :blue
        io << '.'
      end
      io << type.name.colorize.magenta

      unless type.params.empty?
        io << '('
        format io, type.params[0]

        if type.params.size > 1
          type.params[1..].each do |param|
            io << ", "
            format io, param
          end
        end

        io << ')'
      end
      io << '\n'
    end

    def self.signature(io, type : Redoc::Type, *__) : Nil
      raise "BUG: erased method signature for #{type.class}"
    end

    private def self.format(io : IO, type : Redoc::Parameter) : Nil
      io << '*'.colorize.red if type.splat?
      io << "**".colorize.red if type.double_splat?
      io << '&'.colorize.red if type.block?
      io << type.name

      if rest = type.type
        io << " : " << rest
      end

      if value = type.default_value
        io << " = " << value
      end
    end
  end
end
