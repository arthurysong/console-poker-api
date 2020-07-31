class AddBigBlindToGames < ActiveRecord::Migration[6.0]
  def change
    add_column :games, :big_blind, :integer, :default => 400
  end
end
