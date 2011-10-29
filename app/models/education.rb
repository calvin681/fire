require 'time_helper'

class Education
  include Mongoid::Document
  include Mongoid::Timestamps
  include TimeHelper
  
  embedded_in :user
  
  field :start_month, :type => Integer
  field :start_year, :type => Integer
  field :end_month, :type => Integer
  field :end_year, :type => Integer
  
  attr_accessible :degree, :field_of_study, :school_name, :start_month, :start_year, :end_month, :end_year
  
  validates_presence_of :school_name
  
end