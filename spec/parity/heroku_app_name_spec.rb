require File.join(File.dirname(__FILE__), "..", "..", "lib", "parity")

RSpec.describe Parity::HerokuAppName do
  describe "#to_s" do
    it "returns the name of the application as hosted on Heroku" do
      allow(Open3).
        to receive(:capture3).
        with("heroku info --remote staging").
        and_return(
          [
            "=== my-special-app-staging\nAddOns: blahblahblah",
            "",
            {},
          ],
        )

      application_name = Parity::HerokuAppName.new("staging").to_s

      expect(application_name).to eq("my-special-app-staging")
    end
  end
end
