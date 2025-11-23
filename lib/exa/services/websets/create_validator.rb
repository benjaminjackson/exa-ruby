# frozen_string_literal: true

require_relative "../../constants/websets"

module Exa
  module Services
    module Websets
      # Validates parameters for webset creation
      class CreateValidator
        VALID_ENTITY_TYPES = Constants::Websets::ENTITY_TYPES
        VALID_ENRICHMENT_FORMATS = Constants::Websets::ENRICHMENT_FORMATS
        VALID_SOURCE_TYPES = Constants::Websets::SOURCE_TYPES

        class << self
          def validate!(params)
            validate_has_search_or_import!(params)
            validate_search!(params[:search]) if params[:search]
            validate_import!(params[:import]) if params[:import]
            validate_enrichments!(params[:enrichments]) if params[:enrichments]
            validate_exclude!(params[:exclude]) if params[:exclude]
            validate_external_id!(params[:externalId]) if params[:externalId]
            validate_metadata!(params[:metadata]) if params[:metadata]
          end

          private

          def validate_has_search_or_import!(params)
            return if params[:search] || params[:import]

            raise ArgumentError, "At least one of :search or :import is required"
          end

          def validate_search!(search)
            raise ArgumentError, "search must be a Hash" unless search.is_a?(Hash)
            raise ArgumentError, "search[:query] is required" unless search[:query]
            raise ArgumentError, "search[:query] must be a String" unless search[:query].is_a?(String)
            raise ArgumentError, "search[:query] cannot be empty" if search[:query].strip.empty?
            raise ArgumentError, "search[:query] cannot exceed 5000 characters" if search[:query].length > 5000

            validate_count!(search[:count]) if search[:count]
            validate_entity!(search[:entity]) if search[:entity]
            validate_criteria!(search[:criteria]) if search[:criteria]
            validate_scope!(search[:scope]) if search[:scope]
            validate_exclude_list!(search[:exclude]) if search[:exclude]
          end

          def validate_count!(count)
            raise ArgumentError, "count must be a positive Integer" unless count.is_a?(Integer) && count > 0
          end

          def validate_entity!(entity)
            raise ArgumentError, "entity must be a Hash" unless entity.is_a?(Hash)
            raise ArgumentError, "entity[:type] is required" unless entity[:type]

            type = entity[:type]
            unless VALID_ENTITY_TYPES.include?(type)
              raise ArgumentError, "entity[:type] must be one of: #{VALID_ENTITY_TYPES.join(', ')}"
            end

            if type == "custom"
              raise ArgumentError, "entity[:description] is required for custom entity type" unless entity[:description]
              validate_string_length!(entity[:description], "entity[:description]", min: 2, max: 200)
            end
          end

          def validate_criteria!(criteria)
            raise ArgumentError, "criteria must be an Array" unless criteria.is_a?(Array)
            raise ArgumentError, "criteria must have at least 1 item" if criteria.empty?
            raise ArgumentError, "criteria cannot have more than 5 items" if criteria.length > 5

            criteria.each_with_index do |criterion, index|
              raise ArgumentError, "criteria[#{index}] must be a Hash" unless criterion.is_a?(Hash)
              raise ArgumentError, "criteria[#{index}][:description] is required" unless criterion[:description]
              validate_string_length!(criterion[:description], "criteria[#{index}][:description]", min: 1, max: 1000)
            end
          end

          def validate_scope!(scope)
            raise ArgumentError, "scope must be an Array" unless scope.is_a?(Array)

            scope.each_with_index do |item, index|
              validate_source_reference!(item, "scope[#{index}]")

              next unless item[:relationship]

              rel = item[:relationship]
              raise ArgumentError, "scope[#{index}][:relationship] must be a Hash" unless rel.is_a?(Hash)
              raise ArgumentError, "scope[#{index}][:relationship][:definition] is required" unless rel[:definition]
              raise ArgumentError, "scope[#{index}][:relationship][:limit] is required" unless rel[:limit]

              limit = rel[:limit]
              unless limit.is_a?(Integer) && limit >= 1 && limit <= 10
                raise ArgumentError, "scope[#{index}][:relationship][:limit] must be an Integer between 1 and 10"
              end
            end
          end

          def validate_exclude_list!(exclude)
            raise ArgumentError, "exclude must be an Array" unless exclude.is_a?(Array)

            exclude.each_with_index do |item, index|
              validate_source_reference!(item, "exclude[#{index}]")
            end
          end

          def validate_import!(import)
            raise ArgumentError, "import must be an Array" unless import.is_a?(Array)

            import.each_with_index do |item, index|
              validate_source_reference!(item, "import[#{index}]")
            end
          end

          def validate_enrichments!(enrichments)
            raise ArgumentError, "enrichments must be an Array" unless enrichments.is_a?(Array)

            enrichments.each_with_index do |enrichment, index|
              raise ArgumentError, "enrichments[#{index}] must be a Hash" unless enrichment.is_a?(Hash)
              raise ArgumentError, "enrichments[#{index}][:description] is required" unless enrichment[:description]
              validate_string_length!(enrichment[:description], "enrichments[#{index}][:description]", min: 1, max: 5000)

              if enrichment[:format]
                format = enrichment[:format]
                unless VALID_ENRICHMENT_FORMATS.include?(format)
                  raise ArgumentError, "enrichments[#{index}][:format] must be one of: #{VALID_ENRICHMENT_FORMATS.join(', ')}"
                end

                if format == "options"
                  validate_enrichment_options!(enrichment[:options], index)
                end
              end
            end
          end

          def validate_enrichment_options!(options, enrichment_index)
            unless options.is_a?(Array)
              raise ArgumentError, "enrichments[#{enrichment_index}][:options] is required when format is 'options'"
            end

            if options.empty? || options.length > 150
              raise ArgumentError, "enrichments[#{enrichment_index}][:options] must have between 1 and 150 items"
            end

            options.each_with_index do |option, option_index|
              unless option.is_a?(Hash) && option[:label]
                raise ArgumentError, "enrichments[#{enrichment_index}][:options][#{option_index}][:label] is required"
              end
            end
          end

          def validate_exclude!(exclude)
            validate_exclude_list!(exclude)
          end

          def validate_external_id!(external_id)
            raise ArgumentError, "externalId must be a String" unless external_id.is_a?(String)
            raise ArgumentError, "externalId cannot exceed 300 characters" if external_id.length > 300
          end

          def validate_metadata!(metadata)
            raise ArgumentError, "metadata must be a Hash" unless metadata.is_a?(Hash)

            metadata.each do |key, value|
              raise ArgumentError, "metadata values must be Strings" unless value.is_a?(String)
              raise ArgumentError, "metadata value for '#{key}' cannot exceed 1000 characters" if value.length > 1000
            end
          end

          def validate_source_reference!(item, context)
            raise ArgumentError, "#{context} must be a Hash" unless item.is_a?(Hash)
            raise ArgumentError, "#{context}[:source] is required" unless item[:source]
            raise ArgumentError, "#{context}[:id] is required" unless item[:id]

            source = item[:source]
            unless VALID_SOURCE_TYPES.include?(source)
              raise ArgumentError, "#{context}[:source] must be one of: #{VALID_SOURCE_TYPES.join(', ')}"
            end

            raise ArgumentError, "#{context}[:id] must be a non-empty String" unless item[:id].is_a?(String) && !item[:id].empty?
          end

          def validate_string_length!(value, name, min: nil, max: nil)
            raise ArgumentError, "#{name} must be a String" unless value.is_a?(String)
            raise ArgumentError, "#{name} must be at least #{min} characters" if min && value.length < min
            raise ArgumentError, "#{name} cannot exceed #{max} characters" if max && value.length > max
          end
        end
      end
    end
  end
end
