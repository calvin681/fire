class CarCrawl

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
      ]).body).css("ul.uf-CERTIFIED_USED_INVENTORY > li.vehicle").each do |node|

      name = node.at_css("h2 span").text.strip
      ext_color = node.at_css("dd.extColorValue")
      ext_color = ext_color.text.strip if ext_color
      int_color = node.at_css("dd.intColorValue")
      int_color = int_color.text.strip if int_color
      mileage = node.at_css("dd.mileageValue").text
      mileage.gsub!(",", "") if mileage
      location = node.at_css("dd.location").text.strip
      price = node.at_css("span.price em").text.gsub!("$", "").gsub!(",", "")
      car_number = node.css("dt").detect { |d| d.text == 'Vin:' }.next_element.text.strip
      
      car = Car.find_or_create_by(:car_number => car_number)
      @cars.delete(car.id) unless car.new_record?
      car.attributes = { :name => name, :ext_color => ext_color, :int_color => int_color, :mileage => mileage,
        :location => location, :price => price }
      car.save!
    end
  end
  
  def crawl2
    nodes = JSON.parse(agent.get("http://www.mypreownedmercedes.com/cgi-bin/mbusa/mbhitlist.cgi", [
        ['country2', 'US'],
        ['lang', 'en_US'],
        ['cpo', '1'],
        ['yearfrom', '2009'],
        ['yearto', '2013'],
        ['pricefrom', '0'],
        ['priceto', '0'],
        ['zip', '94002'],
        ['distance', '50'],
        ['bodystyle1', '3'],
        ['class1', '45'],
        ['count', '0'],
        ['page', '1'],
        ['model1', '']
      ]).body)
    nodes.unshift
    nodes.each do |node|
      car_number = node[1].to_s
      name = "#{node[10]} #{node[3]} #{node[4]} #{node[5]}"
      ext_color = node[8]
      int_color = node[9]
      mileage = node[12]
      location = node[14]
      price = node[11]
      city = node[15]
      
      next if location == "Autobahn Motors" || car_number.size < 4
      
      car = Car.find_or_create_by(:car_number => car_number)
      @cars.delete(car.id) unless car.new_record?
      car.attributes = { :name => name, :ext_color => ext_color, :int_color => int_color, :mileage => mileage,
        :location => "#{location}, #{city}", :price => price }
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