module Docr::Commands
  class Remove < Base
    def setup : Nil
      @name = "remove"
      @summary = "removes a library"
      @description = "Removes an imported library. If the 'version' argument is not specified, all\n" \
                     "versions of the library are removed."

      add_usage "docr remove <name> [version]"

      add_argument "name", description: "the name of the library"
      add_argument "version", description: "the version of the library", required: false
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      name = arguments.get("name").as_s
      version = arguments.get?("version").try &.as_s
      library = Library.fetch name, version

      library.delete version.nil?
    rescue ex : Library::Error
      error "failed to remove library:"
      error ex
    end
  end
end
