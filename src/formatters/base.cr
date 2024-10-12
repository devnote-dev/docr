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

  protected def apply(includes : Array(String)) : Nil
    @constants = includes.includes?("constants") || includes.includes?("const")
    @modules = includes.includes? "modules"
    @classes = includes.includes? "classes"
    @structs = includes.includes? "structs"
    @enums = includes.includes? "enums"
    @aliases = includes.includes? "aliases"
    @annotations = includes.includes?("annotations") || includes.includes?("anno")
    @defs = includes.includes? "defs"
    @macros = includes.includes? "macros"
  end
end
