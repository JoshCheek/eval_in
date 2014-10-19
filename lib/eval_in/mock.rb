module EvalIn
  class Mock
    def initialize(options={})
      @result = options[:result]
    end

    def call(code, options={})
      @result
    end

    def fetch_result(raw_url, options={})
      @result
    end
  end
end
