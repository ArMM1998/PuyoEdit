extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$ElementStuff/ElementRect.rotation_degrees = 0
	$ElementStuff/ElementRect.global_position = Vector2(0,0)
signal selected_element
var zoomIntervals = [0.025,0.05,0.1,0.15,0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 18.0,20.0]
var zoomLevel = 1.0

var holdingMoveKey = false
var initialPos = Vector2(0,0)
var holdingAlt = false
var initialMousePos = Vector2(0,0)
var initialElementPos = Vector2(0,0)
var cursor_reset = false
var draggingPivot = false
var draggingElement = false
var draggingScaleX = false
var draggingScaleY = false
var draggingAngle = false
var undoBlock = false
var initialMouseAngle = Vector2(0,0)
var inverY = false
var inverX = false
var holdingControl = false
var holdingShift = false


func _process(_delta):
	if draggingPivot or draggingElement or draggingScaleX or draggingScaleY or draggingAngle:
		undoBlock = true
	else:
		undoBlock = false
	
	if holdingMoveKey:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_MOVE)
		cursor_reset = true
	elif cursor_reset:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
	if owner.selected_element > -1 and not owner.playing:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		$ElementStuff.visible = true
		
		$ElementStuff/MoveButton.global_position = element.global_position
		if element.scaley < 0:
			$ElementStuff/posMoveScaleTop/ScaleTop.position = Vector2(-8,8)
			$ElementStuff/posMoveScaleBottom/ScaleBottom.position = Vector2(-8,-24)
			$ElementStuff/posRotate.scale.y = -1
		else:
			$ElementStuff/posMoveScaleTop/ScaleTop.position = Vector2(-8,-24)
			$ElementStuff/posMoveScaleBottom/ScaleBottom.position = Vector2(-8,8)
			$ElementStuff/posRotate.scale.y = 1
		
		element.transformTop.position = Vector2(-element.pivot_point[0] + element.element_size[0]/2, -element.pivot_point[1])
		element.transformBottom.position = Vector2(-element.pivot_point[0] + element.element_size[0]/2, -element.pivot_point[1] + element.element_size[1])
		element.transformLeft.position = Vector2(-element.pivot_point[0], -element.pivot_point[1] + element.element_size[1]/2)
		element.transformRight.position = Vector2(-element.pivot_point[0] + element.element_size.x, -element.pivot_point[1] + element.element_size[1]/2)
		
		
		#corners
		element.transformTopLeft.position = -element.pivot_point
		element.transformBottomLeft.position = -element.pivot_point + Vector2(0,element.element_size[1])
		element.transformBottomRight.position = -element.pivot_point + element.element_size
		element.transformTopRight.position = -element.pivot_point + Vector2(element.element_size[0],0)
		$ElementStuff/ElementRect.global_position = Vector2(0,0)
		$ElementStuff/ElementRect.set_point_position(0, element.transformTopLeft.global_position )
		$ElementStuff/ElementRect.set_point_position(1, element.transformTopRight.global_position )
		$ElementStuff/ElementRect.set_point_position(2, element.transformBottomRight.global_position)
		$ElementStuff/ElementRect.set_point_position(3, element.transformBottomLeft.global_position)
		$ElementStuff/ElementRect.set_point_position(4, element.transformTopLeft.global_position)
		
		$ElementStuff/posMoveScaleBottom.global_position = element.transformBottom.global_position
		$ElementStuff/posMoveScaleRight.global_position = element.transformRight.global_position
		$ElementStuff/posRotate.global_position = element.transformBottomRight.global_position
		
		var btnAngle = 0
		var offset = element.transformRight.global_position - element.transformLeft.global_position
		btnAngle = (int(atan2(offset.y, offset.x)* 180 / PI) + 360) % 360
		
		if element.scalex < 0:
			btnAngle -= 180
		
		$ElementStuff/posMoveScaleRight.rotation_degrees = btnAngle
		$ElementStuff/posRotate.rotation_degrees = btnAngle
		$ElementStuff/posMoveScaleTop.rotation_degrees = btnAngle
		$ElementStuff/posMoveScaleSide.rotation_degrees = btnAngle
		$ElementStuff/posMoveScaleBottom.rotation_degrees = btnAngle
		
		$ElementStuff/posMoveScaleSide.global_position = element.transformLeft.global_position
		$ElementStuff/posMoveScaleSide.position = Vector2(round($ElementStuff/posMoveScaleSide.position[0]), round($ElementStuff/posMoveScaleSide.position[1]))
		
		$ElementStuff/posMoveScaleTop.global_position = element.transformTop.global_position
		$ElementStuff/posMoveScaleSide.global_position = element.transformLeft.global_position
		
		$ElementStuff/posMoveScaleTop.position = Vector2(round($ElementStuff/posMoveScaleTop.position[0]), round($ElementStuff/posMoveScaleTop.position[1]))
		
		if element.scalex < 0:
			$ElementStuff/posMoveScaleSide/ScaleSide.position = Vector2(8,-8)
			$ElementStuff/posMoveScaleRight/ScaleRight.position = Vector2(-24,-8)
			$ElementStuff/posRotate.scale.x = -1
		else:
			$ElementStuff/posMoveScaleSide/ScaleSide.position = Vector2(-24,-8)
			$ElementStuff/posMoveScaleRight/ScaleRight.position = Vector2(8,-8)
			$ElementStuff/posRotate.scale.x = 1
	else:
		$ElementStuff.visible = false

