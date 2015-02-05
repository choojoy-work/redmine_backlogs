class CreateAcceptanceCriteria < ActiveRecord::Migration
  def change
    create_table :acceptance_criteria do |t|
      t.string :title, null: false
      t.integer :issue_id, null:false
    end

    add_index :acceptance_criteria, :issue_id
  end
end
