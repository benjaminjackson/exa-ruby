# frozen_string_literal: true

module Exa
  class Client
    def initialize(api_key: nil, **options)
      @api_key = api_key || Exa.api_key
      @options = options

      validate_api_key!
    end

    def search(query, **params)
      Services::Search.new(connection, query: query, **params).call
    end

    def find_similar(url, **options)
      Services::FindSimilar.new(connection, url: url, **options).call
    end

    def get_contents(urls, **options)
      Services::GetContents.new(connection, urls: urls, **options).call
    end

    def answer(query, **options)
      Services::Answer.new(connection, query: query, **options).call
    end

    def research_start(**params)
      Services::ResearchStart.new(connection, **params).call
    end

    def research_list(**params)
      Services::ResearchList.new(connection, **params).call
    end

    def research_get(research_id, **params)
      Services::ResearchGet.new(connection, research_id: research_id, **params).call
    end

    def context(query, **params)
      Services::Context.new(connection, query: query, **params).call
    end

    private

    def connection
      @connection ||= Connection.build(
        api_key: @api_key,
        **connection_options
      )
    end

    def connection_options
      options = {}
      options[:base_url] = @options[:base_url] if @options[:base_url]
      options[:timeout] = @options[:timeout] if @options[:timeout]
      options
    end

    def validate_api_key!
      return if @api_key && !@api_key.empty?

      raise ConfigurationError, "API key is required. Set it with Exa.configure or pass it to Client.new"
    end
  end
end
