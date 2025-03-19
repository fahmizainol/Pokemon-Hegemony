def pbCreateLog(logname, *args)
    log_dir = File.expand_path("./Log", Dir.pwd)
    Dir.mkdir(log_dir) if !Dir.exist?(log_dir)
    log_file = File.expand_path("./Log/#{logname}.log", Dir.pwd)
    File.open(log_file, 'ab') do |f|
      f.write(sprintf("=======================\n"))
      f.write(sprintf("\n%s\n", Time.now))
      f.write(sprintf("%s\n", args))
      f.write(sprintf("=======================\n\n"))
    end
  
end 