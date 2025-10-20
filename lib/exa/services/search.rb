# frozen_string_literal: true

module Exa
  module Services
    class Search
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        response = @connection.post("/search", convert_params(@params))
        body = response.body

        Resources::SearchResult.new(
          results: body["results"],
          request_id: body["requestId"],
          resolved_search_type: body["resolvedSearchType"],
          search_type: body["searchType"],
          context: body["context"],
          cost_dollars: body["costDollars"]
        )
      end

      private

      def convert_params(params)
        converted = {}
        params.each do |key, value|
          converted[convert_key(key)] = value
        end
        converted
      end

      def convert_key(key)
        case key
        when :start_published_date then :startPublishedDate
        when :end_published_date then :endPublishedDate
        when :start_crawl_date then :startCrawlDate
        when :end_crawl_date then :endCrawlDate
        else
          key
        end
      end
    end
  end
end
