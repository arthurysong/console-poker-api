class CreateRounds < ActiveRecord::Migration[6.0]
  def change
    create_table :rounds do |t|
      t.integer :game_id

      t.integer :phase, :default => 0
      t.integer :turn_count, :default => 0
      t.integer :no_players_for_phase, :default => 0
      t.integer :small_blind_index, :default => 0
      t.integer :turn_index, :default => 0
      t.integer :pot, :default => 0
      t.integer :highest_bet_for_phase, :default => 0
      t.string :community_cards
      t.text :status, array: true, :default => []
      t.text :result, array: true, :default => []
      t.boolean :is_playing, :default => false
      t.boolean :all_in, :default => false

      t.timestamps
    end
  end
end
