class GeneralMailer < ActionMailer::Base
  default from: "time@lnti.me"
  
  def crawl_report(cars)
    @cars = cars

    mail to: "calvin@lnti.me"
  end
end