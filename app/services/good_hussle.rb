class GoodHussle
  def initialize(correct_answer)
    @correct_answer = correct_answer
  end

  def saying
    [
      'The correct answer was "{}", but good hussle!',
      'Sorry! The correct answer was "{}".',
      'Oh no, you played yourself!',
    ].sample.sub('{}', @correct_answer)
  end
end