require 'rails/railtie'
require 'action_controller'
require 'active_support'
require 'active_model'

require 'jsonapi/rails/configuration'
require 'jsonapi/rails/parser'
require 'jsonapi/rails/renderer'

module JSONAPI
  module Rails
    class Railtie < ::Rails::Railtie
      MEDIA_TYPE = 'application/vnd.api+json'.freeze
      RENDERERS = {
        jsonapi:       SuccessRenderer.new,
        jsonapi_error: ErrorsRenderer.new
      }.freeze

      initializer 'jsonapi-rails.action_controller' do
        ActiveSupport.on_load(:action_controller) do
          require 'jsonapi/rails/action_controller'
          include ::JSONAPI::Rails::ActionController

          if JSONAPI::Rails.config.register_mime_type
            Mime::Type.register MEDIA_TYPE, :jsonapi
          end

          if JSONAPI::Rails.config.register_parameter_parser
            if ::Rails::VERSION::MAJOR >= 5
              ::ActionDispatch::Request.parameter_parsers[:jsonapi] = PARSER
            else
              ::ActionDispatch::ParamsParser::DEFAULT_PARSERS[Mime[:jsonapi]] = PARSER
            end
          end

          if JSONAPI::Rails.config.register_renderers
            ::ActionController::Renderers.add(:jsonapi) do |resources, options|
              self.content_type ||= Mime[:jsonapi]

              RENDERERS[:jsonapi].render(resources, options).to_json
            end

            ::ActionController::Renderers.add(:jsonapi_error) do |errors, options|
              # Renderer proc is evaluated in the controller context, so it
              # has access to the jsonapi_pointers method.
              options = options.merge(_jsonapi_pointers: jsonapi_pointers)
              self.content_type ||= Mime[:jsonapi]

              RENDERERS[:jsonapi_error].render(errors, options).to_json
            end
          end

          JSONAPI::Deserializable::Resource.configure do |config|
            config.default_has_one do |key, _rel, id, type|
              key  = key.to_s.singularize
              type = type.to_s.singularize.camelize
              { "#{key}_id".to_sym => id, "#{key}_type".to_sym => type }
            end

            config.default_has_many do |key, _rel, ids, types|
              key   = key.to_s.singularize
              types = types.map { |t| t.to_s.singularize.camelize }
              { "#{key}_ids".to_sym => ids, "#{key}_types".to_sym => types }
            end
          end
        end
      end
    end
  end
end
