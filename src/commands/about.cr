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

      version ||= Library.get_versions_for(name).last
      library = Library.get name, version
      doc = Markd::Parser.parse library.description

      stdout.puts Renderer.new.render(doc)
    rescue JSON::Error
      error "Failed to open library: source file is in an invalid format"
      error "Please remove and import the library again"
    end
  end
end
