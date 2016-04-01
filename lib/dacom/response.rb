module Dacom
  class Response
    attr_reader :code, :message, :raw

    SUCCESS_CODE = "0000".freeze

    def initialize(data = {})
      @code = data.fetch("LGD_RESPCODE") { data[:code] }
      @message = data.fetch("LGD_RESPMSG") { data[:message] }
      @raw = data.fetch("LGD_RESPONSE") { [] }
    end

    def data
      @raw.first
    end

    def successful?
      @code == SUCCESS_CODE
    end
  end
end
