module Docr::Formatters::Default
  def self.format(io : IO, type : Redoc::Const) : Nil
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

  def self.format(io : IO, type : Redoc::Module) : Nil
    io << "module ".colorize.red
    format_path io, type.full_name, :magenta
    io << '\n'
    format_base io, type
  end

  def self.format(io : IO, type : Redoc::Class) : Nil
    io << "abstract ".colorize.red if type.abstract?
    io << "class ".colorize.red
    format_path io, type.full_name, :magenta

    if parent = type.parent
      io << " < "
      format_path io, parent.full_name, :magenta
    end
    io << '\n'

    format_base io, type
  end

  def self.format(io : IO, type : Redoc::Struct) : Nil
    io << "abstract ".colorize.red if type.abstract?
    io << "struct ".colorize.red
    format_path io, type.full_name, :magenta

    if parent = type.parent
      io << " < "
      format_path io, parent.full_name, :magenta
    end
    io << '\n'

    format_base io, type
  end

  def self.format(io : IO, type : Redoc::Enum) : Nil
    io << "enum ".colorize.red
    format_path io, type.full_name, :magenta
    io << '\n'

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

  def self.format(io : IO, type : Redoc::Alias) : Nil
    io << "alias ".colorize.red
    format_path io, type.full_name, :magenta
    io << " = "
    format_path io, type.type, :blue
    io << '\n'
    format_base io, type
  end

  def self.format(io : IO, type : Redoc::Annotation) : Nil
    io << "annotation ".colorize.red
    format_path io, type.full_name, :magenta
    io << '\n'
    format_base io, type
  end

  def self.format(io : IO, type : Redoc::Def) : Nil
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

  def self.format(io : IO, type : Redoc::Macro) : Nil
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
    if summary = type.summary
      io << "\n  " << summary << '\n'
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

    if doc = type.doc
      io << '\n'
      doc.lines.join(io, '\n') { |line, str| str << "  " << line }
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
