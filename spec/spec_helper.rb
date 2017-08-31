def stub_faraday_request(conn, &stubs_block)
  adapter_handler = conn.builder.handlers.find { |h| h.klass < Faraday::Adapter }
  conn.builder.swap(adapter_handler, Faraday::Adapter::Test, &stubs_block)
end