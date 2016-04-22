class GoodHussle
  def initialize(correct_answer)
    [
      'The correct answer was "{}", but good hussle!',
      'Sorry! The correct answer was "{}".',
      'Oh no, you played yourself!',
    ].sample.replace('{}', correct_answer)
  end
end