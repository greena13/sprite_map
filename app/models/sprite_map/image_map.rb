module SpriteMap
  class ImageMap < ActiveRecord::Base
    validates :positions, :image, :fingerprint, presence: true

    serialize :positions

    has_attached_file :image

    validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/

    def self.find_or_create_by_image_map(image_map)
      fingerprint = Digest::MD5.hexdigest(image_map.keys.sort.join('-'))

      if (sprite_map = ImageMap.find_by(fingerprint: fingerprint))
        sprite_map.touch
        sprite_map
      else
        total_width = 0
        total_height = 0

        images = {}

        positions = image_map.inject({}) do |memo, (identifier, path)|
          image_file = Magick::Image.read(path)[0]

          image_width = image_file.columns
          image_height = image_file.rows

          memo[identifier] = {
              x: total_width,
              y: 0,
              width: image_width,
              height: image_height
          }

          images[identifier] = {
              path: path,
              file: image_file
          }

          total_width += image_width
          total_height = [total_height, image_height].max
          memo
        end

        create_sprite_image(
            fingerprint: fingerprint,
            positions: positions,
            images: images,
            width: total_width,
            height: total_height
        )
      end
    end

    def url
      image.url(:original)
    end

    private

    def self.create_sprite_image(fingerprint:, images:, positions:, width:, height:)
      sprite_map_image = Magick::Image.new(width, height)
      sprite_map_image.opacity = Magick::QuantumRange

      positions.each do |identifier, image_options|
        sprite_map_image.composite!(
            images[identifier][:file], image_options[:x], 0, Magick::SrcOverCompositeOp
        )
      end

      file = Tempfile.new([fingerprint, '.jpg'])
      sprite_map_image.write(file.path)

      ImageMap.create!(
          positions: positions,
          image: file,
          fingerprint: fingerprint
      )
    end

  end

end
