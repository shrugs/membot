class Messenger
  include HTTParty

  base_uri('https://graph.facebook.com/v2.6/me')
  headers({
    'Content-Type' => 'application/json',
  })
  default_options.update(verify: false)

  def send_message(id, data)
    request(:post, '/messages', body: {
      recipient: { id: id },
      message: data
    }.to_json)
  end

  def request(method, endpoint, opts)
    self.class.send(method, endpoint, {
      query: {
        'access_token': ENV.fetch('PAGE_ACCESS_TOKEN'),
      }
    }.merge(opts))
  end



end