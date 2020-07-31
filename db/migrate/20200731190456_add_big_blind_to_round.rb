class AddBigBlindToRound < ActiveRecord::Migration[6.0]
  def change
    add_column :rounds, :big_blind, :integer, :default => 400
  end
end
