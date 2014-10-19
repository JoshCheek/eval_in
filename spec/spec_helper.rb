require 'eval_in'
require 'webmock'
WebMock.disable_net_connect!

RSpec.configure do |config|
  config.filter_run_excluding integration: true

  config.include Module.new {
    def assert_result(result, attributes)
      attributes.each do |key, value|
        expect(result.public_send key).to eq value
      end
    end
  }

  config.after do
    WebMock.reset!
  end
end