func _gui_input(event):
	var cursor_pos_text = (get_global_mouse_position() - $posScreenRect.global_position)/zoomLevel
	cursor_pos_text = Vector2(snapped(cursor_pos_text[0], 0.1), snapped(cursor_pos_text[1], 0.1))
	$cursorPosLabel.text = str(cursor_pos_text)
	if event is InputEventKey and event.keycode == KEY_F11 and event.pressed:
		owner.toggle_fullscreen()
	if not owner.fullscreen:
		#print(owner.fullscreen)
		if self.has_focus():
			owner.panel_right.update()
		
		
		if event is InputEventKey and event.keycode == KEY_C and owner.selected_element != -1 and holdingControl and event.pressed:
			owner.clipboardElement()
		if event is InputEventMouseButton and event.pressed:
			grab_focus()
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			holdingMoveKey = event.pressed
			initialPos = get_global_mouse_position()
		
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not owner.playing:
			var rect = Rect2($ElementStuff/MoveButton.get_global_transform()[2][0]-8, $ElementStuff/MoveButton.get_global_transform()[2][1]-8,
							16 , 16)
			if rect.has_point(get_global_mouse_position()):
				draggingPivot = true
				initialMousePos = get_global_mouse_position()
				var element = owner.LayerList[owner.selected_layer][owner.selected_element]
				owner.add_undo(element.setPivot, element.getPivot, element.pivot_point, "value", element)
				initialElementPos = element.pivot_point
				#get_viewport().warp_mouse(element.sprite_rect.global_position)

		if event is InputEventMouseMotion:
			var canvas_pos = $Center/Canvas.global_position
			$Center.global_position = get_global_mouse_position()
			$Center.position = Vector2(int($Center.position[0]), int($Center.position[1]))
			$Center/Canvas.global_position = canvas_pos
		
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
		
		
		if event is InputEventKey and event.keycode == KEY_P and event.pressed and self.has_focus() and owner.selected_element != -1 and not owner.playing:
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			var screen_center = $posScreenRect.global_position + (Vector2(owner.project_settings["screen_size"][0], owner.project_settings["screen_size"][1])/2)*zoomLevel
			if element.global_position != screen_center:
				owner.add_undo(element.setPosition, element.getPosition, element.position, "value", element)
				element.global_position = ($posScreenRect.global_position + (Vector2(owner.project_settings["screen_size"][0], owner.project_settings["screen_size"][1])/2)*zoomLevel)
				checkKeyframeSaving(element, element.position.x / owner.project_settings["screen_size"][0], "posx")
				checkKeyframeSaving(element, element.position.y / owner.project_settings["screen_size"][1], "posy")
				element.setPosition(element.position)
				
				
		if event is InputEventKey and event.keycode == KEY_KP_1 and self.has_focus() and event.pressed:
			zoomLevel = 1.0
			updateScale()
		
		if event is InputEventKey and event.keycode == KEY_KP_2 and self.has_focus() and event.pressed:
			zoomLevel = 2.0
			updateScale()
		
		if event is InputEventKey and event.keycode == KEY_KP_3 and self.has_focus() and event.pressed:
			zoomLevel = 3.0
			updateScale()
		
		if event is InputEventKey and event.keycode == KEY_KP_4 and self.has_focus() and event.pressed:
			zoomLevel = 4.0
			updateScale()
		
		if event is InputEventKey and event.keycode == KEY_F and self.has_focus() and event.pressed:
			owner.toggleField()
		
		if event is InputEventKey and event.keycode == KEY_S and self.has_focus() and event.pressed and not holdingControl:
			owner.toggleScreen()
		
		if event is InputEventKey and event.keycode == KEY_A and self.has_focus() and event.pressed:
			owner.toggleAxis()
		
		if event is InputEventKey and event.keycode == KEY_ALT and self.has_focus():
			holdingAlt = event.pressed
		
		if event is InputEventKey and (event.keycode == KEY_PAGEUP or event.keycode == 4194323) and self.has_focus() and event.pressed and not owner.playing:
			if holdingControl:
				owner.move_element_front()
			else:
				owner.move_element_up()
			self.grab_focus()
			
		if event is InputEventKey and (event.keycode == KEY_PAGEDOWN or event.keycode == 4194324) and self.has_focus() and event.pressed and not owner.playing:
			if holdingControl:
				owner.move_element_back()
			else:
				owner.move_element_down()
			self.grab_focus()
		updateObjectPositions()

