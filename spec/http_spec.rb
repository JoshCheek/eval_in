require 'spec_helper'

# This code is mostly tested through tests on the higher level things it depends on
# But for a few small helpers, I wanted to just hit a lot of edge cases to really
# give myself confidence they did what I was expecting.
RSpec.describe EvalIn::HTTP do
  describe '.jsonify_url' do
    def assert_transforms(initial_url, expected_url)
      actual_url = EvalIn::HTTP.jsonify_url initial_url
      expect(actual_url).to eq expected_url
    end

    it 'appends .json to a url that is missing it' do
      assert_transforms 'http://eval.in/1',          'http://eval.in/1.json'
      assert_transforms 'http://eval.in/1.json',     'http://eval.in/1.json'

      assert_transforms 'http://eval.in/1?a=b',      'http://eval.in/1.json?a=b'
      assert_transforms 'http://eval.in/1.json?a=b', 'http://eval.in/1.json?a=b'
    end

    it 'changes .not-json to .json' do
      assert_transforms 'http://eval.in/1.xml',      'http://eval.in/1.json'
      assert_transforms 'http://eval.in/1.html',     'http://eval.in/1.json'
      assert_transforms 'http://eval.in/1.html?a=b', 'http://eval.in/1.json?a=b'
    end
  end
end
