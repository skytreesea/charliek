class AddAttachmentToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :attachment_file_path, :string
  end
end
