require "helper"

describe Dacom::Response do
  let(:res) { Dacom::Response.new(Stubs.response_ok) }

  it "must initialize attributes" do
    res.raw.must_be_instance_of Array
    res.code.must_equal "XC01"
    res.message.must_match(/^LGD_TXNAME/)
  end

  it "must return data as a hash" do
    res.data.must_equal Stubs.response_ok["LGD_RESPONSE"][0]
  end

  it "must accept symbol keys to initialize attributes" do
    res = Dacom::Response.new(code: "XC01", message: "LGD_TXNAME")
    res.raw.must_be_instance_of Array
    res.code.must_equal "XC01"
    res.message.must_match(/^LGD_TXNAME/)
  end

  it "must detect successful response" do
    res = Dacom::Response.new(code: "0000", message: "LGD_TXNAME")
    assert res.successful?
  end

  it "must print itself with intrnal state" do
    res.to_s.must_equal %Q{<Dacom::Response:#{res.__id__}, code: "XC01", message: "LGD_TXNAME 필드가 누락되었습니다.", successful: false>}
  end

  it "must set defaults for empty data" do
    res = Dacom::Response.new
    res.raw.must_be_empty
    refute res.code
    refute res.message
  end
end
