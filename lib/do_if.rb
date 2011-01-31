require 'sha1'

module DoIf

  @@temp_directory = '/tmp'
  
  class << self

    def any_file_changed(file_glob, &block)
      files = Dir.glob(file_glob)

      cache = File.exists?(yaml_file) ? YAML.load_file(yaml_file) : {}

      return if files.empty? && !cache.has_key?(file_glob)
    
      file_hash = file_name_hash(files)
      mtime = max_mtime(files)
    
      if !cache.has_key?(file_glob) || (cache[file_glob] != {'file_names' => file_hash, 'max_mtime' => mtime})
        update_cache_and_save cache, file_glob, file_hash, mtime
        yield
      end
    end
  
    def any_file_changed_for_each_changed_file(file_glob, &block)
      Dir.glob(file_glob).each do |file_path|
        DoIf.any_file_changed(file_path) do
          yield file_path
        end
      end
    end

    def temp_directory
      @@temp_directory
    end

    def temp_directory=(value)
      @@temp_directory = value
    end

    def reset
      FileUtils.rm(yaml_file) if File.exists?(yaml_file)
    end

    private

    def yaml_file
      File.join(@@temp_directory, "do_if.yml")
    end
  
    def update_cache_and_save(cache, dir_name, file_hash, mtime)
      cache[dir_name] = {"file_names" => file_hash, "max_mtime" => mtime}
      FileUtils.mkdir_p(File.expand_path(temp_directory)) unless File.exists?(File.expand_path(temp_directory))
      File.open(yaml_file, 'w') do |f|
        f.write(YAML.dump(cache))
      end
    end
  
    def file_name_hash(files)
      SHA1.sha1(files.join("::")).to_s
    end
  
    def max_mtime(files)
      files.collect {|f| File.mtime(f)}.max
    end
  end
end