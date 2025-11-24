# frozen_string_literal: true

require "faraday"

module Exa
  module Services
    module Websets
      class UploadImport
        def initialize(connection, file_path:, **params)
          @connection = connection
          @file_path = file_path
          @params = params
        end

        def call
          validate_file!

          # Infer file size
          file_size = File.size(@file_path)

          # Create import with inferred size
          import = CreateImport.new(@connection, size: file_size, **@params).call

          # Upload file to the upload URL
          upload_file(import.upload_url)

          # Return the import resource
          import
        end

        private

        def validate_file!
          unless File.exist?(@file_path)
            raise Error, "File not found: #{@file_path}"
          end

          unless File.readable?(@file_path)
            raise Error, "Permission denied: file is not readable: #{@file_path}"
          end
        end

        def upload_file(upload_url)
          file_content = File.read(@file_path)

          upload_connection = Faraday.new do |f|
            f.adapter Faraday.default_adapter
          end

          upload_connection.put(upload_url) do |req|
            req.headers["Content-Type"] = "text/csv"
            req.body = file_content
          end
        end
      end
    end
  end
end
