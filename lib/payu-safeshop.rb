require 'hashutils'
require 'curb'

module PayUSafeShop
  
  def self.config(config_path)
    @config = YAML.load_file(config_path)['safeshop']
    @primary_key = @config['primary-key']
    @secondary_key = @config['secondary-key']
    @curb = Curl::Easy.new(@config['url'])
  end  

  def self.get_config
    @config
  end

  def self.transaction
    Transaction.new(:primary_key => @primary_key, :curb => @curb, :config => @config )
  end

  class Transaction
    
    attr_accessor :reference, :order_no, :amount, :card_holder_name, :cc_no, :cc_exp_date, :cc_cvv, 
                  :cc_budget_term, :currency_code, :vat_cost, :vat_shipping_cost, :shipper_cost, 
                  :surcharge, :safetrack, :secure3d_xid, :secure3d_cavv, :info1, :info2, :live,
                  :call_centre, :term_id, :member_guid, :redirect_url, :safepay_ref, :bank_ref, :receipt,
                  :status, :error
                  
    def initialize(options = {})
      @primary_key = options[:primary_key]
      @config = options[:config]
      @curb = options[:curb]
      @amount ||= 0
      @status = "New"
    end
    
    def save
      { :settings => {
          :reference => @reference, 
          :order_no => @order_no, 
          :amount => @amount, 
          :currency_code => @currency_code, 
          :vat_cost => @vat_cost, 
          :vat_shipping_cost => @vat_shipping_cost, 
          :shipper_cost => @shipper_cost, 
          :surcharge => @surcharge, 
          :safetrack => @safetrack, 
          :info1 => @info1, 
          :info2 => @info2, 
          :live => @live,
          :call_centre => @call_centre, 
          :term_id => @term_id, 
          :member_guid => @member_guid, 
          :redirect_url => @redirect_url, 
          :safepay_ref => @safepay_ref, 
          :bank_ref => @bank_ref, 
          :receipt => @curb.escape(@receipt),
          :status => @status
        }
      }.to_xml
    end
    
    def load(xml_string)
      loaded_settings = {}
      loaded_settings.from_xml!(xml_string.gsub(/[\r\n\t]/, ''))
      loaded_settings.each do |key, val|
        self.send("#{key}=", val)
      end
    end
  
    def auth
      if @status != "New"
        return false
      end
      transaction = self.build_auth_transaction
      @curb.http_post(transaction)
      result = Hash.new.from_xml(@curb.body_str.gsub(/[\r\n\t]/, ''))
      p result
      if result[:Transactions] && result[:Transactions][:TransactionResult] == "Successful"
        @status = "Authed"
        @safepay_ref = result[:Transactions][:SafePayRefNr]
        @bank_ref = result[:Transactions][:BankRefNr]
        @receipt = result[:Transactions][:ReceiptURL]
        return true
      elsif result[:Transactions] && result[:Transactions][:TransactionResult] == "Failed"
        @error = result[:Transactions][:TransactionErrorResponse]
        return false
      else
        @error = result[:Error]
        return false
      end
    end
  
    def settle
      if @status != "Authed"
        return false
      end
      transaction = self.build_settle_transaction
      @curb.http_post(transaction)
      result = Hash.new.from_xml(@curb.body_str.gsub(/[\r\n\t]/, ''))
      if result[:Transactions] && result[:Transactions][:TransactionResult] == "Successful"
        @safepay_ref = result[:Transactions][:SafePayRefNr]
        @status = "Settled"
        return true
      elsif result[:Transactions] && result[:Transactions][:TransactionResult] == "Failed"
        @error = result[:Transactions][:TransactionErrorResponse]
        return false
      else
        @error = result[:Error]
        return false
      end
    end      
  
    def build_settle_transaction
      settle = { 'Safe' =>
        { 'Merchant' => { 'SafeKey' => @primary_key },
          'Transactions' =>
          { 'Settle' => 
            { 'MerchantReference' => @reference,
              'SafePayRefNr' => @safepay_ref,
              'Amount' => (@amount.to_f * 100).to_i,
              'BankRefNr' => @bank_ref
            }
          }
        }
      }.to_xml(:root => 'Safe')
      return "<?xml version=\"1.0\" ?>\r\n"+settle
    end
  
    def build_auth_transaction
      card_holder_name = @config['mode'] == 'test' ? @config['test-cc-user'] : @card_holder_name
      cc_no = @config['mode'] == 'test' ? @config['test-cc-no'] : @cc_no
      cc_exp_date = @config['mode'] == 'test' ? @config['test-cc-exp'] : @cc_exp_date.strftime("%m%Y")
      cc_cvv = @config['mode'] == 'test' ? @config['test-cc-cvv'] : @cc_cvv
      auth = { 'Safe' => 
        { 'Merchant' => { 'SafeKey' => @primary_key },
          'Transactions' => 
          { 'Auth' => 
            { 'MerchantReference' => @reference,
              'MerchantOrderNr' => @order_no,
              'Amount' => (@amount.to_f * 100).to_i,
              'CardHolderName' => card_holder_name,
              'BuyerCreditCardNr' => cc_no,
              'BuyerCreditCardExpireDate' => cc_exp_date ? cc_exp_date : Time.now.strftime("%m%Y"),
              'BuyerCreditCardCVV2' => cc_cvv,
              'BuyerCreditCardBudgetTerm' => @cc_budget_term,
              'CurrencyCode' => @currency_code,
              'VatCost' => @vat_cost,
              'VatShippingCost' => @vat_shipping_cost,
              'ShipperCost' => @shipper_cost,
              'SURCharge' => @surcharge,
              'SafeTrack' => @safetrack,
              'Secure3D_XID' => @secure3d_xid,
              'Secure3D_CAVV' => @secure3d_cavv,
              'AdditionalInfo1' => @info1,
              'AdditionalInfo2' => @info2,
              'LiveTransaction' => @config['mode'] == 'live' ? true : false,
              'CallCentre' => @call_centre,
              'TerminalID' => @term_id,
              'MemberGUID' => @member_guid,
              'RedirectURL' => @redirect_url
            }
          }
        }
      }.to_xml(:root => 'Safe')
      return "<?xml version=\"1.0\" ?>\r\n"+auth
    end
  end
end