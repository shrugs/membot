class ConversationsController < ApplicationController

  def inbound_message

    if params['hub.verify_token'] == ENV.fetch('VERIFICATION_TOKEN')
      render html: params['hub.challenge']
    end

    params[:entry].each do |entry|
      entry[:messaging].each do |message_event|

        handle_message(message_event) if message_event[:message].present?
        handle_postback(message_event) if message_event[:postback].present?

      end
    end

  end

  def handle_message(event)
    if conversation = Conversation.find_by(facebook_user_id: event[:sender][:id])

      if conversation.pre_signup?
        # check for an email in the message
        r = Regexp.new(/\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}\b/)
        email = event[:message][:text].scan(r).first
        if email.present?
          conversation.signup!(email)
        else
          conversation.text_message 'I didn\'t understand that, sorry. I\'m looking for an email right now.'
        end
      elsif conversation.waiting_on_answer?
        # if we're waiting on an answer and they messaged us, chances are it's an answer
        last_question = conversation.questions.last
        if last_question.box_template == 'typing'
          # now we're pretty sure it's an answer, lets try it out
          if event[:message][:text] == last_question.given_answer
            # correct
            conversation.provide_answer!(last_question.thing.id)
          else
            # incorrect
            conversation.provide_incorrect_answer!(last_question.given_answer)
          end
        end
      end


    else
      # NEW USER YAY
      conversation = create_new_conversation(event['sender']['id'])
      conversation.text_message 'Welcome! First, lets create a new Memrise account.'
      conversation.text_message 'What\'s your email address?'
    end

  end

  def handle_postback(event)
    conversation = Conversation.find_by(facebook_user_id: event['sender']['id'])

    head :ok if conversation.nil?

    event_arguments = event[:postback][:payload].split('#')
    event_type = event_arguments.first
    event_arg = event_arguments.last

    case event_type
    when 'SELECT_COURSE'
      conversation.select_course!(event_arg)
    when 'SHOW_MEMS'
      conversation.present_mems_for_thing!(event_arg)
    when 'ANSWER_CORRECTLY'
      conversation.provide_answer!(event_arg)
    when 'ANSWER_INCORRECTLY'
      conversation.provide_incorrect_answer!(event_arg)
    end

  end

  def create_new_conversation(facebook_user_id)
    Conversation.create({
      facebook_user_id: facebook_user_id
    })
  end

  private


end
