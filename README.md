do-if is a small gem to allow you to easily run code when files on your file system change. It is not a file-system watcher, but instead inspects the files every time it is called and will invoke a block if anything has changed since the last time it was run.

This can be especially useful for doing pre-processing of files as part of a build, where you need a predictable, synchronous process but only when file modifications have occurred.

Here's an example where you want to rebuild DOM fixtures when any of your view files have changed:

    DoIf.any_file_changed("#{Rails.root}/app/views/**/*") do
      `rake fixtures:build`
    end

Here's an example looking for accidental console statements in JavaScript files:

    DoIf.any_file_changed_for_each_changed_file("#{Rails.root}/public/javascripts/**/*.js") do |changed_file|
      if File.read(changed_file).include? 'console.'
        raise "Whoops! A console statement was found in #{changed_file}"
      end
    end

All state about previous runs is stored in a YAML file. The default location is /tmp but this can be configured using the temp_directory= method

    DoIf.temp_directory = "#{Rails.root}/tmp"

== License
MIT License
