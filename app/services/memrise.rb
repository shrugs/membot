class Memrise
  include HTTParty

  base_uri('https://api.memrise.com/v1.4')
  headers({
    'Content-Type' => 'application/x-www-form-urlencoded',
    'User-Agent' => 'MemriseForiOS/2321',
  })
  default_options.update(verify: false)

  def initialize(access_token = nil)
    @instance_headers = {}

    set_access_token(access_token) if access_token.present?
  end

  def user_info(user_id)
    request(:get, "/users/#{user_id}")
  end

  def new_user(opts)
    request(:post, '/auth/signup/', {
      client_id: ENV.fetch('MEMRISE_FACEBOOK_CLIENT_ID'),
      timezone: 'America/New_York',
      language: 'en',
    }.merge(opts))
  end

  def get_language_courses
    request(:get, '/categories/languages')['featured']
  end

  def get_course_info(id)
    request(:get, "/courses/#{id}")
  end

  def enroll_in_course(id)
    request(:post, "/courses/#{id}/enroll")
  end

  def course_levels(id)
    request(:get, "/courses/#{id}/levels")['levels']
  end

  def get_things(thing_ids)
    request(:get, "/things/#{thing_ids.join(',')}")['things']
  end

  def record_event(event)
    request(:post, "/progress/register/", {
      events: [event].to_json,
      limit: 5000,
      sync_token: 0,
      with_stats: 1,
    })
  end

  private

  def set_access_token(access_token)
    @instance_headers.merge!({
      'Authorization' => "Bearer #{access_token}"
    })
  end

  def request(method, endpoint, opts = {})
    self.class.send(method, endpoint, opts.merge({
      body: opts,
      headers: @instance_headers,
      query: {
        format: 'json'
      },
    }))
  end

end