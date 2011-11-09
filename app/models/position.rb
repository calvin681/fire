require 'time_helper'

class Position
  include Mongoid::Document
  include Mongoid::Timestamps
  include TimeHelper
  
  embedded_in :user
  
  field :company_id, :type => Integer
  field :start_month, :type => Integer
  field :start_year, :type => Integer
  field :end_month, :type => Integer
  field :end_year, :type => Integer
  field :company_name
  field :company_industry
  field :title
  field :summary
  
  attr_accessible :company_id, :company_name, :company_industry, :title, :summary, :start_month, :start_year,
                  :end_month, :end_year
  
  validates_presence_of :company_name
  validates_presence_of :title
  
end