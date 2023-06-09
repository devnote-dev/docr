module Docr::Commands
  class About < Base
    def setup : Nil
      @name = "about"
      @summary = "gets information about a library"
      @description = <<-DESC
        Gets information about a specified library. This will use the body text from the
        Crystal docs tool which is generally the README.md file of the library.
        DESC

      add_usage "docr about <name> [version]"

      add_argument "name", description: "the name of the library", required: true
      add_argument "version", description: "the version of the library (defaults to latest)"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      name = arguments.get("name").as_s
      version = arguments.get?("version").try &.as_s
      library = Library.fetch name, version

      stdout.puts library.data.body
    rescue ex : Library::Error
      error "Failed to fetch library:"
      error ex
    end
  end
end
