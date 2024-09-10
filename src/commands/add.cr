module Docr::Commands
  class Add < Base
    def setup : Nil
      @name = "add"
      @summary = "imports documentation for a library"
      @description = <<-DESC
        Imports documentation for the Crystal standard library or a third-party library
        (or shard). If you are importing the standard library, the 'source' argument
        should be the version to import ("latest" also works here). Otherwise, the
        'source' argument should be a URI that resolves to the library's repository
        (which is handled by git).
        DESC

      add_usage "docr add <name> <source> [options]"
      add_usage "docr add <name> latest [options]"

      add_argument "name", description: "the name of the library", required: true
      add_argument "source", description: "the source of the library (or latest for crystal)", required: true
      add_option 'f', "fetch", description: "fetch versions from the api"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      name = arguments.get("name").as_s
      source = arguments.get("source").as_s

      if name == "crystal"
        add_crystal_library source, options.has?("fetch")
      else
        add_external_library name, source, "latest"
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

    private def add_external_library(name : String, source : String, version : String) : Nil
      uri = URI.parse source
      cache_dir = CACHE_DIR / name
      Dir.mkdir_p cache_dir

      info "Cloning into #{uri}..."
      args = ["git", "clone", uri.to_s, ".", "--quiet"]
      unless version.empty?
        args << "--branch" << version
      end

      if err = exec args.join(' '), cache_dir
        if version.empty?
          error "Failed to clone #{uri}:"
          error err
          exit_program
        end

        if err = exec args[0...-2].join(' '), cache_dir
          error "Failed to clone #{uri}:"
          error err
          exit_program
        end
      end

      info "installing dependencies"
      if err = exec "shards install --without-development", cache_dir
        error "Failed to install library dependencies:"
        error err
        exit_program
      end

      info "Getting shard information..."
      shard = YAML.parse File.read(cache_dir / "shard.yml")

      unless shard["name"].as_s == name
        error "Cannot verify shard: names do not match"
        error "Expected '#{name}'; got '#{shard["name"]}'"
        exit_program
      end

      if version == "latest"
        version = shard["version"].as_s
      else
        unless shard["version"].as_s == version
          error "Cannot verify shard: versions do not match"
          error "Expected version #{version}; got #{shard["version"]}"
          exit_program
        end
      end

      if Library.exists?(name, version)
        error "Library #{name} version #{version} is already imported"
        exit_program
      end

      info "Building documentation..."
      if err = exec "crystal docs", cache_dir
        error "Failed to build documentation:"
        error err
        exit_program
      end

      lib_dir = LIBRARY_DIR / name
      Dir.mkdir_p lib_dir

      File.open(lib_dir / (version + ".json"), mode: "w") do |dest|
        File.open(cache_dir / "docs" / "index.json") do |src|
          proj = Redoc.load src
          proj.to_json dest
        end
      end

      info "Imported #{name} version #{version}"
    ensure
      debug "clearing: #{cache_dir}"
      FileUtils.rm_r cache_dir.as(Path)
    end

    private def exec(command : String, dir : Path) : String?
      debug "exec: #{command}"
      debug "dir: #{dir}"

      err = IO::Memory.new
      res = Process.run command, chdir: dir, error: err, shell: true
      debug "status: #{res.exit_status}"

      return err.to_s unless res.success? && err.empty?
    end
  end
end
