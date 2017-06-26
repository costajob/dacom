require "yaml"

module Stubs
  extend self

  class Response
    attr_reader :code, :message
    attr_accessor :body

    def initialize(options)
      @code = options[:code]
      @message = options[:message]
      @path = options["path"]
      @user_agent = options["User-Agent"]
      @form_data = options["form_data"]
    end

    def to_s
      [].tap do |res|
        res << "code=#{@code}" if @code
        res << "message=#{@message}" if @message
        res << "path=#{@path}" if @path
        res << "user_agent=#{@user_agent}" if @user_agent
        res << "form_data=#{@form_data}" if @form_data
      end.join("; ")
    end
  end

  class HTTP
    attr_accessor :host, :port, :verify_mode, :use_ssl, :open_timeout, :read_timeout

    def initialize(host, port)
      @host, @port = host, port
    end

    def request(payload)
      Response.new(code: 200).tap do |res|
        res.body = payload.to_json
      end
    end

    class Post
      attr_accessor :data

      def initialize(path, data = {})
        @data = data
        @data["path"] = path
      end

      def []=(k,v)
        @data[k] = v
      end

      def set_form_data(data)
        @data["form_data"] = data
      end

      def to_json
        @data.to_json
      end
    end
  end

  def time
    Time.new(2017,6,26,10,30,59)
  end

  def uuid
    "3bc03ef5-b9c9-418e-94df-b2cdd64dd542"
  end

  def config
    @config ||= OpenStruct.new(url: "https://xpayclient.lgdacom.net/xpay/Gateway.do", merchant_id: "lgdacomxpay", merchant_key: "live_key", platform: "service", verify_peer?: true, server_id: "01", timeout: 60, verify_cert: true, verify_host: true, auto_rollback: true, report_error: true, aux_url: "http://xpay.lgdacom.net:7080/xpay/Gateway.do")
  end

  def config_data
    {"url"=>"https://xpayclient.lgdacom.net/xpay/Gateway.do","test_url"=>"https://xpayclient.lgdacom.net:7443/xpay/Gateway.do","aux_url"=>"http://xpay.lgdacom.net:7080/xpay/Gateway.do","server_id"=>"01","timeout"=>60,"verify_cert"=>true,"verify_host"=>true,"report_error"=>true,"auto_rollback"=>true,"mert_id"=>"lgdacomxpay","mert_key"=>"live_key","test_mert_id"=>"tlgdacomxpay","test_mert_key"=>"test_key","test_mode"=>true}
  end

  def config_test
    Tempfile.new(%w[test .yml]).tap do |config|    
      config << config_data.to_yaml
      config.rewind
    end
  end

  def config_live
    Tempfile.new(%w[live .yml]).tap do |config| 
      config << config_data.merge("test_mode"=>false).to_yaml
      config.rewind
    end
  end

  def response_ok
    {"LGD_RESPONSE"=>[{"LGD_RESPCODE"=>"XC01", "LGD_RESPMSG"=>"LGD_TXNAME \355\225\204\353\223\234\352\260\200 \353\210\204\353\235\275\353\220\230\354\227\210\354\212\265\353\213\210\353\213\244."}], "LGD_RESPCODE"=>"XC01", "LGD_RESPMSG"=>"LGD_TXNAME \355\225\204\353\223\234\352\260\200 \353\210\204\353\235\275\353\220\230\354\227\210\354\212\265\353\213\210\353\213\244."}
  end
end