func customFloor(value: float) -> int:
	var intValue = int(value)
	if value < 0 and value != intValue:
		intValue -= 1
	return intValue

func customFmodf(a: float, b: float) -> float:
	var quotient = a / b
	var wholePart = customFloor(quotient)
	var remainder = a - (wholePart * b)
	return remainder

func _input(event):
	
	if event is InputEventKey and event.keycode == KEY_Z:
		updateKeyPos = event.pressed and (not draggingElement)
	
	if event is InputEventKey and event.keycode == KEY_CTRL:
		holdingControl = event.pressed
		
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		holdingShift = event.pressed
	
	if event is InputEventKey and event.keycode == KEY_ENTER and holdingControl and event.pressed:
		owner.playing = not owner.playing
		if owner.playing:
			$status_message.displayMessage("Play")
		else:
			$status_message.displayMessage("Pause")
	
	if event is InputEventKey and event.keycode == KEY_L and holdingControl and event.pressed:
			owner.loop.button_pressed = not owner.loop.button_pressed
			if owner.loop.button_pressed:
				$status_message.displayMessage("Looping Enabled")
			else:
				$status_message.displayMessage("Looping Disabled")
	if not owner.fullscreen:
		
		if event is InputEventKey and event.keycode == KEY_SPACE and self.has_focus():
			holdingMoveKey = event.pressed
			initialPos = get_global_mouse_position()
		
		
		if event is InputEventKey and event.keycode == KEY_D and holdingControl and event.pressed:
			owner.duplicate_element()
		
		
		
		if event is InputEventMouseButton and not event.pressed:
			if draggingElement:
				checkKeyframeSavingPos(owner.LayerList[owner.selected_layer][owner.selected_element], pos_diff)
			draggingElement = false
			draggingScaleY = false
			draggingScaleX = false
			draggingAngle = false
			changing = false
			$ElementStuff/posMoveAlongX.visible = false
			$ElementStuff/posMoveAlongY.visible = false
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
			holdingMoveKey = false
		
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			draggingPivot = false
			
		if event is InputEventMouseMotion and holdingMoveKey:
			$Center/Canvas.global_position += get_global_mouse_position() - initialPos
			initialPos = get_global_mouse_position()
			updateObjectPositions()
			
		if event is InputEventMouseMotion and draggingElement:
			
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			if holdingShift:
				if abs(initialMousePos.x - get_global_mouse_position().x) > abs(initialMousePos.y - get_global_mouse_position().y):
					element.global_position = Vector2((get_global_mouse_position() - (initialMousePos - initialElementPos)).x, initialElementPos.y)
					
					
					checkKeyframeSaving(element, element.position.x / owner.project_settings["screen_size"][0], "posx")
					element.setPositionX(element.position.x)
					checkKeyframeSaving(element, element.position.y / owner.project_settings["screen_size"][1], "posy")
					element.setPositionY(element.position.y)
					
					
					
					$ElementStuff/posMoveAlongX.visible = true
					$ElementStuff/posMoveAlongY.visible = true
					
					$ElementStuff/posMoveAlongY.modulate = Color(1,1,1,0.5)
					$ElementStuff/posMoveAlongX.modulate = Color(1,1,1,1)
					$ElementStuff/posMoveAlongY.global_position = initialElementPos
					$ElementStuff/posMoveAlongX.global_position = element.global_position
					
					element.setPosition(element.position)
					
				else:
					element.global_position = Vector2(initialElementPos.x, (get_global_mouse_position() - (initialMousePos - initialElementPos)).y)
					checkKeyframeSaving(element, element.position.x / owner.project_settings["screen_size"][0], "posx")
					element.setPositionX(element.position.x)
					checkKeyframeSaving(element, element.position.y / owner.project_settings["screen_size"][1], "posy")
					element.setPositionY(element.position.y)
					
					$ElementStuff/posMoveAlongX.visible = true
					$ElementStuff/posMoveAlongY.visible = true
					
					$ElementStuff/posMoveAlongX.modulate = Color(1,1,1,0.5)
					$ElementStuff/posMoveAlongY.modulate = Color(1,1,1,1)
					$ElementStuff/posMoveAlongY.global_position = element.global_position
					$ElementStuff/posMoveAlongX.global_position = initialElementPos
					
					element.setPosition(element.position)
					
			else:
				$ElementStuff/posMoveAlongX.visible = false
				$ElementStuff/posMoveAlongY.visible = false
				element.global_position = get_global_mouse_position() - (initialMousePos - initialElementPos)
				checkKeyframeSaving(element, element.position.x / owner.project_settings["screen_size"][0], "posx")
				checkKeyframeSaving(element, element.position.y / owner.project_settings["screen_size"][1], "posy")
				element.setPosition(element.position)
				
			
			if locktogrid:
				element.position = Vector2(round(snappedf(element.position[0], owner.project_settings["screen_size"][0]/60)), round(snappedf(element.position[1], owner.project_settings["screen_size"][0]/60)))
				checkKeyframeSaving(element, element.position.x / owner.project_settings["screen_size"][0], "posx")
				checkKeyframeSaving(element, element.position.y / owner.project_settings["screen_size"][1], "posy")
				element.setPosition(element.position)
				
			if holdingAlt:
				element.position = Vector2(round(element.position[0]), round(element.position[1]))
				
				checkKeyframeSaving(element, element.position.x / owner.project_settings["screen_size"][0], "posx")
				checkKeyframeSaving(element, element.position.y / owner.project_settings["screen_size"][1], "posy")
				element.setPosition(element.position)
				
			$status_message.displayMessage("Updated " + element.element_name + " position to: " + str(element.position))
			
		
		if event is InputEventMouseMotion and draggingPivot:
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			element.setPivot(-element.to_local(get_global_mouse_position()) + initialElementPos)
			if holdingAlt:
				element.setPivot(Vector2(round(element.pivot_point[0]), round(element.pivot_point[1])))
			$status_message.displayMessage("Updated " + element.element_name + " pivot point to: " + str(element.pivot_point))
			
		if event is InputEventMouseMotion and draggingScaleY:
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			var globalMousePos = get_global_mouse_position() - initialMousePos + element.global_position
			var localMousePos = element.to_local(globalMousePos)
			var distance = localMousePos.y
			distance = distance*element.scaley
			if inverY:
				distance = -distance
			var localScaleY = distance / (element.element_size.y/2)
			localScaleY = -localScaleY + initialElementPos
			if holdingAlt:
				localScaleY = snapped(localScaleY, 0.25)
			
			checkKeyframeSaving(element, localScaleY, "scaley")
				
			element.setScaley(localScaleY)
			
			if element.scaley == 0 or element.scaley == -0:
				element.setScaley(0.00001)
			
			$status_message.displayMessage("Updated " + element.element_name + " scale to : " + str(Vector2(element.scalex, element.scaley)))
			element.saveDefaults = true
		if event is InputEventMouseMotion and draggingScaleX:
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			var globalMousePos = get_global_mouse_position() - initialMousePos + element.global_position
			var localMousePos = element.to_local(globalMousePos)
			var distance = localMousePos.x
			distance = distance*element.scalex
			if inverX:
				distance = -distance
			var localScaleX = distance / (element.element_size.x)
			localScaleX = -localScaleX + initialElementPos
			if holdingAlt:
				localScaleX = snapped(localScaleX, 0.25)
			
			checkKeyframeSaving(element, localScaleX, "scalex")
			
			element.setScalex(localScaleX)
			
			if element.scalex == 0  or element.scalex == -0:
				element.setScalex(0.00001)
			$status_message.displayMessage("Updated " + element.element_name + " scale to : " + str(Vector2(element.scalex, element.scaley)))
		
		if event is InputEventMouseMotion and draggingAngle:
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			var offset = get_global_mouse_position() - element.global_position
			var angle = customFmodf(((atan2(offset.y, offset.x)* 180 / PI) + 360), 360)
			angle = initialElementPos + (angle - initialMouseAngle)
			if angle > 180:
				angle = angle-360
				initialMouseAngle += -180
				initialElementPos += -180
			if angle < -180:
				angle = angle+360
				initialMouseAngle += +180
				initialElementPos += +180
			if holdingShift:
				angle = snapped(angle, 22.5)
			else:
				angle = snapped(angle, 0.01)
			
			checkKeyframeSaving(element, -angle, "angle")
			
			element.setAngle(angle)
			$status_message.displayMessage("Updated " + element.element_name + " angle to : " + str(element.angle) + "º")
		
		if event is InputEventKey and event.keycode == KEY_F1 and event.pressed:
			owner.layer_2_panels.togglePanels()
			self.grab_focus()
		
		if event is InputEventKey and event.keycode == KEY_DELETE and (self.has_focus() or owner.element_list.has_focus()) and event.pressed and owner.selected_element > -1:
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			owner.delElement(element, true)


