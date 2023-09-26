extends ItemList


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func update():
	self.clear()
	for i in owner.spriteCropList:
		self.add_icon_item(i.texture)
	self.add_icon_item(load("res://Graphics/add_sprite.png"))
	
	$"../../../Layer2_SpriteEditor_Canvas/Control/Center/Canvas/square".clear_points()
	if selected != -1 and owner.spriteCropList.size() != 0:
		$"../../../Layer2_SpriteEditor_Canvas/SpinBox".visible = true
		#print(owner.spriteCropList[selected])
		
		var texIDX = owner.spriteCropList[selected].texIDX
		$"../../../Layer2_SpriteEditor_Canvas/Control/Center/Canvas/texture".texture = owner.textureList[texIDX]
		
		var topleft = owner.spriteCropList[selected].texture.region.position
		var topright = owner.spriteCropList[selected].texture.region.position + Vector2(owner.spriteCropList[selected].texture.region.size.x, 0)
		var bottomright =  owner.spriteCropList[selected].texture.region.position + owner.spriteCropList[selected].texture.region.size
		var bottomleft = topleft + Vector2(0,owner.spriteCropList[selected].texture.region.size.y)
		
		$"../../../Layer2_SpriteEditor_Canvas/Control/Center/Canvas/square".add_point(topleft)
		$"../../../Layer2_SpriteEditor_Canvas/Control/Center/Canvas/square".add_point(topright)
		$"../../../Layer2_SpriteEditor_Canvas/Control/Center/Canvas/square".add_point(bottomright)
		$"../../../Layer2_SpriteEditor_Canvas/Control/Center/Canvas/square".add_point(bottomleft)
		$"../../../Layer2_SpriteEditor_Canvas/Control/Center/Canvas/square".add_point(topleft)
		select(selected)
		
		for child in $"../../../Layer2_SpriteEditor_Canvas/Control/Center/Canvas/other_crops".get_children():
			child.queue_free()
		
		var texturerect = Line2D.new()
		texturerect.add_point(Vector2(0,0))
		texturerect.add_point(Vector2(owner.spriteCropList[selected].texture.atlas.get_size().x,0))
		texturerect.add_point(owner.spriteCropList[selected].texture.atlas.get_size())
		texturerect.add_point(Vector2(0,owner.spriteCropList[selected].texture.atlas.get_size().y))
		texturerect.add_point(Vector2(0,0))
		texturerect.width = 1.0 / $"../../../Layer2_SpriteEditor_Canvas/Control".zoomLevel
		texturerect.modulate = Color(0.3,0.3,0.3,1)
		$"../../../Layer2_SpriteEditor_Canvas/Control/Center/Canvas/other_crops".add_child(texturerect)
		
		$"../../../Layer2_SpriteEditor_Canvas/SpinBox".max_value = owner.textureList.size()-1
		
		for sprite in owner.spriteCropList:
			# 
			if sprite.texIDX == owner.spriteCropList[selected].texIDX and sprite != owner.spriteCropList[selected]:
				var square = Line2D.new()
				var sq_size = (Vector2(sprite.cropping_positions[2], sprite.cropping_positions[3]) - Vector2(sprite.cropping_positions[0], sprite.cropping_positions[1])) * owner.spriteCropList[selected].texture.atlas.get_size()
				var sq_position = Vector2(sprite.cropping_positions[0], sprite.cropping_positions[1]) * owner.spriteCropList[selected].texture.atlas.get_size()
				
				square.add_point(sq_position)
				square.add_point(sq_position + Vector2(sq_size.x,0))
				square.add_point(sq_position + sq_size)
				square.add_point(sq_position + Vector2(0,sq_size.y))
				square.add_point(sq_position)
				
				square.width = 1.0 / $"../../../Layer2_SpriteEditor_Canvas/Control".zoomLevel
				
				square.modulate = Color(1,0,0,1)
				$"../../../Layer2_SpriteEditor_Canvas/Control/Center/Canvas/other_crops".add_child(square)
				#print("square ", sprite.cropping_positions)
		
	else:
		$"../../../Layer2_SpriteEditor_Canvas/SpinBox".visible = false
var selected = -1
var ignore = false

func _on_item_clicked(index, _at_position, _mouse_button_index):
	if index in range(owner.spriteCropList.size()) and _mouse_button_index == 1:
		#print("selected idx " + str(index))
		ignore = true
		$"../../../Layer2_SpriteEditor_Canvas/SpinBox".value = owner.spriteCropList[index].texIDX
		ignore = false
		selected = index
		update()
		
	clicked_currently = index

var clicked_currently = 0
func _on_item_activated(index):
	if not index in range(owner.spriteCropList.size()):
		owner.newSpriteCrop()
		selected = owner.spriteCropList.size() -1
		update()


func _on_spin_box_value_changed(value):
	if not ignore:
		owner.spriteCropList[selected].setOgTexture(owner.textureList[value], value)
		update()


func _on_gui_input(event):
	if event is InputEventKey and event.keycode == KEY_DELETE and event.pressed:
		if clicked_currently != -1 and clicked_currently in range(owner.spriteCropList.size()):
			#owner.spriteCropList[clicked_currently].queue_free()
			var spriteCrop = owner.spriteCropList[selected]

			for layer in owner.LayerList:
				for element in layer:
					for sprite in element.sprite_list:
						#print(sprite, spriteCrop.texture)
						if sprite == spriteCrop.texture:
							element.sprite_list.erase(sprite)
			
			owner.spriteCropList.pop_at(selected)
			
			if selected != 0:
				selected -= 1
			
			update()
