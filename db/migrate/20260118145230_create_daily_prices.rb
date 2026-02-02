class CreateDailyPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_prices do |t|
      t.string :ticker, null: false
      t.date :date, null: false
      t.decimal :close_price, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :daily_prices, [:ticker, :date], unique: true
  end
end
