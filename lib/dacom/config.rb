require 'yaml'
require 'erb'

module Dacom
  class Config
    CONFIG_PATH = File::expand_path("../../../config/dacom.yml", __FILE__)

    def initialize(path = CONFIG_PATH)
      @path = path
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
      return "test".freeze if test_mode?
      "service".freeze
    end

    def verify_peer?
      verify_cert || verify_host
    end

    private

    def test_mode?
      @config.fetch("test_mode") { false }
    end

    def fetch_config
      return {} unless File.exist?(@path)
      YAML.load(ERB.new(File.read(@path)).result)
    end
  end
end
