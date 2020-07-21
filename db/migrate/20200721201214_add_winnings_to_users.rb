class AddWinningsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :winnings, :integer
  end
end
