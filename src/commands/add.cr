module Docr::Commands
  class Add < Base
    KNOWN_SOURCES = {
      "github.com",
      "gitlab.com",
      "bitbucket.com",
      "codeberg.org",
      "sr.ht",
      "git.sr.ht",
    }

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
          - codeberg: / cb:
          - srht:

        Absolute URLs to sources other than GitHub, GitLab, BitBucket, Codeberg and
        Source Hut are not yet supported.
        DESC

      add_usage "docr add <source> [options]"
      add_usage "docr add crystal [options]"

      add_argument "source", description: "the source of the library (or 'crystal')", required: true
      add_option 'a', "alias", type: :single
      add_option 'v', "version", type: :single, default: "latest"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      source = arguments.get("source").as_s

      if source == "crystal"
        add_crystal_library options.get("version").as_s
      else
        add_external_library(
          source,
          options.get("version").as_s,
          options.get?("alias").try(&.as_s)
        )
      end
    end

    private def add_crystal_library(version : String) : Nil
      info "Fetching available versions..."

      versions = Resolver.fetch_versions_for(
        "crystal",
        "https://crystal-lang.org/api/versions.json",
        version
      )
      version = versions[1] if version == "latest"
      term = version == "nightly" ? "nightly build" : "version #{version}"
      set = Library.get_versions_for "crystal"

      if version != "nightly" && set.includes? version
        error "Crystal #{term} is already imported"
        exit_program
      end

      unless versions.includes? version
        error "Crystal #{term} is not available"
        error "Run '#{"docr check".colorize.blue}' to see available versions of imported libraries"
        exit_program
      end

      info "Importing library..."
      Resolver.import_crystal_version version

      info "Imported crystal #{term}"
    end

    private def add_external_library(source : String, version : String, alias_name : String?) : Nil
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
      when .starts_with?("codeberg:"), .starts_with?("cb:")
        host = "codeberg-org"
        path = source.gsub(/codeberg:|cb:/, "")
      when .starts_with?("srht:")
        host = "git-sr-ht"
        path = source.gsub("srht:", "")
        path = '~' + path unless path.starts_with? '~'
      else
        source = URI.parse source

        unless source.host.in? KNOWN_SOURCES
          error "Unsupported library source"
          error "See '#{"docr add --help".colorize.blue}' for more information"
          exit_program
        end

        host = source.host.as(String)
        if host == "sr.ht" || host == "git.sr.ht"
          host = "git-sr-ht"
        elsif host == "codeberg.org"
          host = "codeberg-org"
        else
          host = host.chomp ".com"
        end
        path = source.path.lchop '/'
      end

      path = path.chomp ".git"
      info "Fetching available versions..."
      debug url = "https://crystaldoc.info/#{host}/#{path}/versions.json"

      begin
        Crest.head url
      rescue Crest::NotFound
        error "Library not found"
        exit_program
      end

      name = alias_name || path.split('/')[1]
      versions = Resolver.fetch_versions_for(name, url, version)

      if version == "latest"
        version = versions[1]
      elsif !versions.includes?(version)
        error "Version #{version} not found for #{name}"
        error "Run '#{"docr check".colorize.blue}' to see available versions of imported libraries"
        exit_program
      end

      if Library.exists?(name)
        unless Library.get_source(name) == url
          error "Library #{name} has separate sources with the same name"
          error "Install this library using an '#{"--alias".colorize.blue}' or remove the existing library"
          exit_program
        end

        if Library.exists?(name, version)
          error "Library #{name} version #{version} is already imported"
          exit_program
        end
      end

      info "Importing library..."
      debug lib_dir = LIBRARY_DIR / name
      debug url = "https://crystaldoc.info/#{host}/#{path}/#{version}/index.json"

      begin
        Crest.get url do |res|
          File.open(lib_dir / "#{version}.json", mode: "w") do |dest|
            library = Redoc.load res.body_io.gets_to_end
            library.to_json dest
          end
        end
        File.write(lib_dir / "SOURCE", url)

        info "Imported #{name} version #{version}"
      rescue ex
        error "Failed to save library data:"
        error ex.to_s
      end
    end
  end
end
