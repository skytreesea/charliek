class AddWritingStyleToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :writing_style, :string, default: "official"
  end
end
