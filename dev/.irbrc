
# require '/Users/shurik/wtracker/work_tracker.rb'

begin
  current_dir = `pwd`.strip
  gemspec = Dir["#{current_dir}/*.gemspec"][0]

  if gemspec
    gem_name = File.basename(gemspec).split('.')[0]
    puts "GEM: #{gem_name}"
    $LOAD_PATH.unshift "#{current_dir}/lib"
    require gem_name

    if File.exists?("#{current_dir}/tmp/autoload.rb")
      require "#{current_dir}/tmp/autoload.rb"
    end
  end

  if File.exists?("#{current_dir}/load.rb")
    require "#{current_dir}/load.rb"
  end

  if File.exists?("#{current_dir}/dev/console_helper.rb") && !ENV["no_ch"]
    require "#{current_dir}/dev/console_helper.rb"
    extend ConsoleHelper
    send(:_cs_init) if respond_to?(:_cs_init)
  end
rescue Exception => e
  puts e.to_s
  puts e.backtrace.join("\n")
end
