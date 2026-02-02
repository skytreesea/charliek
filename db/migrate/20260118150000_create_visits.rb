class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.string :ip_address, null: false
      t.string :user_agent
      t.date :visited_date, null: false
      t.timestamps
    end

    add_index :visits, [:ip_address, :user_agent, :visited_date], unique: true, name: 'index_visits_on_unique_visit'
    add_index :visits, :visited_date
  end
end
