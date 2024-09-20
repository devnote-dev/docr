module Docr::Resolver
  def self.fetch_versions_for(name : String, url : String, req : String) : Array(String)
    path = LIBRARY_DIR / name / "VERSIONS"

    if File.exists? path
      versions = File.read_lines path
      return versions if versions.includes? req
    else
      Dir.mkdir_p LIBRARY_DIR / name
    end

    res = Crest.get url
    versions = Array({name: String})
      .from_json(res.body, root: "versions")
      .map(&.[:name])

    File.write(path, versions.join('\n'))

    versions
  end

  def self.import_crystal_version(version : String) : Nil
    ver = version == "nightly" ? "master" : version

    File.open(LIBRARY_DIR / "crystal" / (version + ".json"), mode: "w") do |file|
      Crest.get "https://crystal-lang.org/api/#{ver}/index.json" do |res|
        proj = Redoc.load res.body_io
        proj.to_json file
      end
    end
  end
end
