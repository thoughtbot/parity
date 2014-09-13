require File.join(File.dirname(__FILE__), '..', 'lib', 'parity')

describe Parity::Configuration do
  describe "#redis_url_env_variable" do
    it "is set to REDISTOGO_URL by default" do
      configuration = Parity::Configuration.new

      expect(configuration.redis_url_env_variable).to eq("REDISTOGO_URL")
    end

    it "can be overridden" do
      configuration = Parity::Configuration.new
      configuration.redis_url_env_variable = "MYREDIS_URL"

      expect(configuration.redis_url_env_variable).to eq("MYREDIS_URL")
    end
  end
end
