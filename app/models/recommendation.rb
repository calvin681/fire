class Recommendation
  include Mongoid::Document
  include Mongoid::Timestamps
  
  embedded_in :user
  
  attr_accessible :recommendation_text, :type, :recommender_first_name, :recommender_last_name,
                  :recommender_id
  
  validates_presence_of :recommendation_text
  validates_presence_of :recommender_id
  
end