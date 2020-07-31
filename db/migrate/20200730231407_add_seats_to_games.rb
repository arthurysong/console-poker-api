class AddSeatsToGames < ActiveRecord::Migration[6.0]
  def change
    add_column :games, :seats, :integer, array: true, :default => [nil, nil, nil, nil, nil, nil, nil, nil]
  end
end
