require 'net/https'
require 'uri'
require 'openssl'
require 'json'
require 'logger'
require 'dacom/config'
require 'dacom/constants'
require 'dacom/response'

module Dacom
  class Client
    include Constants

    LOGGER_PATH = File::expand_path("../../../log/dacom.log", __FILE__)

    class ResponseError < StandardError; end
    class HTTPCodeError < StandardError; end

    attr_reader :response, :form_data

    def initialize(options = {})
      @config = options.fetch(:config) { Config::new }
      @logger = options.fetch(:logger) { Logger::new(LOGGER_PATH) }
      @mid = @config.merchant_id
      @mert_key = @config.merchant_key
      @auto_rollback = @config.auto_rollback
      @report_error = @config.report_error
      @endpoint = @config.url
      @tx_id = gen_tx_id
      @auth_code = gen_auth_code
      @form_data = init_form_data
    end

    def tx
      json = do_request
      data = parse_response(json)
      @response = Response::new(data)
    rescue ResponseError => e
      @logger.error("rescue from ResponseError - #{e.message} \n #{e.backtrace.join("\n")}")
      rollback
      report
      @response
    end

    def set(k, v)
      @form_data[k] = v
    end

    private

    def rollback
      return unless @auto_rollback
      rollback_client = RollbackClient::new(:config => @config, 
                                            :parent_id => @tx_id, 
                                            :reason => rollback_reason)
      Thread::new { rollback_client.tx }
    end

    def report
      return unless @report_error
      report_client = ReportClient::new(:config => @config,
                                        :status => @response.code,
                                        :message => @response.message)
      Thread::new { report_client.tx }
    end

    def parse_response(json)
      JSON::parse(json)
    rescue JSON::ParserError => e
      set_response_and_raise(LGD_ERR_JSON_DECODE, e)
    end

    def init_form_data
      { "LGD_TXID" => @tx_id, "LGD_AUTHCODE" => @auth_code, "LGD_MID" => @mid }
    end

    def gen_tx_id
      sha = OpenSSL::Digest::SHA1.new
      sha.update(get_unique)
      "#{tx_header}#{sha}"
    end

    def gen_auth_code
      sha = OpenSSL::Digest::SHA1.new
      sha.update("#{@tx_id}#{@mert_key}").to_s
    end

    def tx_header
      "#{@mid}-#{@config.server_id}#{timestamp}"
    end

    def get_unique
      "#{timestamp}#{rand_three_digits}"
    end

    def rand_three_digits
      "%03d" % rand(1000)
    end

    def timestamp
      Time.now.getutc.strftime("%Y%m%d%H%M%S")
    end

    def rollback_reason
      return "Timeout" if @response.code == LGD_ERR_TIMEDOUT
      return "HTTP #{@http_code}" if @http_code >= 500
      @response.message
    end

    def do_request
      req, http = prepare_http_client
      @logger.info("do_request(#{@endpoint}) - #{@form_data.inspect}")
      res = http.request(req)
      set_http_code(res.code) 
      res.body
    rescue Timeout::Error => e
      set_response_and_raise(LGD_ERR_TIMEDOUT, e)
    rescue SocketError => e
      set_response_and_raise(LGD_ERR_RESOLVE_HOST, e)
    rescue OpenSSL::SSL::SSLError => e
      set_response_and_raise(LGD_ERR_SSL, e)
    rescue HTTPCodeError => e
      set_response_and_raise("#{30000+@http_code}", e)
    rescue StandardError => e
      set_response_and_raise(LGD_ERR_CONNECT, e)
    end

    def set_response_and_raise(code, e)
      @response = Response::new(:code => code, :message => e.message)
      @logger.error("rescue from #{e.class} - #{e.message} \n #{e.backtrace.join("\n")}")
      raise ResponseError, e.message
    end

    def prepare_http_client
      url = URI.parse(@endpoint)
      req = Net::HTTP::Post.new(url.path)
      req["User-Agent"] = LGD_USER_AGENT
      req.set_form_data(@form_data)
      http = Net::HTTP.new(url.host, url.port)
      http.open_timeout = http.read_timeout = @config.timeout
      if url.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER if @config.verify_peer?
      end
      [req, http]
    end

    def set_http_code(code)
      @http_code = code.to_i
      fail HTTPCodeError, "invalid HTTP code #{code}" unless http_code_valid?
    end

    def http_code_valid?
      (200...300) === @http_code
    end
  end

  class EventClient < Client
    def initialize(options = {})
      super(options)
      @auto_rollback = false
      @report_error = false
    end
  end

  class RollbackClient < EventClient
    def initialize(options = {})
      @parent_id = options.fetch(:parent_id) { fail ArgumentError, "missing parent ID" }
      @reason = options.fetch(:reason) { fail ArgumentError, "missing parent reason" }
      super(options)
    end

    private

    def init_form_data
      super.merge({ "LGD_TXID" => @parent_id, "LGD_TXNAME" => "Rollback", "LGD_RB_TXID" => @tx_id, "LGD_RB_REASON" => @reason })
    end
  end

  class ReportClient < EventClient
    def initialize(options = {})
      @status = options.fetch(:status) { fail ArgumentError, "missing status" }
      @message = options.fetch(:message) { fail ArgumentError, "missing message" }
      super(options)
      @endpoint = @config.aux_url
    end

    private

    def init_form_data
      super.merge({ "LGD_TXNAME" => "Report", "LGD_STATUS" => @status, "LGD_MSG" => @message })
    end
  end
end