func updateScale():
	$Center.scale = Vector2(zoomLevel, zoomLevel)
	$Center.global_position = Vector2(int($Center.global_position[0]), int($Center.global_position[1]))
	$Center/Canvas.global_position = Vector2(int($Center/Canvas.global_position[0]), int($Center/Canvas.global_position[1]))
func updateObjectPositions():
	#update positions
	$posAxis.global_position = $Center/Canvas.global_position
	$posAxis/Y.global_position = Vector2($posAxis/Y.global_position[0], 0)
	$posAxis/X.global_position = Vector2(0,$posAxis/X.global_position[1])
	$posScreenRect.global_position = $Center/Canvas.global_position
	$posScreenRect.visible = not owner.user_settings["hide_screen"]
	$posAxis.visible = not owner.user_settings["hide_axis"]
	#update screen rect size
	$posScreenRect/ScreenRect.set_point_position(1, Vector2(owner.project_settings["screen_size"][0], 0)*zoomLevel)
	$posScreenRect/ScreenRect.set_point_position(2, Vector2(owner.project_settings["screen_size"][0], owner.project_settings["screen_size"][1])*zoomLevel)
	$posScreenRect/ScreenRect.set_point_position(3, Vector2(0, owner.project_settings["screen_size"][1])*zoomLevel)
	
	#update field rect
	if owner.project_settings["field"] is Array and owner.project_settings["hide_field"] == false:
		$posFieldRect/FieldRect.global_position = Vector2(owner.project_settings["field"][0], owner.project_settings["field"][1])*zoomLevel + $posAxis.global_position
		$posFieldRect/FieldRect.set_point_position(1, Vector2(owner.project_settings["field"][2], 0)*zoomLevel)
		$posFieldRect/FieldRect.set_point_position(2, Vector2(owner.project_settings["field"][2], owner.project_settings["field"][3])*zoomLevel)
		$posFieldRect/FieldRect.set_point_position(3, Vector2(0, owner.project_settings["field"][3])*zoomLevel)
		$posFieldRect/FieldRect.visible = true
	else:
		$posFieldRect/FieldRect.visible = false
	
	#update checkerboard background
	$checkbg.position = Vector2(int(str(int($Center/Canvas.global_position[0])).right(2)),int(str(int($Center/Canvas.global_position[1])).right(2))) - Vector2(178,122)
	
	#update zoom label
	$zoomLabel.text = str(100*zoomLevel) + "%"

