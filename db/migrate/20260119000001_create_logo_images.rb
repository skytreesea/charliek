class CreateLogoImages < ActiveRecord::Migration[8.1]
  def change
    create_table :logo_images do |t|
      t.timestamps
    end
  end
end
