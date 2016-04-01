require 'test_helper'
require 'dacom/config'

describe Dacom::Config do
  let(:data) { {"url"=>"https://xpayclient.lgdacom.net/xpay/Gateway.do","test_url"=>"https://xpayclient.lgdacom.net:7443/xpay/Gateway.do","aux_url"=>"http://xpay.lgdacom.net:7080/xpay/Gateway.do","server_id"=>"01","timeout"=>60,"verify_cert"=>true,"verify_host"=>true,"report_error"=>true,"auto_rollback"=>true,"mert_id"=>"lgdacomxpay","mert_key"=>"live_key","test_mert_id"=>"tlgdacomxpay","test_mert_key"=>"test_key","test_mode"=>true} }
  let(:yml_test) { Tempfile::new("test.yml") << data.to_yaml  }
  before { yml_test.read }
  let(:config) { Dacom::Config::new(yml_test.path) }

  it "must return server id" do
    config.server_id.must_equal "01"
  end

  it "must return aux url" do
    config.aux_url.must_equal "http://xpay.lgdacom.net:7080/xpay/Gateway.do"
  end

  it "must return timeout" do
    config.timeout.must_equal 60
  end

  it "must return verify cert" do
    assert config.verify_cert
  end

  it "must return report error" do
    assert config.report_error
  end

  it "must return verify host" do
    assert config.verify_host
  end

  it "must verify peer" do
    assert config.verify_peer?
  end

  it "must return auto rollback" do
    assert config.auto_rollback
  end

  it "must return url" do
    config.url.must_equal "https://xpayclient.lgdacom.net:7443/xpay/Gateway.do"
  end

  it "must return merchant id" do
    config.merchant_id.must_equal "tlgdacomxpay"
  end

  it "must return merchant key" do
    config.merchant_key.must_equal "test_key"
  end

  it "must return platform" do
    config.platform.must_equal "test"
  end

  describe "live mode" do
    let(:yml_live) { Tempfile::new("live.yml") << data.merge("test_mode"=>false).to_yaml }
    before { yml_live.read }
    let(:config) { Dacom::Config::new(yml_live.path) }

    it "must return url" do
      config.url.must_equal "https://xpayclient.lgdacom.net/xpay/Gateway.do"
    end

    it "must return merchant id" do
      config.merchant_id.must_equal "lgdacomxpay"
    end

    it "must return merchant key" do
      config.merchant_key.must_equal "live_key"
    end

    it "must return platform" do
      config.platform.must_equal "service"
    end
  end
end
