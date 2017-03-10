class CreateSpriteMapImageMaps < ActiveRecord::Migration
  def change
    create_table :sprite_map_image_maps do |t|
      t.string :fingerprint, null: false, default: '', index: true
      t.text :positions
      t.timestamps null: false
    end

    add_attachment :sprite_map_image_maps, :image
  end
end