func resetZoom():
	zoomLevel = 1.0
	$Center.position = self.size/2
	$Center/Canvas.position = Vector2(0,0) - Vector2(owner.project_settings["screen_size"][0], owner.project_settings["screen_size"][1])/2
	updateScale()
	updateObjectPositions()
	self.grab_focus()

func snap_to_closest_zoom(lvl_of_zoom) -> float:
	var minIndex = 0
	var minDifference = abs(lvl_of_zoom - zoomIntervals[0])

	for i in range(1, zoomIntervals.size()):
		var difference = abs(lvl_of_zoom - zoomIntervals[i])
		if difference < minDifference:
			minDifference = difference
			minIndex = i
	#print(typeof(zoomIntervals[minIndex]))
	return float(zoomIntervals[minIndex])

func fillZoom():
	# Calculate the scale factor for X and Y dimensions separately
	var scaleX = self.size.x / owner.project_settings["screen_size"][0]
	var scaleY = self.size.y / owner.project_settings["screen_size"][1]
	# Choose the smaller scale factor to ensure both dimensions fit within rect1
	zoomLevel = min(scaleX, scaleY)
	zoomLevel = snap_to_closest_zoom(zoomLevel)
	
	
	#print(self.size)
	#print(owner.project_settings["screen_size"])
	
	$Center.position = self.size/2
	$Center/Canvas.position = Vector2(0,0) - Vector2(owner.project_settings["screen_size"][0]/2, owner.project_settings["screen_size"][1]/2)
	updateScale()
	updateObjectPositions()
	self.grab_focus()


