class Car
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name
  field :subtitle
  field :ext_color
  field :int_color
  field :mileage, :type => Integer
  field :price, :type => Integer
  field :location
  field :car_number
  
end