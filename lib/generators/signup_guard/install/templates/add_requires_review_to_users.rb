class <%= migration_class_name %> < ActiveRecord::Migration<%= migration_version %>
  def change
    add_column :<%= user_table %>, :<%= requires_review_attribute %>, :boolean, default: false, null: false
    add_index :<%= user_table %>, :<%= requires_review_attribute %>, where: "<%= requires_review_attribute %> = true"
  end
end
