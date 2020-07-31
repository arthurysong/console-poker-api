class ChangeColumnsInRounds < ActiveRecord::Migration[6.0]
  def change
    add_column :rounds, :seats, :integer, array: true, :default => [nil, nil, nil, nil, nil, nil, nil, nil]
    remove_column :rounds, :status, :string #type doesn't matter
  end
end
