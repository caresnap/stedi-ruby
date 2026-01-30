# frozen_string_literal: true

module Stedi
  class Response
    def initialize(data)
      @data = normalize_keys(data)
    end

    def [](key)
      @data[key.to_s]
    end

    def to_h
      deep_to_h(@data)
    end

    def to_json(*args)
      to_h.to_json(*args)
    end

    def respond_to_missing?(method_name, include_private = false)
      @data.key?(method_name.to_s) || super
    end

    def method_missing(method_name, *args, &block)
      key = method_name.to_s
      if @data.key?(key)
        @data[key]
      else
        super
      end
    end

    def inspect
      "#<Stedi::Response #{@data.keys.join(', ')}>"
    end

    private

    def normalize_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(key, value), result|
          normalized_key = underscore(key.to_s)
          result[normalized_key] = wrap_value(value)
        end
      else
        obj
      end
    end

    def wrap_value(value)
      case value
      when Hash
        Response.new(value)
      when Array
        value.map { |v| wrap_value(v) }
      else
        value
      end
    end

    def deep_to_h(obj)
      case obj
      when Response
        obj.instance_variable_get(:@data).transform_values { |v| deep_to_h(v) }
      when Hash
        obj.transform_values { |v| deep_to_h(v) }
      when Array
        obj.map { |v| deep_to_h(v) }
      else
        obj
      end
    end

    def underscore(str)
      str.gsub(/::/, "/")
         .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
         .gsub(/([a-z\d])([A-Z])/, '\1_\2')
         .tr("-", "_")
         .downcase
    end
  end
end
