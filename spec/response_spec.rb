# encoding: utf-8

require 'spec_helper'
require 'dacom/response'

describe Dacom::Response do
  let(:data) { {"LGD_RESPONSE"=>[{"LGD_RESPCODE"=>"XC01", "LGD_RESPMSG"=>"LGD_TXNAME \355\225\204\353\223\234\352\260\200 \353\210\204\353\235\275\353\220\230\354\227\210\354\212\265\353\213\210\353\213\244."}], "LGD_RESPCODE"=>"XC01", "LGD_RESPMSG"=>"LGD_TXNAME \355\225\204\353\223\234\352\260\200 \353\210\204\353\235\275\353\220\230\354\227\210\354\212\265\353\213\210\353\213\244."} }
  let(:res) { Dacom::Response::new(data) }

  it "must initialize attributes" do
    res.raw.must_be_instance_of Array
    res.code.must_equal "XC01"
    res.message.must_match /^LGD_TXNAME/
  end

  it "must return data as a hash" do
    res.data.must_equal data["LGD_RESPONSE"][0]
  end

  it "must accept symbol keys to initialize attributes" do
    res = Dacom::Response::new(:code => "XC01", :message => "LGD_TXNAME")
    res.raw.must_be_instance_of Array
    res.code.must_equal "XC01"
    res.message.must_match /^LGD_TXNAME/
  end

  it "must detect successful response" do
    res = Dacom::Response::new(:code => "0000", :message => "LGD_TXNAME")
    assert res.successful?
  end

  it "must print itself with intrnal state" do
    res.to_s.must_equal %Q{<Dacom::Response:#{res.__id__}, code: "XC01", message: "LGD_TXNAME 필드가 누락되었습니다.", successful: false>}
  end

  it "must set default for empty data" do
    res = Dacom::Response::new
    res.raw.must_be_empty
    refute res.code
    refute res.message
  end
end
