require "./app/models/reserves.rb"

namespace :josiah do
  desc "Updates Course Reserves cache"
  task "reserves_update_cache" => :environment do |_cmd, args|
    puts "Updating cache reserves cache..."
    reserves = Reserves.new
    errors = reserves.cache_update()
    if errors.count == 0
      puts "OK"
    else
      puts "Errors updating reserves:"
      errors.each do |err|
        puts "\t#{err}"
      end
    end
  end
end
