class Company
  include MongoMapper::Document
  
  key :name, String
  
  timestamps!
  
  validates_presence_of :name
  validates_length_of :name, :maximum => 20
end