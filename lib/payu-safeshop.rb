require 'hashutils'

class PayUSafeShop
  def initialize(config_path)
    @config = YAML.load_file(config_path)['safeshop']
    @primary_key = @config['primary_key']
    @secondary_key = @config['secondary-key']
    @post_url = @config['url']
  end
  
  def build_auth_transaction
    { 'Safe' => 
      { 'Merchant' => { 'SafeKey' => @primary_key },
        'Transactions' => 
        { 'Auth' => 
          { 'MerchantReference' => '',
            'MerchantOrderNr' => '',
            'Amount' => '',
            'CardHolderName' => '',
            'BuyerCreditCardNr' => '',
            'BuyerCreditCardExpireDate' => '',
            'BuyerCreditCardCVV2' => '',
            'BuyerCreditCardBudgetTerm' => '',
            'CurrencyCode' => '',
            'VatCost' => '',
            'VatShippingCost' => '',
            'ShipperCost' => '',
            'SURCharge' => '',
            'SafeTrack' => '',
            'Secure3D_XID' => '',
            'Secure3D_CAVV' => '',
            'AdditionalInfo1' => '',
            'AdditionalInfo2' => '',
            'LiveTransaction' => '',
            'CallCentre' => '',
            'TerminalID' => '',
            'MemberGUID' => '',
            'Member' => 
            {
              'MemberEmailHTML' => '',
              'MemberEmail' => '',
              'MemberPhoneNumber' => '',
              'MemberFaxNumber' => '',
              'MemberCellNumber' => '',
              'MemberIDNr' => '',
              'MemberTitle' => '',
              'MemberRealName' => '',
              'MemberRealSurname' => '',
              'MemberGender' => '',
              'MemberAge' => '',
              'AddressName' => '',
              'RecepientName' => '',
              'RecepientIDNumber' => '',
              'RecipientContactNumber' => '',
              'DeliveryAddressStreetName' => '',
              'MemberSuburb' => '',
              'MemberCity' => '',
              'MemberCountry' => '',
              'MemberPostalCode' => '',
              'MemberActivationEmail' => ''
            },
            'BasketLineItem' => 
            {
              'SKUNr' => '',
              'ProductName' => '',
              'ProductPrice' => '',
              'ProductQty' => '',
              'ProductUrl' => '',
              'GiftTo' => '',
              'GiftMessage' => '',
              'AdditionalText' => '',
              'AffiliateID' => ''
            }
          } 
        },
        'RedirectURL' => ''
      }
    }.to_xml(:pretty => true)
  end
end