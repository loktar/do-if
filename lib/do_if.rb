require 'sha1'

module DoIf
  YAML_FILE = "/tmp/do_if.yml"
  
  def self.any_file_changed(file_glob, &block)
    FileUtils.touch(YAML_FILE) unless File.exists?(YAML_FILE)
    
    cache = YAML.load_file(YAML_FILE) || {}
    files = Dir.glob(file_glob)
    
    file_hash = file_name_hash(files)
    mtime = max_mtime(files)
    
    if !cache.has_key?(file_glob) || (cache[file_glob] != {'file_names' => file_hash, 'max_mtime' => mtime})
      update_cache_and_save cache, file_glob, file_hash, mtime
      yield
    end
  end
  
  private
  
  def self.update_cache_and_save(cache, dir_name, file_hash, mtime)
    cache[dir_name] = {"file_names" => file_hash, "max_mtime" => mtime}
    File.open(YAML_FILE, 'w') do |f|
      f.write(YAML.dump(cache))
    end
  end
  
  def self.file_name_hash(files)
    SHA1.sha1(files.join("::")).to_s
  end
  
  def self.max_mtime(files)
    files.collect {|f| File.mtime(f)}.max
  end
end