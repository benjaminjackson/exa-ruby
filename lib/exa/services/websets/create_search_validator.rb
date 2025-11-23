# frozen_string_literal: true

module Exa
  module Services
    module Websets
      # Validates parameters for webset search creation
      class CreateSearchValidator
        VALID_ENTITY_TYPES = %w[company person article research_paper custom].freeze
        VALID_BEHAVIORS = %w[override append].freeze
        VALID_SOURCE_TYPES = %w[import webset].freeze

        class << self
          def validate!(params)
            validate_query!(params[:query]) if params[:query]
            validate_count!(params[:count]) if params[:count]
            validate_entity!(params[:entity]) if params[:entity]
            validate_criteria!(params[:criteria]) if params[:criteria]
            validate_scope!(params[:scope]) if params[:scope]
            validate_exclude!(params[:exclude]) if params[:exclude]
            validate_behavior!(params[:behavior]) if params[:behavior]
            validate_metadata!(params[:metadata]) if params[:metadata]
          end

          private

          def validate_query!(query)
            raise ArgumentError, "query must be a String" unless query.is_a?(String)
            raise ArgumentError, "query cannot be empty" if query.strip.empty?
            raise ArgumentError, "query cannot exceed 5000 characters" if query.length > 5000
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

          def validate_exclude!(exclude)
            raise ArgumentError, "exclude must be an Array" unless exclude.is_a?(Array)

            exclude.each_with_index do |item, index|
              validate_source_reference!(item, "exclude[#{index}]")
            end
          end

          def validate_behavior!(behavior)
            unless VALID_BEHAVIORS.include?(behavior)
              raise ArgumentError, "behavior must be one of: #{VALID_BEHAVIORS.join(', ')}"
            end
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
