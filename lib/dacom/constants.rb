module Dacom
  module Constants
    extend self

    def all
      {
        "lgd_user_agent" => "xpayclient (1.1.0.2/ruby)",
        "lgd_log_fatal" => 0,
        "lgd_log_error" => 1,
        "lgd_log_warn" => 2,
        "lgd_log_info" => 3,
        "lgd_log_debug" => 4,
        "lgd_err_no_home_dir" => "10001",
        "lgd_err_no_mall_config" => "10002",
        "lgd_err_no_lgdacom_config" => "10003",
        "lgd_err_no_mid" => "10004",
        "lgd_err_out_of_memory" => "10005",
        "lgd_err_http_url" => "20001",
        "lgd_err_resolve_host" => "20002",
        "lgd_err_resolve_proxy" => "20003",
        "lgd_err_connect" => "20004",
        "lgd_err_write" => "20005",
        "lgd_err_read" => "20006",
        "lgd_err_send" => "20007",
        "lgd_err_recv" => "20008",
        "lgd_err_timedout" => "20009",
        "lgd_err_ssl" => "20101",
        "lgd_err_curl" => "20201",
        "lgd_err_json_decode" => "40001"
      }
    end

    def included(klass)
      all.each do |k,v|
        klass::const_set(k.upcase, v)
      end
    end
  end
end
