require "spec_helper"

describe Company do
  it "requires a name" do
    lambda { Company.create! }.should raise_error
  end
  
  it "validates max length on name" do
    lambda { Company.create!(:name => "012345678901234567890") }.should raise_error
  end
  
  it "creates company with name" do
    lambda { Company.create!(:name => "google") }.should change(Company, :count).by(1)
  end
end