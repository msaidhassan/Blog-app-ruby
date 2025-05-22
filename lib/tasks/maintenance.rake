namespace :maintenance do
  desc "Display job statistics"
  task job_stats: :environment do
    job_classes = [DeleteOldPostsJob]
    
    job_classes.each do |job_class|
      name = job_class.name
      started = Rails.cache.read("jobs:#{name}:started").to_i
      completed = Rails.cache.read("jobs:#{name}:completed").to_i
      retried = Rails.cache.read("jobs:#{name}:retried").to_i
      
      puts "\n#{name} Statistics:"
      puts "----------------"
      puts "Started:   #{started}"
      puts "Completed: #{completed}"
      puts "Retried:   #{retried}"
    end
  end

  desc "Clean up posts older than specified hours (default 24)"
  task :cleanup_old_posts, [:hours] => :environment do |_, args|
    hours = (args[:hours] || 24).to_i
    time = hours.hours.ago
    
    count = Post.where('created_at <= ?', time).count
    puts "Found #{count} posts older than #{hours} hours"
    
    if count > 0
      print "Do you want to proceed with deletion? [y/N] "
      if STDIN.gets.chomp.downcase == 'y'
        Post.where('created_at <= ?', time).destroy_all
        puts "Successfully deleted #{count} posts"
      else
        puts "Operation cancelled"
      end
    end
  end

  desc "Reset job statistics"
  task reset_job_stats: :environment do
    job_classes = [DeleteOldPostsJob]
    
    job_classes.each do |job_class|
      name = job_class.name
      Rails.cache.delete("jobs:#{name}:started")
      Rails.cache.delete("jobs:#{name}:completed")
      Rails.cache.delete("jobs:#{name}:retried")
      puts "Reset statistics for #{name}"
    end
  end
end