class RemoveResultFromRounds < ActiveRecord::Migration[6.0]
  def change
    remove_column :rounds, :result, :string #type doesn't matter
  end
end
