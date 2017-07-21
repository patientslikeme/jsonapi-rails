require 'jsonapi/rails/active_model_error'
require 'jsonapi/serializable/renderer'

module JSONAPI
  module Rails
    class SuccessRenderer
      def initialize(renderer = JSONAPI::Serializable::SuccessRenderer.new)
        @renderer = renderer

        freeze
      end

      def render(resources, options)
        opts = options.dup
        # TODO(beauby): Move this to a global configuration.
        default_exposures = {
          url_helpers: ::Rails.application.routes.url_helpers
        }
        opts[:expose] = default_exposures.merge!(opts[:expose] || {})
        opts[:jsonapi] = opts.delete(:jsonapi_object)

        @renderer.render(resources, opts)
      end
    end

    class ErrorsRenderer
      def initialize(renderer = JSONAPI::Serializable::ErrorsRenderer.new)
        @renderer = renderer

        freeze
      end

      def render(errors, options)
        errors = [errors] unless errors.is_a?(Array)
        errors = errors.flat_map do |error|
          if error.respond_to?(:as_jsonapi)
            error
          elsif error.is_a?(ActiveModel::Errors)
            ActiveModelError.from_errors(error, options[:_jsonapi_pointers]).to_a
          elsif error.is_a?(Hash)
            JSONAPI::Serializable::Error.create(error)
          else
            raise # TODO(lucas): Raise meaningful exception.
          end
        end

        # TODO(beauby): SerializableError inference on AR validation errors.
        @renderer.render(errors, options)
      end
    end
  end
end
