module Docr::Formatters::Base
  protected getter? constants : Bool = false
  protected getter? modules : Bool = false
  protected getter? classes : Bool = false
  protected getter? structs : Bool = false
  protected getter? enums : Bool = false
  protected getter? aliases : Bool = false
  protected getter? annotations : Bool = false
  protected getter? defs : Bool = false
  protected getter? macros : Bool = false

  protected def apply(options : Cling::Options) : Nil
    if excludes = options.get?("exclude").try(&.as_a)
      @constants = !excludes.includes?("constants")
      @modules = !excludes.includes?("modules")
      @classes = !excludes.includes?("classes")
      @structs = !excludes.includes?("structs")
      @enums = !excludes.includes?("enums")
      @aliases = !excludes.includes?("aliases")
      @annotations = !excludes.includes?("annotations")
      @defs = !excludes.includes?("defs")
      @macros = !excludes.includes?("macros")
    end

    if includes = options.get?("include").try(&.as_a)
      @constants ||= includes.includes?("constants")
      @modules ||= includes.includes?("modules")
      @classes ||= includes.includes?("classes")
      @structs ||= includes.includes?("structs")
      @enums ||= includes.includes?("enums")
      @aliases ||= includes.includes?("aliases")
      @annotations ||= includes.includes?("annotations")
      @defs ||= includes.includes?("defs")
      @macros ||= includes.includes?("macros")
    end
  end
end
