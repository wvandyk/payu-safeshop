require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "PayuSafeshop" do
  before(:all) do
    PayUSafeShop.config(File.dirname(__FILE__) + '/test_config.yml')
    @t = PayUSafeShop.transaction    
  end
  
  it "should give us a transaction object" do
    @t.class.should == PayUSafeShop::Transaction
  end

  it "should generate xml for the auth call" do
    @t.amount = 12.50
    @t.build_auth_transaction.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?><Safe><Merchant><SafeKey>#{PayUSafeShop.get_config['primary-key']}</SafeKey></Merchant><Transactions><Auth><MerchantReference></MerchantReference><MerchantOrderNr></MerchantOrderNr><Amount>1250</Amount><CardHolderName>#{PayUSafeShop.get_config['test-cc-user']}</CardHolderName><BuyerCreditCardNr>#{PayUSafeShop.get_config['test-cc-no']}</BuyerCreditCardNr><BuyerCreditCardExpireDate>#{PayUSafeShop.get_config['test-cc-exp']}</BuyerCreditCardExpireDate><BuyerCreditCardCVV2>#{PayUSafeShop.get_config['test-cc-cvv']}</BuyerCreditCardCVV2><BuyerCreditCardBudgetTerm></BuyerCreditCardBudgetTerm><CurrencyCode></CurrencyCode><VatCost></VatCost><VatShippingCost></VatShippingCost><ShipperCost></ShipperCost><SURCharge></SURCharge><SafeTrack></SafeTrack><Secure3D_XID></Secure3D_XID><Secure3D_CAVV></Secure3D_CAVV><AdditionalInfo1></AdditionalInfo1><AdditionalInfo2></AdditionalInfo2><LiveTransaction>false</LiveTransaction><CallCentre></CallCentre><TerminalID></TerminalID><MemberGUID></MemberGUID><RedirectURL></RedirectURL></Auth></Transactions></Safe>"
  end

  it "should set the status to 'New' for new transactions" do
    t = PayUSafeShop.transaction
    t.status.should == 'New'
  end
  
  it "should not allow you to settle a transaction unless it has first been authed" do
    t = PayUSafeShop.transaction
    t.status.should == 'New'
    t.settle.should == false
  end    
  
  it "should generate xml for the settle call" do
    @t.build_settle_transaction.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?><Safe><Merchant><SafeKey>#{PayUSafeShop.get_config['primary-key']}</SafeKey></Merchant><Transactions><Settle><MerchantReference></MerchantReference><SafePayRefNr></SafePayRefNr><Amount>1250</Amount><BankRefNr></BankRefNr></Settle></Transactions></Safe>"
  end
  
  it "should not allow you to auth a previously authed or settled transaction" do
    @t.status = "Authed"
    @t.auth.should == false
    @t.status = "Settled"
    @t.settle.should == false
  end
  
  it "should export the most important attributes of a transaction to xml when saved" do
    # @t.save.should == "<settings><reference></reference><order_no></order_no><amount>12.5</amount><currency_code></currency_code><vat_cost></vat_cost><vat_shipping_cost></vat_shipping_cost><shipper_cost></shipper_cost><surcharge></surcharge><safetrack></safetrack><info1></info1><info2></info2><live></live><call_centre></call_centre><term_id></term_id><member_guid></member_guid><redirect_url></redirect_url><safepay_ref></safepay_ref><bank_ref></bank_ref><receipt></receipt><status>Settled</status></settings>"
    t = PayUSafeShop.transaction
    t.load(@t.save)
    t.save.should == @t.save
  end
  
  it "should be able to talk to the safeshop interface" do
    PayUSafeShop.config(File.dirname(__FILE__) + '/my_live_config.yml')
    t = PayUSafeShop.transaction
    t.amount = 1250
    t.reference = "123123test123"
    t.order_no = '123123'
    t.auth.should == true
  end
  
end
