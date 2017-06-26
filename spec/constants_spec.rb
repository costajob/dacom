require "helper"

describe Dacom::Constants do
  it "must define constants" do
    klass = Class.new { include Dacom::Constants }
    Dacom::Constants::all.each do |k,v|
      klass::const_get(k.upcase).must_equal v
    end
  end
end