func _on_focus_entered():
	$focusIndicator.visible = true


func _on_focus_exited():
	$focusIndicator.visible = false


func _on_scale_top_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		draggingScaleY = true
		draggingElement = false
		draggingScaleX = false
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		owner.add_undo(element.setScaley, element.getScaley, element.scaley, "value", element)
		initialElementPos = element.scaley
		element.transformTop.global_position = $ElementStuff/posMoveScaleTop.global_position
		initialMousePos = get_global_mouse_position()
		inverY = false
		self.grab_focus()


func _on_scale_side_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		draggingScaleX = true
		draggingScaleY = false
		draggingElement = false
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		owner.add_undo(element.setScalex, element.getScalex, element.scalex, "value", element)
		initialElementPos = element.scalex
		initialMousePos = get_global_mouse_position()
		inverX = false
		self.grab_focus()
		


func _on_angle_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		draggingAngle = true
		initialMousePos = get_global_mouse_position()
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		owner.add_undo(element.setAngle, element.getAngle, element.angle, "value", element)
		var offset = get_global_mouse_position() - element.global_position
		initialMouseAngle = customFmodf(((atan2(offset.y, offset.x)* 180 / PI) + 360), 360)
		initialElementPos = element.angle
		element.transformLeft.global_position = $ElementStuff/posRotate.global_position
		self.grab_focus()


