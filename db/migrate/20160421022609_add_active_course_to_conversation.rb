class AddActiveCourseToConversation < ActiveRecord::Migration[5.0]
  def change
    add_column :conversations, :active_course_id, :string
  end
end
