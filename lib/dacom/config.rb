require "erb"
require "yaml"

module Dacom
  class Config
    module Platform
      %w[test service].each do |platform|
        Platform.const_set(platform.upcase, platform)
      end
    end

    def initialize(path = "~/dacom.yml")
      @path = File.expand_path(path)
      @config = fetch_config
    end

    %w[server_id timeout verify_cert verify_host auto_rollback report_error aux_url].each do |msg| 
      define_method(msg) do
        @config.fetch(msg) { fail ArgumentError, "missing #{msg}"}
      end
    end

    def url
      return @config.fetch("test_url") if test_mode?
      @config.fetch("url")
    end

    def merchant_id
      return @config.fetch("test_mert_id") if test_mode?
      @config.fetch("mert_id")
    end

    def merchant_key
      return @config.fetch("test_mert_key") if test_mode?
      @config.fetch("mert_key")
    end

    def platform
      return Platform::TEST if test_mode?
      Platform::SERVICE
    end

    def verify_peer?
      verify_cert || verify_host
    end

    private

    def test_mode?
      @config["test_mode"]
    end

    def fetch_config
      return {} unless File.exist?(@path)
      YAML.load(ERB.new(File.read(@path)).result)
    end
  end
end
