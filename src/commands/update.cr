module Docr::Commands
  class Update < Base
    def setup : Nil
      @name = "update"
      @summary = "updates imported libraries"
      @description = <<-DESC
        Fetches the latest versions of imported libraries. This will also import the
        Crystal standard library documentation if not imported, based on the version of
        the compiler (from "crystal version"). If the compiler is not found on the
        system or the version is unavailable, the latest available version is imported
        instead.
        DESC

      add_usage "docr update [name] [options]"

      add_argument "name", required: false
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      super
      return if Process.find_executable "git"

      error "Could not find the git executable in the system"
      error "Git is required for this operation"
      exit_program
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      if name = arguments.get?("name")
        update name.as_s
      else
        # TODO: requires library metadata that isn't available yet
      end
    end

    private def update(name : String) : Nil
    end
  end
end
