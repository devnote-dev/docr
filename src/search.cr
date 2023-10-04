module Docr
  class Search
    QUERY_RULE = /^(?<ns>(?:::)?[A-Z_]{1,}(?:\w+|::)+)?(?<scp>\.|#|\s+)?(?<sym>[a-zA-Z_]{1,}[\w!?=]|[!?<=>^+\-~\/*&%\[|\]])?$/

    enum Scope
      Class
      Instance
      All

      def self.from(str : String?)
        case str
        when "." then Scope::Class
        when "#" then Scope::Instance
        else          Scope::All
        end
      end
    end

    property! constants : Array(Models::Constant)
    property! modules : Array(Models::Type)
    property! classes : Array(Models::Type)
    property! structs : Array(Models::Type)
    property! enums : Array(Models::Type)
    property! aliases : Array(Models::Type)
    property! annotations : Array(Models::Type)
    property! defs : Array(Models::Def)
    property! macros : Array(Models::Def)

    def results? : Bool
      !(
        @constants.nil? &&
          @modules.nil? &&
          @classes.nil? &&
          @structs.nil? &&
          @enums.nil? &&
          @aliases.nil? &&
          @annotations.nil? &&
          @defs.nil? &&
          @macros.nil?
      )
    end

    def apply_filters(type : Models::Type, namespace : String, scope : Scope, symbol : String?) : Nil
      symbol ||= namespace

      filter_constants type, symbol
      filter_modules type, symbol
      filter_classes type, symbol
      filter_structs type, symbol
      filter_annotations type, symbol
      filter_enums type, symbol
      filter_aliases type, symbol
    end

    private def filter_constants(type : Models::Type, symbol : String) : Nil
      return unless type.constants?
      matches = Fzy.search(symbol, type.constants.map &.name)
      pp! matches

      @constants = matches.map do |match|
        type.constants.find! { |c| c.name == match.value }
      end
    end

    {% for type in %w(modules classes structs annotations) %}
      private def filter_{{type.id}}(type : Models::Type, symbol : String) : Nil
        return unless type.types?
        {{ type.id }} = type.types.select { |t| t.kind == {{ type }} }
        matches = Fzy.search(symbol, {{ type.id }}.map &.name)

        @{{ type.id }} = matches.map do |match|
          {{ type.id }}.find! { |v| v.name == match.value }
        end
      end
    {% end %}

    private def filter_enums(type : Models::Type, symbol : String) : Nil
      return unless type.types?
      enums = type.types.select &.enum?
      matches = Fzy.search(symbol, enums.map &.name)

      @enums = matches.map do |match|
        enums.find! { |e| e.name == match.value }
      end
    end

    private def filter_aliases(type : Models::Type, symbol : String) : Nil
      return unless type.types?
      aliases = type.types.select &.alias?
      matches = Fzy.search(symbol, aliases.map &.name)

      @aliases = matches.map do |match|
        aliases.find! { |e| e.name == match.value }
      end
    end
  end
end
