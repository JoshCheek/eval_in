module EvalIn

  # Can't just use Net::HTTP.get, b/c it doesn't use ssl on 1.9.3
  # https://github.com/ruby/ruby/blob/v2_1_2/lib/net/http.rb#L478-479
  # https://github.com/ruby/ruby/blob/v1_9_3_547/lib/net/http.rb#L454
  module HTTP
    extend self

    def get_request(raw_url, user_agent)
      generic_request_for raw_url:      raw_url,
                          request_type: Net::HTTP::Get,
                          user_agent:   user_agent
    end

    def post_request(raw_url, form_data, user_agent)
      generic_request_for raw_url:      raw_url,
                          request_type: Net::HTTP::Post,
                          user_agent:   user_agent,
                          form_data:    form_data
    end

    # stole this out of implementation for post_form https://github.com/ruby/ruby/blob/2afed6eceff2951b949db7ded8167a75b431bad6/lib/net/http.rb#L503
    # can use this to view the request: http.set_debug_output $stdout
    def generic_request_for(params)
      uri                   = URI params.fetch(:raw_url)
      path                  = uri.path
      path                  = '/' if path.empty?
      request               = params.fetch(:request_type).new(path)
      request['User-Agent'] = params[:user_agent] if params.key? :user_agent
      request.form_data     = params[:form_data]  if params.key? :form_data
      request.basic_auth uri.user, uri.password   if uri.user
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: (uri.scheme == 'https')) { |http| http.request request }
    end
  end
end
