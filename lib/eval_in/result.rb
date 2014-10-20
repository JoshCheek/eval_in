require 'json'

module EvalIn
  # The data structure containing the final result
  # its attributes default to null-objects for their given type
  class Result
    @attribute_names = [:exitstatus, :language, :language_friendly, :code, :output, :status, :url].freeze
    attr_accessor *@attribute_names
    class << self
      attr_reader :attribute_names
    end

    def initialize(attributes={})
      attributes = attributes.dup
      self.exitstatus         = attributes.delete(:exitstatus)        || -1
      self.language           = attributes.delete(:language)          || ""
      self.language_friendly  = attributes.delete(:language_friendly) || ""
      self.code               = attributes.delete(:code)              || ""
      self.output             = attributes.delete(:output)            || ""
      self.status             = attributes.delete(:status)            || ""
      self.url                = attributes.delete(:url)               || ""
      stderr                  = attributes.delete(:stderr)            || $stderr
      stderr.puts "Unexpected attributes! #{attributes.keys.inspect}" if attributes.any?
    end

    # Returns representation of the result built out of JSON primitives (hash, string, int)
    def as_json
      self.class.attribute_names.each_with_object Hash.new do |name, attributes|
        attributes[name.to_s] = public_send name
      end
    end

    def to_json
      JSON.dump(as_json)
    end
  end
end
