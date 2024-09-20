module Docr::Commands
  class Check < Base
    def setup : Nil
      @name = "check"

      add_argument "library"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      if name = arguments.get?("library").try &.as_s
        if Library.exists?(name)
          check name, Library.get_versions_for(name)
        else
          error "Library '#{name}' not imported"
          exit_program
        end
      else
        Library.list_all.each do |name, versions| # ameba:disable Lint/ShadowingOuterLocalVar
          stdout.puts name
          check name, versions
        end
      end
    end

    private def check(name : String, installed : Array(String)) : Nil
      url = Library.get_source name
      res = Crest.get url + "/versions.json"

      Array({name: String})
        .from_json(res.body, root: "versions")
        .map(&.[:name])
        .reject(&.in? installed)
        .map { |v| {v, false} }
        .concat(installed.map { |v| {v, true} })
        .sort_by!(&.[0])
        .reverse_each do |(name, added)|
          if added
            Colorize.with.green.surround(stdout) do
              stdout << "• [x] " << name << '\n'
            end
          else
            stdout << "• [ ] " << name << '\n'
          end
        end
    end
  end
end
