class AddAcceptanceRate < ActiveRecord::Migration
  def up
    add_column :issues, :acceptance_rate, :integer
  end

  def down
    remove_column :issues, :acceptance_rate
  end
end
