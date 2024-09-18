module Docr::Formatters::Default
  class Renderer < Markd::Renderer
    def heading(node : Markd::Node, entering : Bool) : Nil
      level = node.data["level"].as(Int32)

      if entering
        literal "\n"

        if level == 1
          literal "\e[45;97m  "
        else
          literal "\e[34m"
          literal "#" * level
          literal " "
        end
      else
        literal "  " if level == 1
        literal "\e[0m\n\n"
      end
    end

    def code(node : Markd::Node, __) : Nil
      literal(String.build do |io|
        Colorize.with.back(236).fore(203).surround(io) do
          io << ' ' << node.text << ' '
        end
      end)
    end

    def code_block(node : Markd::Node, __) : Nil
      literal(String.build do |io|
        io << '\n'
        Colorize.with.fore(244).surround(io) do
          node.text.each_line do |line|
            io << "  " << line << '\n'
          end
        end
        io << '\n'
      end)
    end

    def thematic_break(node : Markd::Node, __) : Nil
      literal "\n————————————\n".colorize.dark_gray.to_s
    end

    def block_quote(node : Markd::Node, entering : Bool) : Nil
      # literal "┃ ".colorize.dark_gray.to_s if entering
      literal "\n" unless entering
    end

    def list(node : Markd::Node, entering : Bool) : Nil
      literal "\n" unless entering
    end

    def item(node : Markd::Node, entering : Bool) : Nil
      literal "• " if entering
    end

    def link(node : Markd::Node, __) : Nil
    end

    def image(node : Markd::Node, __) : Nil
      literal node.text
    end

    def html_block(node : Markd::Node, __) : Nil
      literal "\n"
      literal node.text
      literal "\n"
    end

    def html_inline(node : Markd::Node, __) : Nil
      literal "\n"
    end

    def paragraph(node : Markd::Node, entering : Bool) : Nil
      literal "\n" unless entering
    end

    def emphasis(node : Markd::Node, __) : Nil
      literal node.text.colorize.italic.to_s
    end

    def soft_break(node : Markd::Node, __) : Nil
      literal " "
    end

    def line_break(node : Markd::Node, __) : Nil
      literal "\n"
    end

    def strong(node : Markd::Node, __) : Nil
      literal node.text.colorize.bold.to_s
    end

    def strikethrough(node : Markd::Node, __) : Nil
      literal node.text.colorize.strikethrough.to_s
    end

    def text(node : Markd::Node, __) : Nil
      literal node.text
    end

    # Markd::Renderer isn't reusable by default...
    def render(document : Markd::Node) : String
      str = super
      @output_io = String::Builder.new
      str
    end
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
