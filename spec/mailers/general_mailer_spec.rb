require "spec_helper"

describe GeneralMailer do
  describe "crawl_report" do
    let(:mail) { GeneralMailer.crawl_report }

    it "renders the headers" do
      mail.subject.should eq("Crawl report")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

end
