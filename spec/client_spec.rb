require "helper"

describe Dacom::Client do
  let(:io) { StringIO.new }
  let(:client) { Dacom::Client.new(config: Stubs.config, net_klass: Stubs::HTTP, res_klass: Stubs::Response, logger: Logger.new(io), time: Stubs.time, uuid: Stubs.uuid) }

  it "must initialize from data" do
    %w[LGD_TXID LGD_AUTHCODE LGD_MID].each do |k|
    end
    client.form_data["LGD_TXID"].must_equal "lgdacomxpay-0120170626083059aabada32496180db0e430eeded11f6c17883f1ff"
    client.form_data["LGD_AUTHCODE"].must_equal "073a7220393168c4cd69013bd804a02f62689649"
    client.form_data["LGD_MID"].must_equal "lgdacomxpay"
  end

  it "must allow to set form data attributes" do
    client.set("LGD_TXNAME", "PaymentByKey")
    client.form_data["LGD_TXNAME"].must_equal "PaymentByKey"
  end

  it "must return a response object" do
    res = client.tx
    res.must_be_instance_of Stubs::Response
    res.to_s.must_equal "path=/xpay/Gateway.do; user_agent=xpayclient (1.1.0.2/ruby); form_data={\"LGD_TXID\"=>\"lgdacomxpay-0120170626083059aabada32496180db0e430eeded11f6c17883f1ff\", \"LGD_AUTHCODE\"=>\"073a7220393168c4cd69013bd804a02f62689649\", \"LGD_MID\"=>\"lgdacomxpay\"}"
  end

  it "must detect response parse error" do
    res = client.tx do |_, _|
      fail JSON::ParserError, "your JSON is awful!"
    end
    res.must_be_instance_of Stubs::Response
    res.to_s.must_equal "code=20004; message=your JSON is awful!"
  end

  describe "#tx" do
    it "must intercept timeout error" do
      skip
      stub(client).prepare_http_client { fail Timeout::Error, "timeout!" }
      mock(client).rollback
      mock(client).report
      res = client.tx
      res.must_be_instance_of Dacom::Response
      res.code.must_equal Dacom::Client::LGD_ERR_TIMEDOUT
      res.message.must_equal "timeout!"
    end

    it "must intercept socket error" do
      skip
      stub(client).prepare_http_client { fail SocketError, "bad socket" }
      mock(client).rollback
      mock(client).report
      res = client.tx
      res.must_be_instance_of Dacom::Response
      res.code.must_equal Dacom::Client::LGD_ERR_RESOLVE_HOST
      res.message.must_equal "bad socket"
    end

    it "must intercept SSL errors" do
      skip
      stub(client).prepare_http_client { fail OpenSSL::SSL::SSLError, "invalid certificate" }
      mock(client).rollback
      mock(client).report
      res = client.tx
      res.must_be_instance_of Dacom::Response
      res.code.must_equal Dacom::Client::LGD_ERR_SSL
      res.message.must_equal "invalid certificate"
    end

    it "must intercept invalid HTTP codes" do
      skip
      http = Class.new { def self.request(_); OpenStruct.new(:code => "199", :body => "{}"); end }
      stub(client).prepare_http_client { [_, http] }
      mock(client).rollback
      mock(client).report
      res = client.tx
      res.must_be_instance_of Dacom::Response
      res.code.must_equal "30199" 
      res.message.must_equal "invalid HTTP code 199"
    end

    it "must intercept connection refused error" do
      skip
      stub(client).prepare_http_client { fail "doh!" }
      mock(client).rollback
      mock(client).report
      res = client.tx
      res.must_be_instance_of Dacom::Response
      res.code.must_equal Dacom::Client::LGD_ERR_CONNECT
      res.message.must_equal "doh!"
    end

    it "must intercept JSON parse error" do
      skip
      http = Class.new { def self.request(_); OpenStruct.new(:code => "200", :body => "wrong!"); end }
      stub(client).prepare_http_client { [_, http] }
      mock(client).rollback
      mock(client).report
      res = client.tx
      res.must_be_instance_of Dacom::Response
      res.code.must_equal Dacom::Client::LGD_ERR_JSON_DECODE
      res.message.must_match /'wrong!'/
    end

    it "must return a response object at the end" do
      skip
      http = Class.new { def self.request(_); OpenStruct.new(:code => "200", :body => "\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n{\"LGD_RESPCODE\":\"XC01\",\"LGD_RESPMSG\":\"LGD_TXNAME \355\225\204\353\223\234\352\260\200 \353\210\204\353\235\275\353\220\230\354\227\210\354\212\265\353\213\210\353\213\244.\",\"LGD_RESPONSE\":[{\"LGD_RESPCODE\":\"XC01\",\"LGD_RESPMSG\":\"LGD_TXNAME \355\225\204\353\223\234\352\260\200 \353\210\204\353\235\275\353\220\230\354\227\210\354\212\265\353\213\210\353\213\244.\"}]}\n"); end }
      stub(client).prepare_http_client { [_, http] }
      dont_allow(client).rollback
      dont_allow(client).report
      res = client.tx
      res.must_be_instance_of Dacom::Response
      res.code.must_equal "XC01"
      res.message.must_match /^LGD_TXNAME/
    end
  end
end

describe Dacom::RollbackClient do
  let(:logger) { Logger.new(nil) }
  let(:parent_id) { "tlgdacomclient-0120160325130702b98baede1e65a67fd73b6b77f6a2bde147feaf12" }
  let(:rollback) { Dacom::RollbackClient.new(:parent_id => parent_id, :reason => "something went wrong", :logger => logger) }

  it "must initialize from data" do
    skip
    %w[LGD_AUTHCODE LGD_MID LGD_RB_TXID].each do |k|
      assert rollback.form_data[k]
    end
    rollback.form_data["LGD_TXID"].must_equal parent_id
    rollback.form_data["LGD_TXNAME"].must_equal "Rollback"
    rollback.form_data["LGD_RB_REASON"].must_equal "something went wrong"
  end

  it "must prevent rollback and report" do
    skip
    refute rollback.send(:rollback)
    refute rollback.send(:report)
  end
end

describe Dacom::ReportClient do
  let(:logger) { Logger.new(nil) }
  let(:report) { Dacom::ReportClient.new(:status => "30199", :message => "invalid HTTP code 199", :logger => logger) }

  it "must initialize from data" do
    skip
    %w[LGD_TXID LGD_AUTHCODE LGD_MID].each do |k|
      assert report.form_data[k]
    end
    report.form_data["LGD_TXNAME"].must_equal "Report"
    report.form_data["LGD_STATUS"].must_equal "30199"
    report.form_data["LGD_MSG"].must_equal "invalid HTTP code 199"
  end

  it "must prevent rollback and report" do
    skip
    refute report.send(:rollback)
    refute report.send(:report)
  end
end
