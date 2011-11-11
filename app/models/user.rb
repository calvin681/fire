class User
  include Mongoid::Document
  include Mongoid::Timestamps
  
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :trackable, :validatable
  devise :rememberable, :omniauthable
  
  embeds_many :positions
  embeds_many :educations
  embeds_many :recommendations
  
  field :num_connections, :type => Integer
  field :num_connections_capped, :type => Boolean
  field :first_name
  field :last_name
  field :name
  field :location
  field :description
  field :public_profile_url
  field :image
  field :industry
  field :summary
  field :num_connections
  field :num_connections_capped
  field :provider
  field :uid
  field :token
  field :secret
  field :positions_attributes
  field :educations_attributes
  field :recommendations_attributes
  field :public
  field :public_id
  field :importing_linkedin_data, :type => Boolean
  
  index :uid
  
  accepts_nested_attributes_for :positions, :educations, :recommendations
  
  attr_accessible :first_name, :last_name, :name, :location, :description, :public_profile_url, :image, :industry,
                  :summary, :num_connections, :num_connections_capped, :provider, :uid, :token, :secret,
                  :positions_attributes, :educations_attributes, :recommendations_attributes, :public,
                  :public_id
  
  validates_presence_of :first_name
  validates_presence_of :last_name
  validates_presence_of :name
  validates_presence_of :public_profile_url
  validates_presence_of :provider
  validates_presence_of :uid
  validates_presence_of :token
  validates_presence_of :secret
  
  before_save :set_public_id
  
  def remember_me
    true
  end
  
  def import_linkedin_data_background
    client = LinkedIn::Client.new(Yetting.linked_in_api_key, Yetting.linked_in_api_secret)
    client.authorize_from_access(self.token, self.secret)
    profile = client.profile(
      :fields => ["industry", "summary", "positions", "educations", "recommendations-received", "num-connections",
                  "num-connections-capped", "picture-url"])

    if profile.positions.all.present?
      profile.positions.all.each do |p|
        p.delete(:id)
        if p.start_date
          p.start_month = p.start_date.month
          p.start_year = p.start_date.year
        end
        if p.end_date
          p.end_month = p.end_date.month
          p.end_year = p.end_date.year
        end
        p.company_id = p.company.id
        p.company_name = p.company.name
        p.company_industry = p.company.industry
      end
      profile.positions_attributes = profile.positions.all
    end
    
    if profile.educations.all.present?
      profile.educations.all.each do |p|
        p.delete(:id)
        if p.start_date
          p.start_month = p.start_date.month
          p.start_year = p.start_date.year
        end
        if p.end_date
          p.end_month = p.end_date.month
          p.end_year = p.end_date.year
        end
      end
      profile.educations_attributes = profile.educations.all
    end
    
    if profile.recommendations_received.all.present?
      profile.recommendations_received.all.each do |p|
        p.delete(:id)
        p.type = p.recommendation_type.code
        p.recommender_id = p.recommender.id
        p.recommender_first_name = p.recommender.first_name
        p.recommender_last_name = p.recommender.last_name
      end
      profile.recommendations_attributes = profile.recommendations_received.all
    end
    
    self.positions.destroy_all
    self.educations.destroy_all
    self.recommendations.destroy_all
    self.attributes = profile
    self.importing_linkedin_data = false
    self.save!
  end
  
  handle_asynchronously :import_linkedin_data_background
  
  def import_linkedin_data
    self.importing_linkedin_data = true
    self.save
    import_linkedin_data_background
  end
  
  def episodes(current_date_number)
    (positions + educations).sort_by! do |e|
      [-e.end_date_number(current_date_number), -e.start_date_number]
    end
  end
  
  def set_public_id
    self.public_id = /.+www\.linkedin\.com\/(.*)/.match(public_profile_url)[1] if public_profile_url.present?
  end
  
end
