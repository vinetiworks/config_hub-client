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
      if has?(key)
        item = @data['properties'][key.to_s]
        cast item['val'], item['type']
      elsif block_given?
        yield
      end
    end

    def fetch_file(key)
      if config_pulled? && @data['files'].present?
        @data.dig('files', key, 'content')
      else
        retrieve_remote_file(key)
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

    def has?(key)
      if config_pulled?
        props = @data['properties']
        props && props.key?(key.to_s)
      else
        raise ConfigNotPulledError
      end
    end

    private

    def cast(val, type)
      case type
      when 'Boolean'
        val == 'true'
      when 'Integer', 'Long'
        val.to_i
      when 'Float', 'Double'
        val.to_f
      when 'JSON'
        JSON.parse(val)
      else
        val
      end
    end

    def retrieve_remote_file(key)
      res = @conn.get('/rest/rawFile') do |req|
        req.headers['File'] = key
      end
      if res.status == 200
        res.body
      elsif res.status == 204
        nil
      else
        raise RequestError.new('Could not retrieve raw file', res)
      end
    end

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
