extends Control


var holdingMoveKey = false
var initialPos
var holdingPosition = false
var holdingSize = false
var movingCrop = false

var zoomIntervals = [0.025,0.05,0.1,0.15,0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 18.0,20.0]
var zoomLevel = 1.0

var holdingCTRL = false

var gridZoomLevel = 4



func _process(_delta):
	if $"../Gridbtn".button_pressed:
		$"../Gridbtn".modulate = Color(0.5,0.5,1)
		if zoomLevel > gridZoomLevel:
			$Center/Canvas/grid_potentially.set_grid_visibility(true)
		elif $Center/Canvas/grid_potentially.grid_visible:
			$Center/Canvas/grid_potentially.set_grid_visibility(false)
	else:
		$"../Gridbtn".modulate = Color(1,1,1)
		$Center/Canvas/grid_potentially.set_grid_visibility(false)
func _input(event):
	if event is InputEventKey and event.keycode == KEY_CTRL:
		holdingCTRL = event.pressed

func _gui_input(event):
		
	if event is InputEventMouseMotion:
		var canvas_pos = $Center/Canvas.global_position
		$Center.global_position = get_global_mouse_position()
		$Center.position = Vector2(int($Center.position[0]), int($Center.position[1]))
		$Center/Canvas.global_position = canvas_pos
		
	if (event is InputEventKey and event.keycode == KEY_SPACE and self.has_focus()) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE):
		self.grab_focus()
		holdingMoveKey = event.pressed
		initialPos = get_global_mouse_position()
	
	if event is InputEventMouseMotion and holdingMoveKey:
		$Center/Canvas.global_position += get_global_mouse_position() - initialPos
		initialPos = get_global_mouse_position()
	
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed) or (event is InputEventKey and event.keycode == KEY_KP_ADD and event.pressed):
		if zoomIntervals.find(zoomLevel) == len(zoomIntervals)-1:
			pass
		else:
			zoomLevel = zoomIntervals[(zoomIntervals.find(zoomLevel))+1]
			updateScale()
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed) or (event is InputEventKey and event.keycode == KEY_KP_SUBTRACT and event.pressed):
		if zoomIntervals.find(zoomLevel) == 0:
			pass
		else:
			zoomLevel = zoomIntervals[(zoomIntervals.find(zoomLevel))-1]
			updateScale()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and owner.spriteCropList.size() != 0:
		holdingPosition = (event.pressed and holdingCTRL)
		var rect_x = get_global_mouse_position().x >= $Center/Canvas/square.points[0].x*zoomLevel + $Center/Canvas.global_position.x and get_global_mouse_position().x <= $Center/Canvas/square.points[2].x*zoomLevel + $Center/Canvas.global_position.x
		var rect_y = get_global_mouse_position().y >= $Center/Canvas/square.points[0].y*zoomLevel + $Center/Canvas.global_position.y and get_global_mouse_position().y <= $Center/Canvas/square.points[2].y*zoomLevel + $Center/Canvas.global_position.y
		#print($Center/Canvas/square.points[0].x*zoomLevel + $Center/Canvas.global_position.x, " ", $Center/Canvas/square.points[2].x*zoomLevel + $Center/Canvas.global_position.x, " ", get_global_mouse_position().x, " ", rect_x)
		movingCrop = (event.pressed and not holdingCTRL) and (rect_x and rect_y)
		if movingCrop:
			initialPos = get_global_mouse_position()
		else:
			var selectedCrop = $"../../Layer2_SpriteEditor_Panels/PanelLeft/ItemList".selected
			var sprite = owner.spriteCropList[selectedCrop]
			var newCrop = [round(sprite.cropping_positions[0] * owner.spriteCropList[selectedCrop].texture.atlas.get_size().x)/owner.spriteCropList[selectedCrop].texture.atlas.get_size().x,
						round(sprite.cropping_positions[1] * owner.spriteCropList[selectedCrop].texture.atlas.get_size().y)/owner.spriteCropList[selectedCrop].texture.atlas.get_size().y,
						round(sprite.cropping_positions[2] * owner.spriteCropList[selectedCrop].texture.atlas.get_size().x)/owner.spriteCropList[selectedCrop].texture.atlas.get_size().x,
						round(sprite.cropping_positions[3] * owner.spriteCropList[selectedCrop].texture.atlas.get_size().y)/owner.spriteCropList[selectedCrop].texture.atlas.get_size().y]
			
			sprite.setCrop(newCrop)
			$"../../Layer2_SpriteEditor_Panels/PanelLeft/ItemList".update()
			
	if holdingPosition:
		var selectedCrop = $"../../Layer2_SpriteEditor_Panels/PanelLeft/ItemList".selected
		if selectedCrop != -1:
			var sprite = owner.spriteCropList[selectedCrop]
			var newPos = (Vector2(int($Center/Canvas.to_local(get_global_mouse_position())[0]), int($Center/Canvas.to_local(get_global_mouse_position())[1])) / owner.spriteCropList[selectedCrop].texture.atlas.get_size())
			var newCrop = [newPos[0],newPos[1],sprite.cropping_positions[2], sprite.cropping_positions[3]]
			
			if newCrop[0] < newCrop[2] and newCrop[1] < newCrop[3]:
				sprite.setCrop(newCrop)
			else:
				newCrop[2] = newCrop[0]+ (1/ owner.spriteCropList[selectedCrop].texture.atlas.get_size().x)
				newCrop[3] = newCrop[1]+ (1/ owner.spriteCropList[selectedCrop].texture.atlas.get_size().y)
				sprite.setCrop(newCrop)
			$"../../Layer2_SpriteEditor_Panels/PanelLeft/ItemList".update()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		holdingSize = (event.pressed and holdingCTRL)
	
	if holdingSize:
		var selectedCrop = $"../../Layer2_SpriteEditor_Panels/PanelLeft/ItemList".selected
		if selectedCrop != -1:
			var sprite = owner.spriteCropList[selectedCrop]
			var newPos = (Vector2(int($Center/Canvas.to_local(get_global_mouse_position())[0]), int($Center/Canvas.to_local(get_global_mouse_position())[1])) / owner.spriteCropList[selectedCrop].texture.atlas.get_size())
			var newCrop = [sprite.cropping_positions[0], sprite.cropping_positions[1],newPos[0],newPos[1]]
			
			if newCrop[0] < newCrop[2] and newCrop[1] < newCrop[3]:
				sprite.setCrop(newCrop)
			else:
				newCrop[2] = newCrop[0]+ (1/ owner.spriteCropList[selectedCrop].texture.atlas.get_size().x)
				newCrop[3] = newCrop[1]+ (1/ owner.spriteCropList[selectedCrop].texture.atlas.get_size().y)
				sprite.setCrop(newCrop)
			
			$"../../Layer2_SpriteEditor_Panels/PanelLeft/ItemList".update()
	if movingCrop:
		var selectedCrop = $"../../Layer2_SpriteEditor_Panels/PanelLeft/ItemList".selected
		if selectedCrop != -1:
			
			var sprite = owner.spriteCropList[selectedCrop]
			var newPos = ((get_global_mouse_position() - initialPos)/zoomLevel) / owner.spriteCropList[selectedCrop].texture.atlas.get_size()
			#print(newPos)
			var newCrop = [sprite.cropping_positions[0] + newPos.x,sprite.cropping_positions[1] + newPos.y,sprite.cropping_positions[2] + newPos.x, sprite.cropping_positions[3] + newPos.y]
			initialPos = get_global_mouse_position()
			sprite.setCrop(newCrop)
		$"../../Layer2_SpriteEditor_Panels/PanelLeft/ItemList".update()
func updateScale():
	
	for child in $Center/Canvas/other_crops.get_children():
		child.width = 1.0/zoomLevel
	
	$Center/Canvas/square.width = 1/zoomLevel
	$Center.scale = Vector2(zoomLevel, zoomLevel)
	$Center.global_position = Vector2(int($Center.global_position[0]), int($Center.global_position[1]))
	$Center/Canvas.global_position = Vector2(int($Center/Canvas.global_position[0]), int($Center/Canvas.global_position[1]))
	$zoomLabel.text = str(100*zoomLevel) + "%"

func _on_close_pressed():
	owner.toggleSpriteEditor()


func _on_zoom_label_pressed():
	$Center/Canvas.position = Vector2(0,0)
	if owner.spriteCropList.size() != 0:
		$Center.global_position = self.size/2 - owner.spriteCropList[$"../../Layer2_SpriteEditor_Panels/PanelLeft/ItemList".selected].texture.atlas.get_size()/2 + Vector2(128,0)
	zoomLevel = 1.0
	updateScale()

