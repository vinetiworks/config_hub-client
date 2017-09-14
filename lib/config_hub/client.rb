require 'faraday'
require 'active_support'
require 'active_support/core_ext/string'
require 'active_support/json/encoding'

module ConfigHub
  class Client
    def initialize(server_url, token, context, options = {})
      @token = token
      @context = context
      @options = options
      env = options[:environment] || defined?(Rails) ? Rails.env : 'development'
      faraday_opts = options[:faraday] || {}
      @conn = Faraday.new(server_url, ssl: { verify: env == 'production' }.merge(faraday_opts), headers: headers)
    end

    def pull
      @data = retrieve_remote_config
    end

    def config_pulled?
      !@data.nil?
    end

    def fetch(key)
      if config_pulled?
        val = @data.dig('properties', key.to_s, 'val')
        if val.nil?
          yield if block_given? && !@data['properties'].key?(key.to_s)
        else
          val
        end
      else
        raise ConfigNotPulledError
      end
    end

    def to_h
      if config_pulled?
        @data['properties'].reduce({}) do |hash, (k, v)|
          hash.merge(k => v['val'])
        end
      else
        raise ConfigNotPulledError
      end
    end

    private

    def retrieve_remote_config
      res = @conn.get('/rest/pull')
      if res.status == 200
        JSON.parse(res.body)
      else
        raise RequestError.new('Could not pull config', res)
      end
    end

    def headers
      header_format({
        client_token: @token,
        context: @context
      }.merge(@options[:headers] || {}))
    end

    def header_format(hash)
      hash.map { |k, v| [k.to_s.titleize.tr(' ', '-'), v] }.to_h
    end
  end

  class RequestError < StandardError
    def initialize(message, response)
      @message = message
      @reason = "#{response.reason_phrase} - #{response.headers['etag']}"
    end

    def message
      "#{@message}: #{@reason}"
    end
  end

  class ConfigNotPulledError < StandardError
    def message
      'Configuration was not loaded from ConfigHub server (use .pull)'
    end
  end
end
