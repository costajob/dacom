module Dacom
  class Response
    SUCCESS_CODE = "0000"

    attr_reader :code, :message, :raw

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

    def to_s
      %Q{<Dacom::Response:#{__id__}, code: "#{@code}", message: "#{@message}", successful: #{successful?}>}
    end
  end
end
