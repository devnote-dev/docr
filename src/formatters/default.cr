module Docr::Formatters::Default
  def self.format_tree(io : IO, type : Redoc::Const, with_parent : Bool) : Nil
    format_signature io, type, false
  end

  def self.format_namespace(io : IO, type : Redoc::Namespace, indent : Int32) : Nil
    {% for type in %w[constants modules classes structs enums aliases annotations] %}
      unless type.{{type.id}}.empty?
        type.{{type.id}}.each do |%type|
          io << (" " * indent)
          format_tree io, %type, indent
        end
        io << '\n'
      end
    {% end %}
  end

  {% for type in %w[Module Class Struct] %}
    def self.format_tree(io : IO, type : Redoc::{{type.id}}, indent : Int32) : Nil
      format_signature io, type, true
      indent += 2

      unless type.includes.empty?
        type.includes.each do |ref|
          io << (" " * indent)
          io << "include ".colorize.red
          format_path io, ref.full_name, :magenta
          io << '\n'
        end
        io << '\n'
      end

      unless type.extends.empty?
        type.extends.each do |ref|
          io << (" " * indent)
          io << "extend ".colorize.red

          if ref.full_name == type.full_name
            io << "self".colorize.blue
          else
            format_path io, ref.full_name, :magenta
          end

          io << '\n'
        end
      end

      format_namespace io, type, indent

      type.class_methods.each do |method|
        io << (" " * indent)
        format_tree io, method, indent
      end

      {% unless type == "Module" %}
        unless type.constructors.empty?
          type.constructors.each do |method|
            io << (" " * indent)
            format_tree io, method, indent
          end
          io << '\n'
        end
      {% end %}

      type.instance_methods.each do |method|
        io << (" " * indent)
        format_tree io, method, indent
      end

      type.macros.each do |method|
        io << (" " * indent)
        format_tree io, method, indent
      end

      indent -= 2
      io << (" " * indent) << "end\n".colorize.red
    end
  {% end %}

  def self.format_tree(io : IO, type : Redoc::Enum, indent : Int32) : Nil
    format_signature io, type, true
    indent += 2

    type.constants.each do |const|
      io << (" " * indent)
      format_signature io, const, false
      io << '\n'
    end

    indent -= 2
    io << (" " * indent) << "end\n".colorize.red
  end

  def self.format_tree(io : IO, type : Redoc::Alias, indent : Int32) : Nil
    format_signature io, type, false
  end

  def self.format_tree(io : IO, type : Redoc::Annotation, indent : Int32) : Nil
    format_signature io, type, false
  end

  def self.format_tree(io : IO, type : Redoc::Def, indent : Int32) : Nil
    format_signature io, type, false
  end

  def self.format_tree(io : IO, type : Redoc::Macro, indent : Int32) : Nil
    format_signature io, type, false
  end

  def self.format_tree(io : IO, type : Redoc::Type, indent : Int32) : Nil
  end

  def self.format_signature(io : IO, type : Redoc::Const, with_parent : Bool) : Nil
    io << type.name.colorize.blue << '\n'
  end

  def self.format_signature(io : IO, type : Redoc::Module, with_parent : Bool) : Nil
    io << "module ".colorize.red
    format_path io, type.full_name, :magenta
    io << '\n'
  end

  def self.format_signature(io : IO, type : Redoc::Class, with_parent : Bool) : Nil
    io << "abstract ".colorize.red if type.abstract?
    io << "class ".colorize.red
    format_path io, type.full_name, :magenta

    if with_parent && (parent = type.parent)
      io << " < "
      format_path io, parent.full_name, :magenta
    end
    io << '\n'
  end

  def self.format_signature(io : IO, type : Redoc::Struct, with_parent : Bool) : Nil
    io << "abstract ".colorize.red if type.abstract?
    io << "struct ".colorize.red
    format_path io, type.full_name, :magenta

    if with_parent && (parent = type.parent)
      io << " < "
      format_path io, parent.full_name, :magenta
    end
    io << '\n'
  end

  def self.format_signature(io : IO, type : Redoc::Enum, with_parent : Bool) : Nil
    io << "enum ".colorize.red
    format_path io, type.full_name, :magenta

    if with_parent && (base = type.type)
      io << " : "
      format_path io, base, :magenta
    end
    io << '\n'
  end

  def self.format_signature(io : IO, type : Redoc::Alias, with_parent : Bool) : Nil
    io << "alias ".colorize.red
    format_path io, type.full_name, :magenta
    io << " = " << type.type.colorize.blue << '\n'
  end

  def self.format_signature(io : IO, type : Redoc::Annotation, with_parent : Bool) : Nil
    io << "annotation ".colorize.red
    format_path io, type.full_name, :magenta
    io << '\n'
  end

  def self.format_signature(io : IO, type : Redoc::Def, with_parent : Bool) : Nil
    io << "abstract ".colorize.red if type.abstract?
    io << "def ".colorize.red
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
      io << " : "
      format_path io, ret, :blue
    end

    if type.generic?
      io << " forall ".colorize.red
      type.free_vars.join(io, ", ") { |v, str| str << v.colorize.blue }
    end
    io << '\n'
  end

  def self.format_signature(io : IO, type : Redoc::Macro, with_parent : Bool) : Nil
    io << "macro ".colorize.red
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

  def self.format_info(io : IO, type : Redoc::Const, with_parent : Bool) : Nil
    io << type.name.colorize.blue << " = " << type.value << '\n'

    if summary = type.summary
      io << "\n  " << summary << '\n'
    end

    io << "\nDefined: "
    if type.top_level?
      io << "top-level namespace\n".colorize.dark_gray
    else
      io << "(cannot resolve location)\n".colorize.dark_gray
    end

    if doc = type.doc
      io << '\n'
      doc.lines.join(io, '\n') { |line, str| str << "  " << line }
    end
  end

  def self.format_info(io : IO, type : Redoc::Module, with_parent : Bool) : Nil
    format_signature io, type, with_parent
    format_base io, type
  end

  def self.format_info(io : IO, type : Redoc::Class, with_parent : Bool) : Nil
    format_signature io, type, with_parent
    format_base io, type
  end

  def self.format_info(io : IO, type : Redoc::Struct, with_parent : Bool) : Nil
    format_signature io, type, with_parent
    format_base io, type
  end

  def self.format_info(io : IO, type : Redoc::Enum, with_parent : Bool) : Nil
    format_signature io, type, with_parent

    type.constants.each do |const|
      io << "  " << const.name.colorize.blue << " = " << const.value
      if summary = const.summary
        io << "\n  " << summary << '\n'
      end
      io << '\n'
    end

    io << "end\n".colorize.red
    format_base io, type
  end

  def self.format_info(io : IO, type : Redoc::Alias, with_parent : Bool) : Nil
    format_signature io, type, with_parent
    format_base io, type
  end

  def self.format_info(io : IO, type : Redoc::Annotation, with_parent : Bool) : Nil
    format_signature io, type, with_parent
    format_base io, type
  end

  def self.format_info(io : IO, type : Redoc::Def, with_parent : Bool) : Nil
    format_signature io, type, with_parent

    if summary = type.summary
      io << "\n  " << summary << '\n'
    end

    io << "\nDefined:"
    if loc = type.location
      io << "\n• " << loc.filename << ':' << loc.line_number << '\n'
      if url = loc.url
        Colorize.with.dark_gray.surround(io) do
          io << "  (" << url << ")\n"
        end
      end
    else
      io << "(cannot resolve location)\n".colorize.dark_gray
    end

    if doc = type.doc
      io << '\n'
      doc.lines.join(io, '\n') { |line, str| str << "  " << line }
    end
  end

  def self.format_info(io : IO, type : Redoc::Macro, with_parent : Bool) : Nil
    format_signature io, type, with_parent

    if summary = type.summary
      io << "\n  " << summary << '\n'
    end

    io << "\nDefined:"
    if loc = type.location
      io << "\n• " << loc.filename << ':' << loc.line_number << '\n'
      if url = loc.url
        Colorize.with.dark_gray.surround(io) do
          io << "  (" << url << ")\n"
        end
      end
    else
      io << "(cannot resolve location)\n".colorize.dark_gray
    end

    if doc = type.doc
      io << '\n'
      doc.lines.join(io, '\n') { |line, str| str << "  " << line }
    end
  end

  def self.format(io : IO, type : Redoc::Parameter) : Nil
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

  def self.format_base(io : IO, type : Redoc::Type) : Nil
    renderer = Renderer.new Markd::Options.new

    if summary = type.summary
      doc = Markd::Parser.parse summary
      io << "\n  " << renderer.render(doc)
    end

    io << "\nDefined:\n"
    type.locations.each do |loc|
      io << "• " << loc.filename << ':' << loc.line_number << '\n'
      if url = loc.url
        Colorize.with.dark_gray.surround(io) do
          io << "  (" << url << ")\n\n"
        end
      end
    end

    if content = type.doc
      doc = Markd::Parser.parse content
      io << '\n' << renderer.render(doc) << '\n'
    end
  end

  def self.format_path(io : IO, name : String, color : Colorize::ColorANSI) : Nil
    if name.includes? '('
      name, *params = name.split(/\(|\)|,/, remove_empty: true)
      name.split("::").join(io, "::") { |n, str| str << n.colorize(color) }

      io << '('
      params.join(io, ", ") do |param, str|
        if param.starts_with? "**"
          str << "**".colorize.red << param[2..].colorize(color)
        elsif param.starts_with? '*'
          str << '*'.colorize.red << param[1..].colorize(color)
        else
          str << param.colorize(color)
        end
      end
      io << ')'
    else
      name.split("::").join(io, "::") { |n, str| str << n.colorize(color) }
    end
  end
end
