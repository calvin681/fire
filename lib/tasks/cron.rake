require 'cron'

task :cron => :environment do
  Cron.start
end
