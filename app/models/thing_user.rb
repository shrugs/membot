class ThingUser < ActiveRecord::Base
  belongs_to :thing
  belongs_to :conversation
  belongs_to :level

  scope :not_mastered,  -> { where 'score < ?', 8  }

  def presentation_question
    # @TODO(shrugs) - find and display the mems as a card
    Question.create({
      conversation: conversation,
      thing: self.thing,
      box_template: 'presentation',
      given_answer: '',
      update_scheduling: 0,
      score: 0,
    })
    {
      attachment: {
        type: 'template',
        payload: {
          template_type: 'generic',
          elements: [{
            title: thing.columns['1']['val'],
            subtitle: thing.columns['2']['val'],
            buttons: [{
              type: 'postback',
              title: 'OK',
              payload: "ANSWER_CORRECTLY##{self.thing.id}"
            }]
          }]
        }
      }
    }
  end

  def one_to_two_question
    prompt = thing.columns['1']['val']
    correct_answer = thing.columns['2']['val']
    other_choices = thing.columns['2']['choices']

    create_multiple_choice(prompt, correct_answer, other_choices)
  end

  def two_to_one_question
    prompt = thing.columns['2']['val']
    correct_answer = thing.columns['1']['val']
    other_choices = thing.columns['1']['choices']

    create_multiple_choice(prompt, correct_answer, other_choices)
  end

  def create_multiple_choice(prompt, correct_answer, other_choices)
    Question.create({
      conversation: conversation,
      thing: self.thing,
      box_template: 'multiple_choice',
      given_answer: correct_answer,
      update_scheduling: 1,
      score: 1,
    })
    {
      attachment: {
        type: 'template',
        payload: {
          template_type: 'generic',
          elements: other_choices.sample(5).concat([correct_answer]).shuffle.each_slice(3).map do |answers|
            {
              title: prompt,
              buttons: answers.map do |a|
                payload = if a == correct_answer
                  "ANSWER_CORRECTLY##{self.thing.id}"
                else
                  "ANSWER_INCORRECTLY##{correct_answer}"
                end
                {
                  type: 'postback',
                  title: a,
                  payload: payload
                }
              end
            }
          end
        }
      }
    }
  end

  def typing_question
    prompt = thing.columns['2']['val']
    correct_answer = thing.columns['1']['val']

    Question.create({
      conversation: conversation,
      thing: self.thing,
      box_template: 'typing',
      given_answer: correct_answer,
      update_scheduling: 1,
      score: 1,
    })
    {
      attachment: {
        type: 'template',
        payload: {
          template_type: 'generic',
          elements: [{
            title: prompt,
            subtitle: 'Type your answer below.'
          }]
        }
      }
    }
  end

end