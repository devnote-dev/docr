module Docr::Commands
  class Add < Base
    def setup : Nil
      @name = "add"
      @summary = "imports documentation for a library"
      @description = <<-DESC
        Imports a version of a specified library (or shard). By default the latest
        version is installed, this can be changed by specifying the '--version' flag.
        To import Crystal's standard library, specify 'crystal'. For all other libraries,
        the following formats are supported for the source:

          - docr add https://github.com/user/repo
          - docr add github.com/user/repo
          - docr add github:user/repo
          - docr add gh:user/repo

        The following shorthands are supported for sources:
          - github: / gh:
          - gitlab: / gl:
          - bitbucket: / bb:

        Absolute URLs to sources other than GitHub, GitLab and BitBucket are not yet
        supported.
        DESC

      add_usage "docr add <source> [options]"
      add_usage "docr add crystal [options]"

      add_argument "source", description: "the source of the library (or 'crystal')", required: true
      add_option 'f', "fetch", description: "fetch versions from the api"
      add_option 'v', "version", type: :single, default: "latest"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      source = arguments.get("source").as_s

      if source == "crystal"
        add_crystal_library options.get("version").as_s, options.has?("fetch")
      else
        add_external_library source, options.get("version").as_s
      end
    end

    private def add_crystal_library(version : String, fetch : Bool) : Nil
      info "Fetching available versions..."

      versions = Resolver.fetch_crystal_versions fetch
      version = versions[1] if version == "latest"

      if version == "nightly"
        info "Importing nightly build of crystal library"
      else
        info "Importing crystal library version #{version}"
      end

      Dir.mkdir_p LIBRARY_DIR / "crystal"
      set = Library.get_versions_for "crystal"
      term = version == "nightly" ? "Nightly build of crystal" : "Crystal version #{version}"

      if set.includes? version
        error "#{term} is already imported"
        error "If a newer version is available, rerun with the '--fetch' flag"
        exit_program
      end

      unless versions.includes? version
        error "Crystal version #{version} is not available"
        error "Run 'docr check' to see available versions of imported libraries"
        exit_program
      end

      Resolver.import_crystal_version version

      info "Imported #{term}"
    end

    private def add_external_library(source : String, version : String) : Nil
      info "Resolving source..."

      case source
      when .starts_with?("github:"), .starts_with?("gh:")
        host = "github"
        path = source.gsub(/github:|gh:/, "")
      when .starts_with?("gitlab:"), .starts_with?("gl:")
        host = "gitlab"
        path = source.gsub(/gitlab:|gl:/, "")
      when .starts_with?("bitbucket:"), .starts_with?("bb:")
        host = "bitbucket"
        path = source.gsub(/bitbucket:|bb:/, "")
      else
        source = URI.parse source

        unless source.host.in?("github.com", "gitlab.com", "bitbucket.com")
          error "Unsupported library source"
          error "See '#{"docr add --help".colorize.blue}' for more information"
          exit_program
        end

        host = source.host.as(String).rchop(".com")
        path = source.path
      end

      debug url = "https://crystaldoc.info/#{host}/#{path}/versions.json"
      begin
        Crest.head url
      rescue Crest::NotFound
        error "Library not found"
        exit_program
      end

      versions = uninitialized Array(String)
      Crest.get url do |res|
        versions = Array({name: String})
          .from_json(res.body_io, root: "versions")
          .map(&.[:name])
          .sort!
      end

      name = path.split('/')[1]
      if version == "latest"
        version = versions.last
      elsif !versions.includes?(version)
        error "Version #{version} not found for '#{name}'"
        exit_program
      end

      if Library.exists?(name, version)
        error "'#{name}' version #{version} is already imported"
        exit_program
      end

      debug lib_dir = LIBRARY_DIR / name
      Dir.mkdir_p lib_dir
      debug url = "https://crystaldoc.info/#{host}/#{path}/#{version}/index.json"

      begin
        Crest.get url do |res|
          File.open(lib_dir / "#{version}.json", mode: "w") do |dest|
            library = Redoc.load res.body_io.gets_to_end
            library.to_json dest
          end
        end

        info "Imported '#{name}' version #{version}"
      rescue ex
        error "Failed to save library data:"
        error ex.to_s

        FileUtils.rm_rf lib_dir
      end
    end
  end
end
