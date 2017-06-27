require "forwardable"
require "json"
require "logger"
require "net/https"
require "openssl"
require "securerandom"
require "dacom/config"
require "dacom/constants"
require "dacom/response"

module Dacom
  class Client
    extend Forwardable
    include Constants

    class ResponseError < StandardError; end
    class HTTPCodeError < StandardError; end

    def_delegators :@config, :server_id, :merchant_id, :merchant_key, :verify_peer?, :timeout

    attr_reader :http, :response, :reported, :rolled_back

    def initialize(config: Config.new, net_klass: Net::HTTP, res_klass: Response, logger: Logger.new(nil), time: Time.now, uuid: SecureRandom.uuid)
      @config = config
      @net_klass = net_klass
      @res_klass = res_klass
      @logger = logger
      @time = time
      @uuid = uuid
      @auto_rollback = @config.auto_rollback
      @report_error = @config.report_error
      @endpoint = @config.url
    end

    def tx(&b)
      json = Thread.new { do_request(&b) }.value
      data = parse_response(json)
      @response = @res_klass.new(data).tap do |res|
        @logger.info("RESPONSE: #{res}")
      end
    rescue ResponseError => e
      @logger.error("rescue from ResponseError - #{e.message} \n #{e.backtrace.join("\n")}")
      rollback
      report
      @response
    end

    def set(k, v)
      form_data[k] = v
    end

    def form_data
      @form_data ||= { "LGD_TXID" => tx_id, "LGD_AUTHCODE" => auth_code, "LGD_MID" => merchant_id }
    end

    private def tx_id
      @tx_id ||= begin
                   sha = OpenSSL::Digest::SHA1.new
                   sha.update(@uuid)
                   "#{tx_header}#{sha}"
                 end
    end

    private def auth_code
      sha = OpenSSL::Digest::SHA1.new
      sha.update("#{tx_id}#{merchant_key}").to_s
    end

    private def tx_header
      "#{merchant_id}-#{server_id}#{timestamp}"
    end

    private def timestamp
      @time.utc.strftime("%Y%m%d%H%M%S")
    end

    private def rollback
      return unless @auto_rollback
      RollbackClient.new(config: @config, 
                         logger: @logger,
                         net_klass: @net_klass,
                         res_klass: @res_klass,
                         parent_id: tx_id, 
                         reason: rollback_reason).tx
      @rolled_back = true
    end

    private def report
      return unless @report_error
      ReportClient.new(config: @config,
                       logger: @logger,
                       net_klass: @net_klass,
                       res_klass: @res_klass,
                       status: @response.code,
                       message: @response.message).tx
      @reported = true
    end

    private def parse_response(json)
      JSON.parse(json)
    rescue JSON::ParserError => e
      set_response_and_raise(LGD_ERR_JSON_DECODE, e)
    end

    private def rollback_reason
      return "Timeout" if @response.code == LGD_ERR_TIMEDOUT
      return "HTTP #{@http_code}" if http_code_error?
      @response.message
    end
    
    private def do_request
      req, @http = prepare_http_client
      @logger.info("REQUEST: endpoint=#{@endpoint}; form_data=#{form_data.inspect}")
      res = http.request(req)
      yield(req, res) if block_given?
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

    private def prepare_http_client
      url = URI.parse(@endpoint)
      req = @net_klass.const_get("Post").new(url.path)
      req["User-Agent"] = LGD_USER_AGENT
      req.set_form_data(form_data)
      http = @net_klass.new(url.host, url.port)
      http.open_timeout = timeout
      http.read_timeout = timeout
      if url.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER if verify_peer?
      end
      [req, http]
    end

    private def set_http_code(code)
      @http_code = code.to_i
      fail HTTPCodeError, "invalid HTTP code #{code}" unless http_code_valid?
    end

    private def http_code_valid?
      (200...300) === @http_code.to_i
    end

    private def http_code_error?
      (500...599) === @http_code.to_i
    end

    private def set_response_and_raise(code, e)
      @response = @res_klass.new(code: code, message: e.message)
      @logger.info("RESPONSE: #{@response}")
      @logger.error("rescue from #{e.class} - #{e.message} \n #{e.backtrace.join("\n")}")
      raise ResponseError, e.message
    end
  end

  class EventClient < Client
    def initialize(config:, logger: Logger.new(nil), net_klass:, res_klass:)
      super(config: config, logger: logger, net_klass: net_klass, res_klass: res_klass)
      @auto_rollback = false
      @report_error = false
    end
  end

  class RollbackClient < EventClient
    def initialize(config:, logger: Logger.new(nil), net_klass:, res_klass:, parent_id:, reason:)
      super(config: config, logger: logger, net_klass: net_klass, res_klass: res_klass)
      @parent_id = parent_id
      @reason = reason
    end

    def form_data
      @form_data ||= super.merge({ "LGD_TXID" => @parent_id, "LGD_TXNAME" => "Rollback", "LGD_RB_TXID" => tx_id, "LGD_RB_REASON" => @reason })
    end
  end

  class ReportClient < EventClient
    def initialize(config:, logger: Logger.new(nil), net_klass:, res_klass:, status:, message:)
      super(config: config, logger: logger, net_klass: net_klass, res_klass: res_klass)
      @status = status
      @message = message
      @endpoint = @config.aux_url
    end

    def form_data
      @form_data ||= super.merge({ "LGD_TXNAME" => "Report", "LGD_STATUS" => @status, "LGD_MSG" => @message })
    end
  end
end
