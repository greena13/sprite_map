# SpriteMap

Rails engine for generating and caching dynamic sprite maps from Paperclip attachments at runtime - perfect for optimising common searches or filters

## Guiding Principles

* Should work in terms of images, not domain concepts - you can combine images from multiple model types and styles (but **not** image formats).
* Should give you complete freedom when selecting a rendering option - works with rails html templates, JSON decorators, etc
* Should be as performant as possible - sprite maps are only generated when needed and cached. All work that can be pre-processed is done in advance.
* Should be as lightweight as possible - if you already have Paperclip installed, then you don't require any additional dependencies

## When should I NOT use SpriteMap?

* When you want a library that works **without** Ruby on Rails or Paperclip
* When your sprite maps can be determined at deploy time and do not depend on runtime data or behaviour. [SpriteSheet](https://github.com/jakesgordon/sprite-factory) seems to be the leading gem for this, but there are [many others](https://www.ruby-toolbox.com/search?utf8=%E2%9C%93&q=sprite) available.
* When you have not already considered optimising your production stack with technology like [HTTP/2](https://http2.github.io/faq/#why-is-http2-multiplexed ) compatible servers
* When you test SpriteMap on your production stack and it does not result in a measurable improvement in end user experience
* When you do not want or need the additional complexity of using sprite maps over individual images

## When should I use SpriteMap?

* When your sprite maps depend on runtime data, such as common search queries or filters
* When you have already considered HTTP/2 and it is not available on your server, some of your supported clients, or you [aren't convinced HTTP/2 is as fast as a sprite map](http://blog.octo.com/en/http2-arrives-but-sprite-sets-aint-no-dead/)
* When you see a measurable improvement in the average user experience by using SpirteMap
 
## Current limitations

* Only jpeg/jpg images are supported
## Usage
 
 ```ruby
@images = Image.where(id: search_results_ids) 

image_map = @images.inject({}) do |memo, photo|
 
   memo[photo.image_fingerprint + '-preview'] = photo.image.path(:preview)
   memo
   
 end
 
 @sprite_map = SpriteMap.find_or_create_by_image_map(image_map)
```

### Rails Views

```ruby
# Controller action

render @images, locals: { sprite_map: @sprite_map }

# View partial

<% pos = sprite_map.positions[image.fingerprint + '-preview'] %>
<%= image_tag 'placholder.gif', style="width: #{pos[:width]}px; height: #{pos[:height]}px; background: url(#{sprite_map.url}) #{pos[:x]}px #{pox[:y]}px no-repeat}" %>
```

### JSON Decorators

```ruby
# Controller action

@images = ImageDecorator.decorate_collection(@images, context: { sprite_map: sprite_map })

render json: @images, status: :ok


# Decorator

class ImageDecorator < Draper::Decorator
  def url
    context[:sprit_map].url
  end
  
  def position
    context[:sprite_map].positions[object.fingerprint + '-preview']
  end
end
```
 
## How it works

SpriteMap accepts an object or map of identifiers to filepaths. The identifiers should be unique to the image as they will be used for cache validation. It's recommended you calculate file fingerprints in advance using Paperclip and then append the style to the hash (the fingerprint is for the original file, only). Pathnames are used instead file instances, because: 

1. Paperclip provides easy access to the filepaths of images already uploaded
2. We don't want to perform file reads or instantiate complex objects unless we know we have to.

The identifiers are sorted (so the order images appear in the object don't matter, nor does it necessarily correspond with th order of the position the image will occupy in the final spritemap) and a MD5 hash is calculated from them. This is used as the identifier of the sprite map. The database is checked to see if there is already an entry with that hash (indicating the sprite map has already been created) and if so, it is instantiated.

If there is not already a sprite map, one is created by retrieving the image files at the provided filepaths, reading them in and concatenating them into a single file, which is then saved in the database using Paperclip to prevent having to generate it again.

## Installation

### Install SpriteMap

Add this line to your application's Gemfile:

    gem 'sprite_map'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sprite_map
    
### Run SpriteMap's migrations
    
Copy the migrations to your Rails application

    rake sprite_map:install:migrations
        
Run the migrations

    rake db:migrate
    
### Recommended: Generate fingerprints/checksums for your Paperclip attachments

It's also recommended that you generate fingerprints for your images as these will serve as useful identifiers for invalidating generated sprite maps. Please see the Paperclip documentation for how to do this:


#### Paperclip 5.x

Follow the [Paperclip 5.x documentation](https://github.com/thoughtbot/paperclip#checksum--fingerprint) and you're done.

#### Paperclip 4.x

Follow the [Paperclip 4.x documentation](https://github.com/thoughtbot/paperclip/tree/v4.3.7#md5-checksum--fingerprint) and then [regenerate your images](https://github.com/thoughtbot/paperclip/wiki/Thumbnail-Generation#generatingregenerating-your-thumbnails).

## Interface

### SpriteMap::ImageMap class object

#### find_or_create_by_image_map(image_map)

`image_map` must be an object of identifiers and file pathnames or urls. 

* keys: It's recommended you pre-calculate a fingerprint for all your images ([see here](Recommended:-Generate-fingerprints/checksums-for-your-Paperclip-attachments)) and then append the style name as done in the [usage example](Usage).
* values: Filepaths to your images. These can be attained using Paperclip's `path` method: `model.image.path(:style)`.
 
 This method creates a new sprite map from the files listed in `image_map` and returns an instance of `SpriteMap::ImageMap` (an ActiveRecord instance). If there is already a sprite map that corresponds with the list of images (and more specifically, their unique identifiers) then it is returned instead of recreating it. 
 
 It's also recorded in the database that this sprite map has been used, to help keep track of when each sprite map was last accessed.
  
### SpriteMap::ImageMap instance

#### positions

Returns the positions object, keyed by the files' unique identifiers. Each position object has the following structure:

```ruby
{
  x: x, #horizontal position in pixels of the top left-hand corner of the image
  y: y, #vertical position in pixels of the top left-hand corner of the image
  width: width, #width of image in pixels
  height: height #height of image in pixels
}

```

This is the object you will need to work with in your view layer to correctly display the correct section of the sprite map.

### url

Returns the url of the sprite image for you to do whatever you want with - insert into a Rails view, document or JSON response.


#### image

The Paperclip attachment instance for the image. Normally you do not need to interact with this directly.

#### fingerprint

Returns the MD5 fingerprint for the sprite map. Normally you should not need this as SpriteMap automatically generates this value and uses it for cache invalidation.

## To Do

* Support other image types and error handling for when images of different types are supplied
* Rake task for removing old sprite maps
* Test suite

## Contributing

All contributions, suggestions and issue are welcome.
