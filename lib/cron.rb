require 'car_crawl'

class Cron

  class << self
    def start
      now = Time.now
      crawl if now.hour == 9 || now.hour == 16
    end
  
    def crawl
      execute { CarCrawl.new.start }
    end

    def execute
      return yield
    rescue Exception => e
      Airbrake.notify e
    end
  end
end
