require 'eval_in/http'
require 'eval_in/client'

module EvalIn
  # @param code [String] the code to evaluate.
  # @option options [String] :language Mandatory, a language recognized by eval.in, such as any value in {KNOWN_LANGUAGES}.
  # @option options [String] :url      Override the url to post the code to
  # @option options [String] :stdin    Will be passed as standard input to the script
  # @option options [String] :context  Will be included in the user agent
  # @return [Result] the relevant data from the evaluated code.
  #
  # @example
  #   result = EvalIn.call 'puts "hello, #{gets}"', stdin: 'world', language: "ruby/mri-2.1"
  #   result.output # => "hello, world\n"
  def self.call(code, options={})
    url = Client.post_code(code, options)
    fetch_result url, options
  end

  # @param url [String] the url with the result
  # @option options [String] :context Will be included in the user agent
  #
  # @example
  #   result = EvalIn.fetch_result "https://eval.in/147.json"
  #   result.output # => "Hello Charlie! "
  def self.fetch_result(raw_url, options={})
    raw_json_url = HTTP.jsonify_url(raw_url)
    Client.build_result Client.fetch_result_json(raw_json_url, options)
  end
end
