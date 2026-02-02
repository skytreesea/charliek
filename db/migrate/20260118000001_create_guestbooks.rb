class CreateGuestbooks < ActiveRecord::Migration[8.1]
  def change
    create_table :guestbooks do |t|
      t.string :name, null: false, limit: 50
      t.text :content, null: false, limit: 300

      t.timestamps
    end
    
    add_index :guestbooks, :created_at
  end
end
