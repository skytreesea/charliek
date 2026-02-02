class CreateHomeImages < ActiveRecord::Migration[8.1]
  def change
    create_table :home_images do |t|
      t.timestamps
    end
  end
end
