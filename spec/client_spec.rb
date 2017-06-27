require "helper"

describe Dacom::Client do
  let(:client) { Dacom::Client.new(config: Stubs.config, net_klass: Stubs::HTTP, res_klass: Stubs::Response, time: Stubs.time, uuid: Stubs.uuid, logger: Logger.new(STDOUT)) }

  it "must initialize from data" do
    %w[LGD_TXID LGD_AUTHCODE LGD_MID].each do |k|
    end
    client.form_data["LGD_TXID"].must_equal "lgdacomxpay-0120170626093059aabada32496180db0e430eeded11f6c17883f1ff"
    client.form_data["LGD_AUTHCODE"].must_equal "e77f8a2a9a3128c5386d57590557efa16337d0d2"
    client.form_data["LGD_MID"].must_equal "lgdacomxpay"
  end

  it "must allow to set form data attributes" do
    client.set("LGD_TXNAME", "PaymentByKey")
    client.form_data["LGD_TXNAME"].must_equal "PaymentByKey"
  end

  it "must return a response object" do
    res = client.tx
    res.must_be_instance_of Stubs::Response
    res.to_s.must_equal "path=/xpay/Gateway.do; user_agent=xpayclient (1.1.0.2/ruby); form_data={\"LGD_TXID\"=>\"lgdacomxpay-0120170626093059aabada32496180db0e430eeded11f6c17883f1ff\", \"LGD_AUTHCODE\"=>\"e77f8a2a9a3128c5386d57590557efa16337d0d2\", \"LGD_MID\"=>\"lgdacomxpay\"}"
  end

  it "must detect JSON parse error" do
    res = client.tx do |_, res|
      res.body = "{{}}"
    end
    res.must_be_instance_of Stubs::Response
    res.code.must_equal "40001"
  end

  it "must detect timeout error" do
    res = client.tx do |_, _|
      fail Timeout::Error, "tick tock, time expired!"
    end
    res.must_be_instance_of Stubs::Response
    res.to_s.must_equal "code=20009; message=tick tock, time expired!"
  end

  it "must detect socket error" do
    res = client.tx do |_, _|
      fail SocketError, "this socket ain't a rocket"
    end
    res.must_be_instance_of Stubs::Response
    res.to_s.must_equal "code=20002; message=this socket ain't a rocket"
  end

  it "must detect SSL error" do
    res = client.tx do |_, _|
      fail OpenSSL::SSL::SSLError, "SSL is not open"
    end
    res.must_be_instance_of Stubs::Response
    res.to_s.must_equal "code=20101; message=SSL is not open"
  end

  it "must detect HTTP code error" do
    res = client.tx do |_, res|
      res.code = 501
    end
    res.must_be_instance_of Stubs::Response
    res.to_s.must_equal "code=30501; message=invalid HTTP code 501"
  end

  it "must detect standard error" do
    res = client.tx do |_, _|
      fail StandardError, "connection refused"
    end
    res.must_be_instance_of Stubs::Response
    res.to_s.must_equal "code=20004; message=connection refused"
  end

  it "must rollback on error" do
    client.tx do |_, _|
      fail StandardError, "connection refused"
    end
    client.rolled_back.must_equal true
  end

  it "must report on error" do
    client.tx do |_, _|
      fail StandardError, "connection refused"
    end
    client.reported.must_equal true
  end

  describe Dacom::RollbackClient do
    let(:parent_id) { "tlgdacomclient-0120160325130702b98baede1e65a67fd73b6b77f6a2bde147feaf12" }
    let(:rollback) { Dacom::RollbackClient.new(config: Stubs.config, net_klass: Stubs::HTTP, res_klass: Stubs::Response, parent_id: parent_id, reason: "something went wrong") }

    it "must initialize from data" do
      rollback.form_data["LGD_TXID"].must_equal parent_id
      rollback.form_data["LGD_TXNAME"].must_equal "Rollback"
      rollback.form_data["LGD_RB_REASON"].must_equal "something went wrong"
    end

    it "must prevent rollback and report" do
      rollback.tx do |_, _|
        fail StandardError, "connection refused"
      end
      rollback.rolled_back.must_be_nil
      rollback.reported.must_be_nil
    end
  end

  describe Dacom::ReportClient do
    let(:report) { Dacom::ReportClient.new(config: Stubs.config, net_klass: Stubs::HTTP, res_klass: Stubs::Response, status: "30199", message: "invalid HTTP code 199") }

    it "must initialize from data" do
      report.form_data["LGD_TXNAME"].must_equal "Report"
      report.form_data["LGD_STATUS"].must_equal "30199"
      report.form_data["LGD_MSG"].must_equal "invalid HTTP code 199"
    end

    it "must prevent rollback and report" do
      report.tx do |_, _|
        fail StandardError, "connection refused"
      end
      report.rolled_back.must_be_nil
      report.reported.must_be_nil
    end
  end
end
