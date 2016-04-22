class Conversation < ActiveRecord::Base
  include AASM

  belongs_to :level
  has_many :thing_users
  has_many :questions
  validates_presence_of :facebook_user_id

  aasm column: :state do
    state :pre_signup, initial: true
    state :course_selection
    state :in_course
    state :waiting_on_answer

    event :signup, after: :after_signup do
      transitions from: :pre_signup, to: :course_selection, guard: :on_signup
      error do |e|
        # email was probably wrong
        text_message 'That email is already being used. If you already have a Memrise account, due to technical limitations, you have to create a new one. We\'ll support existing accounts in the future! If you use gmail, try "youremailaddress+memriseformessenger@gmail.com".'
      end
    end

    event :select_course, after: :after_select_course do
      transitions from: :course_selection, to: :in_course, guard: :on_select_course
    end

    event :new_question do
      transitions from: :in_course, to: :waiting_on_answer, guard: :send_question
    end

    event :provide_answer, after: :after_provide_answer do
      transitions from: :waiting_on_answer, to: :in_course, guard: :on_provide_answer
    end

    event :provide_incorrect_answer, after: :after_provide_incorrect_answer do
      transitions from: :waiting_on_answer, to: :in_course, guard: :on_provide_incorrect_answer
    end
  end

  def text_message(text)
    Messenger.new.send_message(facebook_user_id, {
      text: text
    })
  end

  def message(data)
    Messenger.new.send_message(facebook_user_id, data)
  end

  def present_course_selection
    language_courses = memrise.get_language_courses
    data = {
      attachment: {
        type: 'template',
        payload: {
          template_type: 'generic',
          elements: language_courses.first(10).map { |i, courses|
            course = courses.first
            {
              title: course['name'],
              subtitle: course['description'],
              image_url: course['photo_large'],
              buttons: [
                {
                  type: 'postback',
                  title: 'Select',
                  payload: "SELECT_COURSE##{course['id']}",
                }
              ],
            }
          }
        }
      }
    }
    message(data)
  end

  def present_mems_for_thing(thing_id)
    mems = memrise.get_mems_for_thing(thing_id)
  end

  def active_thing_users
    thing_users.where(level: level).not_mastered
  end

  # private

  def on_signup(email)

    @temporary_password = SecureRandom.hex(10)

    res = Memrise.new.new_user({
      email: email,
      password: @temporary_password,
    })

    return false if res.nil? || res['access_token'].nil? || res['user'].nil?

    self.email = email

    self.access_token = res['access_token']['access_token']
    self.token_type = res['access_token']['token_type']
    self.expires_in = res['access_token']['expires_in']
    self.refresh_token = res['access_token']['refresh_token']
    self.scope = res['access_token']['scope']

    self.memrise_username = res['user']['username']
    self.memrise_id = res['user']['id']

    save
  end

  def after_signup

    # send message to user with their password
    text_message "Welcome to Memrise via Messenger! Your temporary password is '#{@temporary_password}'. You should change it eventually, but for now, lets pick a course."

    # present the course selection message
    present_course_selection
  end

  def send_question
    # send the next question to the user
    message(next_question)
  end

  def on_provide_answer(thing_id)
    # increase score on ThingUser
    thing_user = self.thing_users.find_by(thing_id: thing_id.to_i, level_id: level_id)
    thing_user.score = thing_user.score + 1
    thing_user.save
  end

  def after_provide_answer
    text_message Congrats.new
    self.new_question!
    post_progress_for_last_question
  end

  def on_select_course(course_id)
    self.active_course_id = course_id
    save
  end

  def after_select_course
    text_message 'Great choice! Memrise uses spaced repetition to help you learn, so you\'ll receive occasional questions throughout the day. Feel free to  stop your learning session at any time or ignore a question entirely.'

    text_message 'Let\'s get started! First let\'s see the word and its definition.'
    self.new_question!
  end

  def on_provide_incorrect_answer(correct_text)
    text_message GoodHussle.new(correct_text)
  end

  def after_provide_incorrect_answer
    self.new_question!
  end

  def memrise
    @memrise ||= Memrise.new(self.access_token)
  end

  def post_progress_for_last_question

    last_question = questions.last
    res = memrise.record_event({
      level_id: level.id.to_s,
      thing_id: last_question.thing_id.to_s,
      course_id: self.active_course_id.to_s,
      correct: 1,
      next_date: (Time.now - 30.seconds).to_i,
      bonus_points: 1,
      given_answer: last_question.given_answer,
      box_template: last_question.box_template,
      growth_level: self.thing_users.find_by(thing_id: last_question.thing_id).score,
      score: last_question.score,
      total_streak: 1,
      column_a: '1',  # until I find out otherwise
      column_b: '2',  # likewise
      starred: false,
      points: 50,
      timestamp: Time.now.to_i,
      time_spent: (Time.zone.now - last_question.created_at).to_i,
      not_difficult: false,
      attempts: 1,
      when: Time.now.to_i,
      current_streak: 1,
      ignored: false,
      interval: 0.01,
      update_scheduling: last_question.update_scheduling,
    })
    # successful if sync_token exists
    res['sync_token'].present?
  end

  def next_question

    # construct and return the data required to present the next question to a user
    # if the data does not exist locally, fetch it and create it locally
    # finally, return the message format for the next question

    # the next question is based on the current level
    # if there is no current level, fetch the levels and choose the first
    # if there are no active thing_users, move to next level

    next_level_index = self.level.nil? ? 1 : (self.level.index + 1)

    current_level = if self.level.nil? || active_thing_users.count == 0
      # if we need new level data
      # 1) Grab it from the internets
      # 1.b) Remove levels without any content (wtf memrise)
      levels = memrise.course_levels(active_course_id)
        .select { |l| l['thing_ids'].count > 0 }
        .sort_by { |l| l['index'] }
      # 2) Get the "next" level (could be the first one)
      next_level_data = self.level.nil? ? levels.first : levels.find { |l| l['index'] == next_level_index }
      # 3) Upsert Level in the DB
      new_level = Level.create_with(next_level_data.except('thing_ids')).find_or_create_by(id: next_level_data['id'])
      # 4) Upsert all of the associated Thing objects
      new_level.things = next_level_data['thing_ids'].map { |thing_id|
        Thing.find_or_create_by(id: thing_id)
      }
      # 5) Get all of the thing_ids that we need info on
      thing_ids = new_level.things.select { |t| t.columns.nil? }.map(&:id)

      if thing_ids.count > 0
        # 6) Grab the info for that and store in the db
        memrise.get_things(thing_ids).map { |t_data|
          t = Thing.find_or_create_by(id: t_data['id'])
          t.update_attributes(t_data.slice('id', 'columns'))
          t
        }
      end
      new_level.things.each do |t|
        # 7) Create all of the ThingUser models because this is a new level
        self.thing_users.create(thing: t, level: new_level)
      end
      new_level
    else
      self.level
    end

    # save the current level
    self.level = current_level

    # choose a random Thing in the Level
    # that we haven't mastered yet
    next_thing_user = active_thing_users.sample

    case next_thing_user.score
    when 0
      # if 0, present new thing
      return next_thing_user.presentation_question
    when 1..5
      # if < 5 present one of the multiple choice questions
      return next_thing_user.send([
        :one_to_two_question,
        :two_to_one_question
      ].sample)
    else
      # otherwise present a random.choice between a typing question and a multiple choice
      return next_thing_user.send([
        :one_to_two_question,
        :two_to_one_question,
        :typing_question
      ].sample)
    end


  end

end
