class CarCrawl
  
  CAR_MAP = { '5472' => 'GL320 BlueTEC', '4231' => 'GL320 CDI', '5531' => 'GL350 BlueTEC', '5220' => 'GL450',
    '5221' => 'GL550' }
  
  def agent
    @m_agent ||= Mechanize.new
  end
  
  def start
    @cars = Car.where(:deleted_at => nil).all.map(&:id)
    crawl
    crawl2
    Car.where(:_id.in => @cars).update_all(:deleted_at => Time.now)
    email
  end
  
  def crawl
    Nokogiri::HTML(agent.get("http://www.autobahnmotors.com/certified-inventory/index.htm", [
        ['SByear', 'clear'],
        ['SBmake', 'Mercedes-Benz'],
        ['SBmodel', 'GL-Class'],
        ['SBbodystyle', 'clear'],
        ['SBprice', 'clear'],
        ['sortBy', 'internetprice asc']
      ]).body).css("ul > li.vehicle").each do |node|

      name = node.at_css("h2 span").text.strip
      ext_color = node.at_css("dd.extColorValue")
      ext_color = ext_color.text.strip if ext_color
      int_color = node.at_css("dd.intColorValue")
      int_color = int_color.text.strip if int_color
      mileage = node.at_css("dd.mileageValue").text
      mileage.gsub!(",", "") if mileage
      location = node.at_css("dd.location").text.strip
      price = node.at_css("span.price em").text.gsub!("$", "").gsub!(",", "")
      car_number = node.css("dt").detect { |d| 'Vin:'.casecmp(d.text) == 0 }.next_element.text.strip
      
      car = Car.find_or_create_by(:car_number => car_number)
      @cars.delete(car.id) unless car.new_record?
      car.attributes = { :name => name, :ext_color => ext_color, :int_color => int_color, :mileage => mileage,
        :location => location, :price => price, :deleted_at => nil }
      car.save!
    end
  end
  
  def crawl2
    JSON.parse(agent.get("http://www.mypreownedmercedes.com/mbucl?search={%22country2%22:%22US%22," +
      "%22hits%22:{%22to%22:999},%22cpo%22:1,%22postcode%22:%2294002%22,%22distance%22:{%22to%22:%2250%22}," +
      "%22year%22:{%22to%22:9998},%22order%22:[%22pricea%22],%22class_bodystyle%22:[{%22class%22:45," +
      "%22bodystyle%22:[3],%22model%22:[],%22variant%22:[]}]}").body)["vehicles"].each do |v|
      car_number = v["reg"]
      name = "#{v['ryr']} Mercedes-Benz #{CAR_MAP[v['mod']]} #{v['vnt']}"
      ext_color = v['ext']
      int_color = v['int']
      mileage = v['mil']
      location = v['dln']
      price = v['pri']
      
      next if location == "Autobahn Motors"

      car = Car.find_or_create_by(:car_number => car_number)
      @cars.delete(car.id) unless car.new_record?
      car.attributes = { :name => name, :ext_color => ext_color, :int_color => int_color, :mileage => mileage,
        :location => location, :price => price, :deleted_at => nil }
      car.save!
    end
  end
  
  def email
    cars = Car.where(:deleted_at => nil).asc(:price)
    GeneralMailer.crawl_report(cars).deliver unless cars.empty?
  end
  
  def retryable(options = {}, &block)
    opts = { :tries => 1, :on => Exception }.merge(options)
    retry_exception, retries = opts[:on], opts[:tries]

    begin
      return yield
    rescue retry_exception => e
      if (retries -= 1) > 0
        sleep(opts[:backoff]) if opts[:backoff]
        retry
      else
        raise e
      end
    end
  end
  
end