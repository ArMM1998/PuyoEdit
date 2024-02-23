class_name PuyoSprite

var cropping_positions = [0.0,0.0,0.0,0.0]
var texture_size = Vector2()
var texture = AtlasTexture.new()
var texIDX = 0
var og_texture 

func setOgTexture(newtexture : Texture2D, idx : int):
	og_texture = newtexture
	texture_size = newtexture.get_size()
	texture.atlas = newtexture
	texture.filter_clip = false
	texIDX = idx
	updateCroppedTexture()

func setCrop(crop : Array):
	cropping_positions = crop
	updateCroppedTexture()

func updateCroppedTexture():
	var img_size = texture.atlas.get_size()
	var texture_region = Rect2(
		round(img_size[0]*cropping_positions[0]),
		round(img_size[1]*cropping_positions[1]), 
		round(img_size[0]*cropping_positions[2]) - round(img_size[0]*cropping_positions[0]), 
		round(img_size[1]*cropping_positions[3]) - round(img_size[1]*cropping_positions[1]))
	texture.region = texture_region
