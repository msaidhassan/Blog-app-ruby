class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name
      t.string :email
      t.string :password_digest
      t.string :image

      t.timestamps
    end
    add_index :tags, :email
  end
end
