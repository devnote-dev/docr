module Docr::Resolver
  def self.fetch_crystal_docs(version : String) : Redoc::Project
    Crest.get "https://crystal-lang.org/api/#{version}/index.json" do |res|
      Redoc.load res
    end
  end

  def self.fetch_crystal_versions(fetch : Bool) : Array(String)
    path = CACHE_DIR / "versions.txt"
    import_crystal_versions if fetch || !File.exists?(path)

    File.read_lines(path).map(&.split(',').first)
  end

  def self.import_crystal_versions : Nil
    FileUtils.rm_rf CACHE_DIR
    Dir.mkdir_p CACHE_DIR

    res = Crest.get "https://crystal-lang.org/api/versions.json"
    data = JSON.parse res.body
    content = data["versions"].as_a.map do |version|
      version["name"].as_s + "," + version["url"].as_s
    end.join('\n')

    File.write(CACHE_DIR / "versions.txt", content)
  end

  def self.import_crystal_version(version : String) : Nil
    versions = fetch_crystal_versions false
    unless versions.includes? version
      raise "crystal version '#{version}' not available"
    end

    ver = version == "nightly" ? "master" : version
    File.open(LIBRARY_DIR / "crystal" / (version + ".json"), mode: "w") do |file|
      Crest.get "https://crystal-lang.org/api/#{ver}/index.json" do |res|
        proj = Redoc.load res.body_io
        proj.to_json file
      end
    end
  end
end
