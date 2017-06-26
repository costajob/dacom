require "helper"

describe Dacom::Config do
  let(:config_test) { Dacom::Config.new(Stubs.config_test.path) }
  let(:config_live) { Dacom::Config.new(Stubs.config_live.path) }

  it "must return server id" do
    config_test.server_id.must_equal "01"
  end

  it "must return aux url" do
    config_test.aux_url.must_equal "http://xpay.lgdacom.net:7080/xpay/Gateway.do"
  end

  it "must return timeout" do
    config_test.timeout.must_equal 60
  end

  it "must return verify cert" do
    config_test.verify_cert.must_equal true
  end

  it "must return report error" do
    config_test.report_error.must_equal true
  end

  it "must return verify host" do
    config_test.verify_host.must_equal true
  end

  it "must verify peer" do
    config_test.verify_peer?.must_equal true
  end

  it "must return auto rollback" do
    config_test.auto_rollback.must_equal true
  end

  it "must return test url" do
    config_test.url.must_equal "https://xpayclient.lgdacom.net:7443/xpay/Gateway.do"
  end

  it "must return test merchant id" do
    config_test.merchant_id.must_equal "tlgdacomxpay"
  end

  it "must return test merchant key" do
    config_test.merchant_key.must_equal "test_key"
  end

  it "must return test platform" do
    config_test.platform.must_equal Dacom::Config::Platform::TEST
  end

  it "must return live url" do
    config_live.url.must_equal "https://xpayclient.lgdacom.net/xpay/Gateway.do"
  end

  it "must return live merchant id" do
    config_live.merchant_id.must_equal "lgdacomxpay"
  end

  it "must return live merchant key" do
    config_live.merchant_key.must_equal "live_key"
  end

  it "must return live platform" do
    config_live.platform.must_equal Dacom::Config::Platform::SERVICE
  end
end
