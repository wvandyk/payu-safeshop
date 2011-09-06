require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "PayuSafeshop" do
  before(:all) do
    @config_file = File.expand_path(File.dirname(__FILE__) + '/test_config.yml')
  end
  
  it "should load config values from a yaml file" do
    lambda { p = PayUSafeShop.new(@config_file) }.should_not raise_error
  end
  
  it "should return a basic AUTH transaction" do
    p = PayUSafeShop.new(@config_file)
    p.build_auth_transaction.should == ""
  end
  
  it "should send the xml with a curl call to the relevant url" do
    p = PayUSafeShop.new(@config_file)
    p.auth(p.build_auth_transaction)
  end
end
