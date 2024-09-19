module Docr::Commands
  class Remove < Base
    def setup : Nil
      @name = "remove"
      @summary = "removes a library"
      @description = "Removes an imported library. If the 'version' argument is not specified, all\n" \
                     "versions of the library are removed."

      add_usage "docr remove <name> [version]"

      add_argument "name", description: "the name of the library", required: true
      add_argument "version", description: "the version of the library"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      name = arguments.get("name").as_s
      version = arguments.get?("version").try &.as_s

      unless Library.exists?(name, version)
        if version
          if Library.exists?(name)
            error "Version '#{version}' of #{name} not found or imported"
            exit_program
          end
        end

        error "Library '#{name}' not imported"
        exit_program
      end

      Library.delete name, version
    end
  end
end