func _on_scale_bottom(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		draggingScaleY = true
		draggingElement = false
		draggingScaleX = false
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		owner.add_undo(element.setScaley, element.getScaley, element.scaley, "value", element)
		initialElementPos = element.scaley
		initialMousePos = get_global_mouse_position()
		inverY = true
		self.grab_focus()


func _on_scale_right_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		draggingScaleX = true
		draggingScaleY = false
		draggingElement = false
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		owner.add_undo(element.setScalex, element.getScalex, element.scalex, "value", element)
		initialElementPos = element.scalex
		initialMousePos = get_global_mouse_position()
		inverX = true
		self.grab_focus()

func _on_checkbg_gui_input(event):
	if not (owner.panel_right.color.button_pressed or owner.panel_right.color_tl.button_pressed or owner.panel_right.color_tr.button_pressed or owner.panel_right.color_bl.button_pressed or owner.panel_right.color_br.button_pressed or owner.fullscreen):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and owner.selected_element != -1:
			var alreadySelectedElement = owner.LayerList[owner.selected_layer][owner.selected_element]
				
			var element_points = [alreadySelectedElement.transformTopLeft.global_position,
									alreadySelectedElement.transformTopRight.global_position,
									alreadySelectedElement.transformBottomRight.global_position,
									alreadySelectedElement.transformBottomLeft.global_position]
			if is_point_inside_polygon(element_points):
				draggingPivot = true
				initialMousePos = get_global_mouse_position()
				var element = owner.LayerList[owner.selected_layer][owner.selected_element]
				owner.add_undo(element.setPivot, element.getPivot, element.pivot_point, "value", element)
				initialElementPos = element.to_local(initialMousePos) + element.pivot_point
		
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var layerlist = owner.LayerList.duplicate()
			var old_selected_element = owner.selected_element
			owner.selected_element = -1
			#layerlist.reverse()
			if old_selected_element != -1:
				var alreadySelectedElement = owner.LayerList[owner.selected_layer][old_selected_element]
				
				var alreadypoints = [alreadySelectedElement.transformTopLeft.global_position,
									alreadySelectedElement.transformTopRight.global_position,
									alreadySelectedElement.transformBottomRight.global_position,
									alreadySelectedElement.transformBottomLeft.global_position]
				if is_point_inside_polygon(alreadypoints):
					owner.selected_element = alreadySelectedElement.id
					owner.selected_layer = alreadySelectedElement.layer
					if owner.selected_element == old_selected_element:
						draggingElement = true
						pos_diff = alreadySelectedElement.position
						initialMousePos = get_global_mouse_position()
						owner.add_undo(alreadySelectedElement.setPosition, alreadySelectedElement.getPosition, alreadySelectedElement.position, "value", alreadySelectedElement)
						initialElementPos = alreadySelectedElement.global_position
				
				else:
					for layer in layerlist:
						var elementlist = layer.duplicate()
						elementlist.reverse()
						for element in elementlist:
							element.transformTopLeft.position = -element.pivot_point
							element.transformBottomLeft.position = -element.pivot_point + Vector2(0,element.element_size[1])
							element.transformBottomRight.position = -element.pivot_point + element.element_size
							element.transformTopRight.position = -element.pivot_point + Vector2(element.element_size[0],0)
							var points =  [element.transformTopLeft.global_position,
										element.transformTopRight.global_position,
										element.transformBottomRight.global_position,
										element.transformBottomLeft.global_position]
							if is_point_inside_polygon(points) and element.is_visible_in_tree() and element.render and not element.hide_editor:
								owner.selected_element = element.id
								owner.selected_layer = element.layer
								if owner.selected_element == old_selected_element:
									draggingElement = true
									pos_diff = element.position
									initialMousePos = get_global_mouse_position()
									owner.add_undo(element.setPosition, element.getPosition, element.position, "value", element)
									initialElementPos = element.global_position
								break
					emit_signal("selected_element")
			else:
				for layer in layerlist:
					var elementlist = layer.duplicate()
					elementlist.reverse()
					for element in elementlist:
						element.transformTopLeft.position = -element.pivot_point
						element.transformBottomLeft.position = -element.pivot_point + Vector2(0,element.element_size[1])
						element.transformBottomRight.position = -element.pivot_point + element.element_size
						element.transformTopRight.position = -element.pivot_point + Vector2(element.element_size[0],0)
						var points =  [element.transformTopLeft.global_position,
									element.transformTopRight.global_position,
									element.transformBottomRight.global_position,
									element.transformBottomLeft.global_position]
						if is_point_inside_polygon(points)  and element.is_visible_in_tree() and element.render and not element.hide_editor:
							owner.selected_element = element.id
							owner.selected_layer = element.layer
							if owner.selected_element == old_selected_element:
								draggingElement = true
								pos_diff = element.position
								initialMousePos = get_global_mouse_position()
								owner.add_undo(element.setPosition, element.getPosition, element.position, "value", element)
								initialElementPos = element.global_position
							break
				emit_signal("selected_element")

func is_point_inside_polygon(points: Array) -> bool:
	var point = get_viewport().get_mouse_position()
	var wn = 0
	
	for i in range(points.size()):
		var edge_start = points[i]
		var edge_end = points[(i + 1) % points.size()]
		
		if edge_start.y <= point.y:
			if edge_end.y > point.y and cross_product(edge_end - edge_start, point - edge_start) > 0:
				wn += 1
		else:
			if edge_end.y <= point.y and cross_product(edge_end - edge_start, point - edge_start) < 0:
				wn -= 1
	
	return wn != 0

func cross_product(v1: Vector2, v2: Vector2) -> float:
	return v1.x * v2.y - v1.y * v2.x

var pos_diff = Vector2(2,2)

var updateKeyPos = false
var changing = false
func checkKeyframeSaving(element, value, track_name):
	if owner.panel_bottom.selected_keyframe != -1 or owner.panel_bottom.multiple_select != []:
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == track_name:
					for keyframe in track["Keyframes"]:
						if int(keyframe["timestamp"]) == int(round(owner.time)):
							if not changing:
								var oldAnim = element.animation_list.duplicate(true)
								owner.undoHistory[-1][3] = "keyframe"
								owner.undoHistory[-1].append(oldAnim)
								owner.undoHistory[-1].append(owner.time)
								#print(oldAnim)
							changing = true
							keyframe["data"] = value
							element.saveDefaults = false
							if track["Keyframes"].find(keyframe)+1 < track["Keyframes"].size():
								owner.panel_bottom.updateKeyframeSettings(keyframe, track["Keyframes"][track["Keyframes"].find(keyframe)+1])
		
func checkKeyframeSavingPos(element, offset):
	var not_skip = false
	offset = element.position - offset
	
	if (owner.panel_bottom.multiple_select == []):
		return 
	if owner.animation_idx < element.animation_list.size():
		for keyframe in owner.panel_bottom.multiple_select:
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "posx":
					
					var selected_kf = track["Keyframes"][owner.panel_bottom.selected_keyframe]
					if selected_kf["timestamp"] != owner.time:
						not_skip = true
					
					if keyframe != track["Keyframes"][owner.panel_bottom.selected_keyframe] and keyframe["mot"] == "posx" or not_skip:
						keyframe["data"] += offset.x / owner.project_settings["screen_size"][0]
				
				elif track["Motion"] == "posy":
					
					var selected_kf = track["Keyframes"][owner.panel_bottom.selected_keyframe]
					if selected_kf["timestamp"] != owner.time:
						not_skip = true
					
					if keyframe != track["Keyframes"][owner.panel_bottom.selected_keyframe] and keyframe["mot"] == "posy" or not_skip:
						keyframe["data"] += offset.y / owner.project_settings["screen_size"][1]
	
var locktogrid = false

func _on_lock_to_grid_toggled(button_pressed):
	self.grab_focus()
	locktogrid = button_pressed
	if button_pressed:
		$LockToGrid.modulate = Color(0.5,0.5,1)
	else:
		$LockToGrid.modulate = Color(1,1,1)


func _on_maximize_view_pressed():
	fillZoom()


