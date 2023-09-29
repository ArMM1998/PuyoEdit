extends Panel


# Called when the node enters the scene tree for the first time.
func _ready():
	$keyframeSettings/MenuButton.get_popup().add_item("None")
	$keyframeSettings/MenuButton.get_popup().add_item("Linear")
	$keyframeSettings/MenuButton.get_popup().add_item("Ease In / Out")
	
	$keyframeSettings/MenuButton.get_popup().id_pressed.connect(changeTweening)
	
	$timeline/background/ColorRect.gui_input.connect(headInput)
	$timeline/background.gui_input.connect(timelineInput)
	limitLine = Line2D.new()
	
	limitLine.default_color = Color(0,0,0,0.2)
	$timeline/line.add_child(limitLine)
	pass # Replace with function body.


#var movingKeyframe = false
var current_element
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_element != [owner.selected_layer, owner.selected_element]:
		selected_keyframe = -1
		selected_track = -1
		multiple_select = []
	
	$ColorRect.visible = owner.selected_element == -1
	
	current_element = [owner.selected_layer, owner.selected_element]
	$keyframeSettings.visible = selected_keyframe != -1 and selected_track != -1
	
	$timeline/focus.visible = $timeline.has_focus()
	
	if owner.selected_element == -1:
		multiple_select = []
	
	
	update()
	doubletimer += delta
	if doubletimer > 0.5:
		doubletimer = 0
		doubleclick = 0
	

var trackID = {"hide" : 0,
			"posx" : 1,
			"posy" : 2,
			"angle" : 3,
			"scalex" : 4,
			"scaley" : 5,
			"sprite_index" : 6,
			"rgba" : 7,
			"rgba_tl" : 8,
			"rgba_bl" : 9,
			"rgba_tr" : 10,
			"rgba_br" : 11}

var trackName = {0	: "hide",
				1	: "posx",
				2	: "posy",
				3	: "angle",
				4	: "scalex",
				5	: "scaley",
				6	: "sprite_index",
				7	: "rgba",
				8	: "rgba_tl",
				9	: "rgba_bl",
				10	: "rgba_tr",
				11	: "rgba_br"}


var zoomLevel = 1.0
var mult = 1.0

var limitLine

var selected_track = -1
var selected_keyframe = -1


func setTimeLabels():
	
	var num_of_labels = ($timeline/background/ColorRect2.size.x / (5*16) + 1)
	
	for child in $timeline/labels.get_children():
		child.queue_free()
	
	for i in range(int(num_of_labels + 1)):
		var timelabel = Label.new()
		#bad here, it gets fucked if the zoom level is different than 1......
		#timelabel.text = str((i * (5.0/zoomLevel)) + int($HScrollBar.value)/5 * (5))
		
		timelabel.text = str(i * (5/zoomLevel) - int($timeline/line.position.x/80) * (5/zoomLevel))
		
		timelabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timelabel.label_settings = LabelSettings.new()
		timelabel.label_settings.font_size = 8
		#timelabel.add_theme_font_size_override(, 11)
		timelabel.size = Vector2(64,16)
		timelabel.position = Vector2(i* (5*16) - 24, 0)
		
		$timeline/labels.add_child(timelabel)
var holdingCtrl = false
var holdingShift = false

var keyframeClipboard = []

func _input(event):
	
	if event is InputEventKey and event.keycode == KEY_CTRL:
		holdingCtrl = event.pressed
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		holdingShift = event.pressed
	
	if event is InputEventMouseButton and not event.pressed:
		holding_ease = 0
	
	if event is InputEventKey and $timeline.has_focus():
		if event.keycode == KEY_DELETE and event.pressed:
			if (selected_keyframe != -1 and selected_track != -1) or multiple_select != []:
				deleteKeyframe()
		if event.keycode == KEY_C and event.pressed and holdingCtrl:
			if multiple_select != []:
				keyframeClipboard = []
				var element = owner.LayerList[owner.selected_layer][owner.selected_element]
				for CBkeyframe in multiple_select.duplicate(true):
					for track in element.animation_list[owner.animation_idx]:
						for keyframe in track["Keyframes"]:
							if keyframe == CBkeyframe:
								CBkeyframe["track"] = track["Motion"]
								keyframeClipboard.append(CBkeyframe)
				DisplayServer.clipboard_set(JSON.stringify(keyframeClipboard))
			elif selected_keyframe != -1:
				var element = owner.LayerList[owner.selected_layer][owner.selected_element]
				for track in element.animation_list[owner.animation_idx]:
					if track["Motion"] == trackName[selected_track]:
						var keyframe_to_copy = track["Keyframes"][selected_keyframe].duplicate(true)
						keyframe_to_copy["track"] = track["Motion"]
						keyframeClipboard = [keyframe_to_copy]
				DisplayServer.clipboard_set(JSON.stringify(keyframeClipboard))
		if event.keycode == KEY_V and event.pressed and holdingCtrl:
			keyframeClipboard = JSON.parse_string(DisplayServer.clipboard_get())
			#print(keyframeClipboard)
			if keyframeClipboard:
				var element = owner.LayerList[owner.selected_layer][owner.selected_element]
				owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
				owner.undoHistory[-1].append(element.animation_list.duplicate(true))
				owner.undoHistory[-1].append(owner.time)
				
				for copied_keyframe in keyframeClipboard:
					var has_track = false
					for track in element.animation_list[owner.animation_idx]:
						if track["Motion"] == copied_keyframe["track"]:
							has_track = true
					if not has_track:
						element.animation_list[owner.animation_idx].append({"Motion": copied_keyframe["track"],"Loop": 0,"Keyframes" : []})
				
				var lowest_timestamp = 999999999
				for copied_keyframe in keyframeClipboard:
					if copied_keyframe["timestamp"] < lowest_timestamp:
						lowest_timestamp = copied_keyframe["timestamp"]
				
				for track in element.animation_list[owner.animation_idx]:
					for copied_keyframe in keyframeClipboard:
						if track["Motion"] == copied_keyframe["track"]:
							var keyframe_to_paste = copied_keyframe.duplicate(true)
							keyframe_to_paste.erase("track")
							if holdingShift:
								keyframe_to_paste["timestamp"] += -lowest_timestamp + round(owner.time)
							track["Keyframes"].append(keyframe_to_paste)
					track["Keyframes"] = sortArrayByTimestamp(track["Keyframes"])
			selected_element = []
		
		if event.keycode == KEY_LEFT and event.pressed:
			for keyframe in multiple_select:
				keyframe["timestamp"]-= 1
			
			if selected_keyframe != -1:
				var element = owner.LayerList[owner.selected_layer][owner.selected_element]
				for track in element.animation_list[owner.animation_idx]:
					if track["Motion"] == trackName[selected_track]:
						track["Keyframes"][selected_keyframe]["timestamp"] -= 1
			
			$timeline.grab_focus()
			selected_element = []
		
		elif event.keycode == KEY_RIGHT and event.pressed:
			for keyframe in multiple_select:
				keyframe["timestamp"]+= 1
			
			if selected_keyframe != -1:
				var element = owner.LayerList[owner.selected_layer][owner.selected_element]
				for track in element.animation_list[owner.animation_idx]:
					if track["Motion"] == trackName[selected_track]:
						track["Keyframes"][selected_keyframe]["timestamp"] += 1
			
			$timeline.grab_focus()
			selected_element = []

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			selected_element = []
			mult -=1
			if mult < 1:
				mult = 1
			_on_h_scroll_bar_scrolling()
			if $timeline/Head.global_position.x > self.size.x - 384 or $timeline/Head.global_position.x < 256:
				#print("off screen")
				$HScrollBar.value = $frameTime.value - 16
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			selected_element = []
			mult += 1
			if mult > 30:
				mult = 30
			_on_h_scroll_bar_scrolling()
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			$HScrollBar.value -= (0.2)/zoomLevel
		elif event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			$HScrollBar.value += (0.2)/zoomLevel
var selected_element 

func update():
	zoomLevel = (1.0/mult)
	
	var scroll_max = owner.animation_max_time + 100
	
	setTimeLabels()
	_on_h_scroll_bar_scrolling()
	$cosmeticShit/highlight.position = Vector2(128+8, (selected_track*16) + 56)
	if selected_track == -1:
		$cosmeticShit/highlight.visible = false
	else:
		$cosmeticShit/highlight.visible = true
	
	limitLine.points = [(Vector2(owner.animation_max_time * (16 * zoomLevel) + 8 , 0)), (Vector2(owner.animation_max_time * (16 * zoomLevel) + 8 , 224))]
	
	button_colors()
	
	if selected_element != [owner.selected_layer, owner.selected_element]:
		
		updateAnimList()
		
		selected_element = [owner.selected_layer, owner.selected_element]
		for child in $timeline/keyframes.get_children():
			child.queue_free()
	
		for child in $timeline/line.get_children():
			if not child == limitLine:
				child.queue_free()
		if owner.selected_element != -1:
			var current_track = 0
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			#print(element)
			$loop_visib.button_pressed = false
			$loop_posx.button_pressed = false
			$loop_posy.button_pressed = false
			$loop_angle.button_pressed = false
			$loop_scalex.button_pressed = false
			$loop_scaley.button_pressed = false
			$loop_sprite.button_pressed = false
			$loop_color.button_pressed = false
			$loop_color_tl.button_pressed = false
			$loop_color_bl.button_pressed = false
			$loop_color_tr.button_pressed = false
			$loop_color_br.button_pressed = false
			
			if owner.animation_idx < element.animation_list.size():
				for track in element.animation_list[owner.animation_idx]:
					
					if track["Loop"] == 2:
						checkTrackLoop(track)
					
					current_track = trackID[track["Motion"]]
						
					var line_starting_pos = 0
					var line_end_pos = 0
					if track["Keyframes"].size() != 0:
						line_starting_pos = track["Keyframes"][0]["timestamp"] * (16 * zoomLevel)
					
					for keyframe in track["Keyframes"]:
						var keyframeBTN = TextureButton.new()
						var btn_texture
						
						if keyframe["tweening"] == 0:
							btn_texture = load("res://Graphics/timeline/kf_nointerpolation.png")
						
						elif keyframe["tweening"] == 1:
							btn_texture = load("res://Graphics/timeline/kf_linear.png")
						
						elif keyframe["tweening"] == 2:
							btn_texture = load("res://Graphics/timeline/kf_easing.png")
						
						
						keyframeBTN.texture_normal = btn_texture
						
						keyframeBTN.position = Vector2(keyframe["timestamp"] * (16 * zoomLevel), (current_track * 16) + 24)
						
						keyframeBTN.mouse_filter = Control.MOUSE_FILTER_IGNORE
						
						if selected_track == current_track and selected_keyframe == track["Keyframes"].find(keyframe) or keyframe in multiple_select:
							keyframeBTN.modulate = Color(0.5,0.5,1)
							
						
						$timeline/keyframes.add_child(keyframeBTN)
						line_end_pos = keyframe["timestamp"] * (16 * zoomLevel)
						
						if keyframe["timestamp"] + 100 > scroll_max:
							scroll_max = keyframe["timestamp"] + 100
						
					if line_starting_pos != line_end_pos:
						var keyframeline = Line2D.new()
						keyframeline.default_color = Color(0.5,0.5,0.6)
						keyframeline.width = 1
						keyframeline.add_point(Vector2(line_starting_pos + 8,(current_track * 16) + 24+8))
						keyframeline.add_point(Vector2(line_end_pos + 8 ,(current_track * 16) + 24+8))
						$timeline/line.add_child(keyframeline)
			
	$HScrollBar.max_value = scroll_max


func _on_h_scroll_bar_scrolling():
	$timeline/keyframes.position = Vector2(-$HScrollBar.value*(16*zoomLevel),0)
	$timeline/line.position = Vector2(-$HScrollBar.value*(16*zoomLevel),0)
	#$checkbg.position = Vector2(int(str(int($Center/Canvas.global_position[0])).right(2)),int(str(int($Center/Canvas.global_position[1])).right(2))) - Vector2(178,122)
	
	$timeline/background/ColorRect.position = Vector2(int(-$HScrollBar.value*(16*zoomLevel)) % 80,0) - Vector2(80,0)
	$timeline/labels.position = Vector2(int(-$HScrollBar.value*(16*zoomLevel)) % 80,0)


func _on_h_scroll_bar_value_changed(_value):
	_on_h_scroll_bar_scrolling()

var holdingHead = false
var starting_pos 

func headInput(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		$timeline.grab_focus()
		owner.playing = false
		holdingHead = event.pressed
		starting_pos = get_global_mouse_position()
		owner.centerHead = false
	
	if holdingHead:
		owner.time =  ((get_global_mouse_position().x - 270) - ($timeline/keyframes.position.x))/(16*zoomLevel)
		if owner.time > owner.animation_max_time:
			owner.time = owner.animation_max_time
		elif owner.time < 0:
			owner.time = 0.0
		
		$timeline/Head.position = Vector2( owner.time, 0)
		for layer in owner.LayerList:
			for element in layer:
				element.animate(owner.time, owner.animation_idx, owner.project_settings["screen_size"])
		owner.panel_right.update()
		owner.centerHead = true
		
#		var timeline_size = ($timeline.size.x + $timeline/background.global_position.x - 256 + $HScrollBar.value)/(16*zoomLevel)
#		print(timeline_size)
#
#		if owner.time > timeline_size:
#			$HScrollBar.value = owner.time
#			get_viewport().warp_mouse(Vector2(((timeline_size+15.9) - $HScrollBar.value)*(16/zoomLevel), get_global_mouse_position().y))
##		if $timeline/Head.global_position.x > self.size.x - 272:
##			$HScrollBar.value = owner.time
##			$timeline/Head.position = Vector2(owner.time, 0)
##			get_viewport().warp_mouse(Vector2($timeline/Head.global_position.x, get_global_mouse_position().y))
##		elif $timeline/Head.global_position.x < 256:
##			$HScrollBar.value = owner.time - (self.size.x - 272)/(16*zoomLevel)
##			$timeline/Head.position = Vector2(owner.time, 0)
##			get_viewport().warp_mouse(Vector2($timeline/Head.global_position.x, get_global_mouse_position().y))
		
var mousepos = Vector2(0,0)
var doubleclick = 0
var doubletimer = 0
var holdingKeyframe = false
var initialTimestamp = -1
var drawingSelectSquare = false

var select_square_points = [Vector2(0,0), Vector2(0,0)]

var multiple_select = []
var multiple_selectInitial = []

var keyframe_dif = 0
var initial_value = 0

func timelineInput(event):
	if event is InputEventMouseButton and not event.pressed:
		holdingKeyframe = false
		drawingSelectSquare = false
		$timeline/ReferenceRect.visible = false
		initialTimestamp = -1
		multiple_selectInitial = []
		if owner.selected_layer != -1 and owner.selected_element != -1 and owner.animationList.size() > 0:
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			for anim_track in element.animation_list[owner.animation_idx]:
				sortArrayByTimestamp(anim_track["Keyframes"])
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		$timeline.grab_focus()
		owner.time = round(($timeline/keyframes.to_local(get_global_mouse_position()).x-7) / (16*zoomLevel))
		owner.time = snapped(owner.time, 1/(zoomLevel))
		selected_track = int(round(($timeline/keyframes.to_local(get_global_mouse_position()).y-32) / 16))
		if selected_track < 0:
			selected_track = 0
		selected_keyframe = -1
		
		for layer in owner.LayerList:
			for element in layer:
				element.animate(owner.time, owner.animation_idx, owner.project_settings["screen_size"])
			
		owner.panel_right.update()
		if owner.selected_layer != -1 and owner.selected_element != -1:
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			if owner.animation_idx < owner.LayerList[owner.selected_layer][owner.selected_element].animation_list.size():
				for anim_track in element.animation_list[owner.animation_idx]:
					var track_name = trackName[selected_track]
					if anim_track["Motion"] == track_name:
						var keyIDX = 0
						for keyframe in anim_track["Keyframes"]:
							
							var in_button_range = int(owner.time) in range(int(keyframe["timestamp"] - (0.5)/zoomLevel), int(keyframe["timestamp"] + (0.5)/zoomLevel))
							#print(int(owner.time), ": - : ", int(owner.time - (0.5)/zoomLevel), ",", int(owner.time + (0.5)*zoomLevel))
							if keyframe["timestamp"] == owner.time or in_button_range:
								owner.time = float(keyframe["timestamp"])
								selected_keyframe = keyIDX
								holdingKeyframe = true
								
								owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
								owner.undoHistory[-1].append(element.animation_list.duplicate(true))
								owner.undoHistory[-1].append(owner.time)
								
								initial_mouse_pos = get_global_mouse_position()
								prev_tweening = keyframe["tweening"]
								if keyIDX < anim_track["Keyframes"].size() -1:
									updateKeyframeSettings(keyframe, anim_track["Keyframes"][keyIDX+1])
								else:
									updateKeyframeSettings(keyframe, keyframe)
								for layer in owner.LayerList:
									for elem in layer:
										elem.animate(owner.time, owner.animation_idx, owner.project_settings["screen_size"], true)
										owner.panel_right.update()
								
								if keyframe not in multiple_select:
									multiple_select = []
								break
								
							keyIDX+= 1
			if selected_keyframe == -1:
				multiple_select = []
		
		if selected_keyframe == -1 and owner.selected_layer != -1 and owner.selected_element != -1 and owner.animation_idx  != -1:
			if owner.animation_idx < owner.animationList.size():
				drawingSelectSquare = true
				select_square_points[0] = get_global_mouse_position() - $timeline.global_position
		
		if abs((mousepos - get_global_mouse_position()).x) < 4 and abs((mousepos - get_global_mouse_position()).y) < 4:
			doubleclick += 1
			
			if doubleclick == 2:
				addKeyframe()
				doubleclick = 0
				mousepos = Vector2(6969,6969)
			
		else:
			doubleclick = 1
			mousepos = Vector2(6969,6969)
			mousepos = get_global_mouse_position()
		selected_element = []
	elif event is InputEventMouseMotion:
		if not get_global_mouse_position().x in range(mousepos.x-2, mousepos.x+2) and  get_global_mouse_position().y in range(mousepos.y-2, mousepos.y+2) :
			doubleclick = 0
			mousepos = Vector2(6969,6969)
		
		if holdingKeyframe:
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			var track_name = trackName[selected_track]
			for anim_track in element.animation_list[owner.animation_idx]:
				if anim_track["Motion"] == track_name:
					if initialTimestamp == -1:
						initialTimestamp = anim_track["Keyframes"][selected_keyframe]["timestamp"]
					if multiple_selectInitial == []:
						for keyframe in multiple_select:
							multiple_selectInitial.append(round(keyframe["timestamp"]))
					
					initial_value = anim_track["Keyframes"][selected_keyframe]["timestamp"]
					initialTimestamp += (get_global_mouse_position().x - initial_mouse_pos.x)/(16*zoomLevel)
					anim_track["Keyframes"][selected_keyframe]["timestamp"] = float(round(int(snapped(initialTimestamp, 1/zoomLevel))))
					owner.time = float(round(int(snapped(initialTimestamp, 1/zoomLevel))))
					
					keyframe_dif = anim_track["Keyframes"][selected_keyframe]["timestamp"] - initial_value
					
					#print(anim_track["Keyframes"][selected_keyframe]["timestamp"])
					
					for keyframe in multiple_select:
						if keyframe != anim_track["Keyframes"][selected_keyframe]:
							#multiple_selectInitial[keyIDX] += (get_global_mouse_position().x - initial_mouse_pos.x)/(16*zoomLevel)
							keyframe["timestamp"] += keyframe_dif
						
					initial_mouse_pos = get_global_mouse_position()
					selected_element = []
					break
		
		elif drawingSelectSquare:
			select_square_points[1] = get_global_mouse_position() - $timeline.global_position
			$timeline/ReferenceRect.visible = true
			
			if select_square_points[0].x < select_square_points[1].x:
				$timeline/ReferenceRect.position.x = select_square_points[0].x
				$timeline/ReferenceRect.size.x = select_square_points[1].x - select_square_points[0].x
			else:
				$timeline/ReferenceRect.position.x = select_square_points[1].x
				$timeline/ReferenceRect.size.x = select_square_points[0].x - select_square_points[1].x
			
			if select_square_points[0].y < select_square_points[1].y:
				$timeline/ReferenceRect.position.y = select_square_points[0].y
				$timeline/ReferenceRect.size.y = select_square_points[1].y - select_square_points[0].y
			else:
				$timeline/ReferenceRect.position.y = select_square_points[1].y
				$timeline/ReferenceRect.size.y = select_square_points[0].y - select_square_points[1].y
				
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			if owner.animation_idx < owner.LayerList[owner.selected_layer][owner.selected_element].animation_list.size():
				multiple_select = []
				for anim_track in element.animation_list[owner.animation_idx]:
					var track_idx = trackID[anim_track["Motion"]]
					for keyframe in anim_track["Keyframes"]:
						var keyframe_time = keyframe["timestamp"]
						
						#print(track_idx, " - ", keyframe_time)
						
						if (track_idx < (select_square_points[1].y - 24)/16 and track_idx > (select_square_points[0].y-24)/16) or (track_idx > (select_square_points[1].y-24)/16 and track_idx < (select_square_points[0].y-24)/16):
							#print((select_square_points[1].x-8) / (16*zoomLevel))
							
							if (keyframe_time < (select_square_points[0].x-8-$timeline/keyframes.position.x) / (16*zoomLevel) and keyframe_time > (select_square_points[1].x-8-$timeline/keyframes.position.x) / (16*zoomLevel)) or (keyframe_time > (select_square_points[0].x-8-$timeline/keyframes.position.x) / (16*zoomLevel) and keyframe_time < (select_square_points[1].x-8-$timeline/keyframes.position.x) / (16*zoomLevel)):
								multiple_select.append(keyframe)
								keyframe["mot"] = anim_track["Motion"]
								#print(keyframe, anim_track["Motion"])
								#print(anim_track["Motion"])
				selected_element = []


func addKeyframe():
	if owner.selected_element != -1:
		if owner.animation_idx < owner.LayerList[owner.selected_layer][owner.selected_element].animation_list.size():
			var element = owner.LayerList[owner.selected_layer][owner.selected_element]
			owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
			owner.undoHistory[-1].append(element.animation_list.duplicate(true))
			owner.undoHistory[-1].append(owner.time)
			var frame = round(($timeline/keyframes.to_local(get_global_mouse_position()).x-8) / (16*zoomLevel))
			frame = int(snapped(frame, 1/zoomLevel))
			
			var track_name = trackName[int(round(($timeline/keyframes.to_local(get_global_mouse_position()).y-32) / 16))]
			
			var track_idx = 0
			for anim_track in element.animation_list[owner.animation_idx]:
				if anim_track["Motion"] == track_name:
					break
				track_idx+= 1
			
			var data = 0
			
			if track_name == "hide":
				data = int(not element.visibility)
				prev_tweening = 0
				
			if track_name == "posx":
				data = element.positionX / owner.project_settings["screen_size"][0]
			
			if track_name == "posy":
				data = element.positionY / owner.project_settings["screen_size"][1]
			
			if track_name == "angle":
				data = -element.angle
				
			if track_name == "scalex":
				data = element.scalex
			
			if track_name == "scaley":
				data = element.scaley
			
			if track_name == "sprite_index":
				data = element.sprite_index
				prev_tweening = 0
				
			if track_name == "rgba":
				data = {"red": element.color.r8,
						"green": element.color.g8,
						"blue": element.color.b8,
						"alpha": element.color.a8}
				if prev_tweening == 2:
					prev_tweening = 1
			
			if track_name == "rgba_tl":
				data = {"red": element.color_tl.r8,
						"green": element.color_tl.g8,
						"blue": element.color_tl.b8,
						"alpha": element.color_tl.a8}
				if prev_tweening == 2:
					prev_tweening = 1
			
			if track_name == "rgba_bl":
				data = {"red": element.color_bl.r8,
						"green": element.color_bl.g8,
						"blue": element.color_bl.b8,
						"alpha": element.color_bl.a8}
				if prev_tweening == 2:
					prev_tweening = 1
			
			if track_name == "rgba_tr":
				data = {"red": element.color_tr.r8,
						"green": element.color_tr.g8,
						"blue": element.color_tr.b8,
						"alpha": element.color_tr.a8}
				if prev_tweening == 2:
					prev_tweening = 1
			
			if track_name == "rgba_br":
				data = {"red": element.color_br.r8,
						"green": element.color_br.g8,
						"blue": element.color_br.b8,
						"alpha": element.color_br.a8}
				if prev_tweening == 2:
					prev_tweening = 1
			
			
			if track_idx > element.animation_list[owner.animation_idx].size()-1:
				element.animation_list[owner.animation_idx].append({
										"Motion": track_name,
										"Loop" : 0,
										"Keyframes" : []
									})
			
			var replaced = false
			
			for keyframe in element.animation_list[owner.animation_idx][track_idx]["Keyframes"]:
				if keyframe["timestamp"] == frame:
					keyframe = {
										"timestamp": frame,
										"data": data,
										"tweening": prev_tweening,
										"ease_in": 0,
										"ease_out": 0,
										"unk": 0
									}
					replaced = true
					break
			if not replaced:
				element.animation_list[owner.animation_idx][track_idx]["Keyframes"].append({
										"timestamp": frame,
										"data": data,
										"tweening": prev_tweening,
										"ease_in": 0,
										"ease_out": 0,
										"unk": 0
									})
				
			element.animation_list[owner.animation_idx][track_idx]["Keyframes"] = sortArrayByTimestamp(element.animation_list[owner.animation_idx][track_idx]["Keyframes"])
				
			selected_element = []
		else:
			pass
			#print("????")
			
func _on_play_pause_pressed():
	owner.playing = not owner.playing

func _on_stop_pressed():
	owner.playing = false
	owner.time = 0.0
	$HScrollBar.value = 0
	for layer in owner.LayerList:
		for element in layer:
			element.animate(owner.time, owner.animation_idx, owner.project_settings["screen_size"])

func sortArrayByTimestamp(array):
	
	for i in range(array.size() - 1):
		for j in range(array.size() - i - 1):
			if array[j]["timestamp"] > array[j + 1]["timestamp"]:
				var temp = array[j]
				array[j] = array[j + 1]
				array[j + 1] = temp
	
	var result = [array[0]]
	
	for i in range(1, len(array)):
		if array[i]["timestamp"] != result[-1]["timestamp"]:
			result.append(array[i])
	
	return result

func updateKeyframeSettings(kf, next_kf):
	if kf["tweening"] != 2:
		$keyframeSettings/curvePanel.visible = false
		if kf["tweening"] == 0:
			$keyframeSettings/tweening_btn.text = "None"
		else:
			$keyframeSettings/tweening_btn.text = "Linear"
		
	else:
		$keyframeSettings/curvePanel.visible = true
		$keyframeSettings/tweening_btn.text = "Ease in / Out"
		$keyframeSettings/curvePanel/curve/Line2D.clear_points()
		var point_mult = 5
		var amount_of_points = (float(next_kf["timestamp"]) - float(kf["timestamp"])) * point_mult
		#print(amount_of_points)
		for i in range(amount_of_points):
			
			
			var y = (owner.smoothCurve(float(i)/ point_mult + float(kf["timestamp"]), kf, next_kf))
			
			y = (y - kf["data"]) / (next_kf["data"] - kf["data"])
			
			var x = i* (128/amount_of_points)
			$keyframeSettings/curvePanel/curve/Line2D.add_point(Vector2(x,y* 108))
		
		
		#BAD
		
		if kf["ease_in"] != 0 or kf["ease_out"] != 0:
		
			var easein_y = (kf["ease_in"]/abs(kf["data"] - next_kf["data"])) * (abs(kf["timestamp"] - next_kf["timestamp"])*4)
			var easeout_y = -(kf["ease_out"]/abs(kf["data"] - next_kf["data"])) * (abs(kf["timestamp"] - next_kf["timestamp"])*4)
			
			if kf["data"] < next_kf["data"]:
				$keyframeSettings/curvePanel/curve/ease_in_btn.position = Vector2(-16,easein_y)
				$keyframeSettings/curvePanel/curve/ease_out_btn.position = Vector2(142, easeout_y + 108)
			
			elif kf["data"] == next_kf["data"]:
				$keyframeSettings/curvePanel/curve/ease_in_btn.position = Vector2(-16,0)
				$keyframeSettings/curvePanel/curve/ease_out_btn.position = Vector2(142,108)
			else:
				$keyframeSettings/curvePanel/curve/ease_in_btn.position = Vector2(-16,-easein_y)
				$keyframeSettings/curvePanel/curve/ease_out_btn.position = Vector2(142, -easeout_y + 108)
		else:
			$keyframeSettings/curvePanel/curve/ease_in_btn.position = Vector2(-16,0)
			$keyframeSettings/curvePanel/curve/ease_out_btn.position = Vector2(142,108)
	$keyframeSettings/curvePanel/curve/Line2D.add_point(Vector2(128,108))


func _on_dropdown_pressed():
	$keyframeSettings/MenuButton.show_popup()
	pass # Replace with function body.

var prev_tweening = 1

func changeTweening(id_pressed):
	if selected_track != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
		owner.undoHistory[-1].append(element.animation_list.duplicate(true))
		owner.undoHistory[-1].append(owner.time)
		for track in element.animation_list[owner.animation_idx]:
			if track["Motion"] == trackName[selected_track]:
				track["Keyframes"][selected_keyframe]["tweening"] = id_pressed
				prev_tweening = id_pressed
				if selected_keyframe +1 < track["Keyframes"].size():
					updateKeyframeSettings(track["Keyframes"][selected_keyframe], track["Keyframes"][selected_keyframe+1])
				selected_element = []
		for keyframe in multiple_select:
			#print(keyframe, "what")
			keyframe["tweening"] = id_pressed
			selected_element = []
		
		for track in element.animation_list[owner.animation_idx]:
			if track["Motion"] == "hide" or track["Motion"] == "sprite_index":
				for keyframe in track["Keyframes"]:
					keyframe["tweening"] = 0
			elif track["Motion"].find("rgba") != -1:
				for keyframe in track["Keyframes"]:
					if keyframe["tweening"] == 2:
						keyframe["tweening"] = 1

func updateAnimList():
	$AnimationList.clear()
	$LineEdit.clear()
	for animation in owner.animationList:
		$AnimationList.add_item(animation["name"])
		
	if owner.animation_idx < owner.animationList.size():
		$AnimationList.select(owner.animation_idx)
		$lengthBox.value = owner.animationList[owner.animation_idx]["length"]
		$LineEdit.text = owner.animationList[owner.animation_idx]["name"]

func _on_animation_list_item_clicked(index, _at_position, mouse_button_index):
	if mouse_button_index == 1:
		owner.animation_idx = index
		owner.time = 0
		selected_element = []
		updateAnimList()

func _on_line_edit_text_submitted(new_text):
	if owner.animation_idx < owner.animationList.size():
		owner.animationList[owner.animation_idx]["name"] = new_text
		updateAnimList()
	else:
		$LineEdit.clear()


func _on_length_box_value_changed(value):
	if owner.animation_idx < owner.animationList.size():
		owner.animationList[owner.animation_idx]["length"] = value
		owner.animation_max_time = value
	else:
		$lengthBox.value = 0

func deleteKeyframe():
	var element = owner.LayerList[owner.selected_layer][owner.selected_element]
	if multiple_select == []:
		var track_name = trackName[int(selected_track)]
		for track in element.animation_list[owner.animation_idx]:
			if track["Motion"] == track_name:
				owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
				owner.undoHistory[-1].append(element.animation_list.duplicate(true))
				owner.undoHistory[-1].append(owner.time)
				track["Keyframes"].remove_at(selected_keyframe)
				selected_element = []
				selected_keyframe = -1
				if track["Keyframes"].size() == 0:
					element.animation_list[owner.animation_idx].remove_at(element.animation_list[owner.animation_idx].find(track))
	else:
		owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
		owner.undoHistory[-1].append(element.animation_list.duplicate(true))
		owner.undoHistory[-1].append(owner.time)
		for track in element.animation_list[owner.animation_idx]:
			var newKeyframeList = []
			for keyframe in track["Keyframes"]:
				if keyframe not in multiple_select:
					newKeyframeList.append(keyframe)
					selected_keyframe = -1
				
			track["Keyframes"] = newKeyframeList
		
		var newTrackList = []
		for track in element.animation_list[owner.animation_idx]:
			if track["Keyframes"].size() != 0:
				newTrackList.append(track)
		element.animation_list[owner.animation_idx] = newTrackList
			
		selected_element = []
	owner.updateElementsettings()
var holding_ease = 0

var initial_mouse_pos = Vector2(0,0)

func _on_ease_in_btn_pressed():
	pass


func _on_ease_out_btn_pressed():
	pass


var changing = false

func _on_ease_in_btn_gui_input(event):
	
	var keyframe
	var next_kf
	
	var element = owner.LayerList[owner.selected_layer][owner.selected_element]
	var track_name = trackName[int(selected_track)]
	for track in element.animation_list[owner.animation_idx]:
		if track["Motion"] == track_name:
			keyframe = track["Keyframes"][selected_keyframe]
			if selected_keyframe+1 < track["Keyframes"].size():
				next_kf = track["Keyframes"][selected_keyframe+1]
			else:
				next_kf = keyframe
			
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		holding_ease = 1
		initial_mouse_pos = get_global_mouse_position()
	
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
		owner.undoHistory[-1].append(element.animation_list.duplicate(true))
		owner.undoHistory[-1].append(owner.time)
		keyframe["ease_in"] = 0
		updateKeyframeSettings(keyframe, next_kf)
	
	
	if holding_ease == 1:
		if not changing:
			owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
			owner.undoHistory[-1].append(element.animation_list.duplicate(true))
			owner.undoHistory[-1].append(owner.time)
		changing = true
		#print((initial_mouse_pos.y - get_global_mouse_position().y)*abs(keyframe["data"] - next_kf["data"]))
		
		if next_kf["data"] > keyframe["data"]:
			keyframe["ease_in"] -= (initial_mouse_pos.y - get_global_mouse_position().y) * (abs(keyframe["data"] - next_kf["data"])/(abs(keyframe["timestamp"] - next_kf["timestamp"]*4)))
		else:
			keyframe["ease_in"] += (initial_mouse_pos.y - get_global_mouse_position().y) * (abs(keyframe["data"] - next_kf["data"])/(abs(keyframe["timestamp"] - next_kf["timestamp"]*4)))
		updateKeyframeSettings(keyframe, next_kf)
		#(-(keyframe["ease_out"]/abs(keyframe["data"] - next_kf["data"]))*72) + 108
		
		initial_mouse_pos = get_global_mouse_position()
		
		element.animate(owner.time, owner.animation_idx, owner.project_settings["screen_size"])
		
func _on_ease_out_btn_gui_input(event):
	
	var keyframe
	var next_kf
	
	var element = owner.LayerList[owner.selected_layer][owner.selected_element]
	var track_name = trackName[int(selected_track)]
	for track in element.animation_list[owner.animation_idx]:
		if track["Motion"] == track_name:
			keyframe = track["Keyframes"][selected_keyframe]
			if selected_keyframe+1 < track["Keyframes"].size():
				next_kf = track["Keyframes"][selected_keyframe+1]
			else:
				next_kf = keyframe
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		holding_ease = 2
		initial_mouse_pos = get_global_mouse_position()
	
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
		owner.undoHistory[-1].append(element.animation_list.duplicate(true))
		owner.undoHistory[-1].append(owner.time)
		keyframe["ease_out"] = 0
		updateKeyframeSettings(keyframe, next_kf)
	if holding_ease == 2:
		if not changing:
			owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
			owner.undoHistory[-1].append(element.animation_list.duplicate(true))
			owner.undoHistory[-1].append(owner.time)
		changing = true
		#print(abs(keyframe["data"] - next_kf["data"]))
		if next_kf["data"] > keyframe["data"]:
			keyframe["ease_out"] += (initial_mouse_pos.y - get_global_mouse_position().y) * (abs(keyframe["data"] - next_kf["data"])/(abs(keyframe["timestamp"] - next_kf["timestamp"]*4)))
		else:
			keyframe["ease_out"] -= (initial_mouse_pos.y - get_global_mouse_position().y) * (abs(keyframe["data"] - next_kf["data"])/(abs(keyframe["timestamp"] - next_kf["timestamp"]*4)))
		updateKeyframeSettings(keyframe, next_kf)
		
		initial_mouse_pos = get_global_mouse_position()
		element.animate(owner.time, owner.animation_idx, owner.project_settings["screen_size"])

func button_colors():
	if $loop_visib.button_pressed:
		$loop_visib.modulate = Color(0.5,0.5,1,1)
	else:
		$loop_visib.modulate = Color(1,1,1,1)
	
	if $loop_posx.button_pressed:
		$loop_posx.modulate = Color(0.5,0.5,1,1)
	else:
		$loop_posx.modulate = Color(1,1,1,1)
	
	if $loop_posy.button_pressed:
		$loop_posy.modulate = Color(0.5,0.5,1,1)
	else:
		$loop_posy.modulate = Color(1,1,1,1)
	
	if $loop_angle.button_pressed:
		$loop_angle.modulate = Color(0.5,0.5,1,1)
	else:
		$loop_angle.modulate = Color(1,1,1,1)
	
	if $loop_scalex.button_pressed:
		$loop_scalex.modulate = Color(0.5,0.5,1,1)
	else:
		$loop_scalex.modulate = Color(1,1,1,1)
	
	if $loop_scaley.button_pressed:
		$loop_scaley.modulate = Color(0.5,0.5,1,1)
	else:
		$loop_scaley.modulate = Color(1,1,1,1)
	
	if $loop_sprite.button_pressed:
		$loop_sprite.modulate = Color(0.5,0.5,1,1)
	else:
		$loop_sprite.modulate = Color(1,1,1,1)
	
	if $loop_color.button_pressed:
		$loop_color.modulate = Color(0.5,0.5,1,1)
	else:
		$loop_color.modulate = Color(1,1,1,1)
	
	if $loop_color_tl.button_pressed:
		$loop_color_tl.modulate = Color(0.5,0.5,1,1)
	else:
		$loop_color_tl.modulate = Color(1,1,1,1)
	
	if $loop_color_bl.button_pressed:
		$loop_color_bl.modulate = Color(0.5,0.5,1,1)
	else:
		$loop_color_bl.modulate = Color(1,1,1,1)
	
	if $loop_color_tr.button_pressed:
		$loop_color_tr.modulate = Color(0.5,0.5,1,1)
	else:
		$loop_color_tr.modulate = Color(1,1,1,1)
	
	if $loop_color_br.button_pressed:
		$loop_color_br.modulate = Color(0.5,0.5,1,1)
	else:
		$loop_color_br.modulate = Color(1,1,1,1)

func checkTrackLoop(track):
	if track["Motion"] == "hide":
		$loop_visib.button_pressed = true
	if track["Motion"] == "posx":
		$loop_posx.button_pressed = true
	if track["Motion"] == "posy":
		$loop_posy.button_pressed = true
	if track["Motion"] == "angle":
		$loop_angle.button_pressed = true
	if track["Motion"] == "scalex":
		$loop_scalex.button_pressed = true
	if track["Motion"] == "scaley":
		$loop_scaley.button_pressed = true
	if track["Motion"] == "sprite_index":
		$loop_sprite.button_pressed = true
	if track["Motion"] == "rgba":
		$loop_color.button_pressed = true
	if track["Motion"] == "rgba_tl":
		$loop_color_tl.button_pressed = true
	if track["Motion"] == "rgba_bl":
		$loop_color_bl.button_pressed = true
	if track["Motion"] == "rgba_tr":
		$loop_color_tr.button_pressed = true
	if track["Motion"] == "rgba_br":
		$loop_color_br.button_pressed = true


func _on_loop_visib_pressed():
	$loop_visib.button_pressed = false
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "hide":
					
					owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
					owner.undoHistory[-1].append(element.animation_list.duplicate(true))
					owner.undoHistory[-1].append(owner.time)
					
					if track["Loop"] == 2:
						track["Loop"] = 0
					else:
						track["Loop"] = 2
					selected_element = []
					break


func _on_loop_posx_pressed():
	$loop_posx.button_pressed = false
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "posx":
					
					owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
					owner.undoHistory[-1].append(element.animation_list.duplicate(true))
					owner.undoHistory[-1].append(owner.time)
					if track["Loop"] == 2:
						track["Loop"] = 0
					else:
						track["Loop"] = 2
					selected_element = []
					break


func _on_loop_posy_pressed():
	$loop_posy.button_pressed = false
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "posy":
					
					owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
					owner.undoHistory[-1].append(element.animation_list.duplicate(true))
					owner.undoHistory[-1].append(owner.time)
					
					if track["Loop"] == 2:
						track["Loop"] = 0
					else:
						track["Loop"] = 2
					selected_element = []
					break


func _on_loop_angle_pressed():
	$loop_angle.button_pressed = false
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "angle":
					
					owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
					owner.undoHistory[-1].append(element.animation_list.duplicate(true))
					owner.undoHistory[-1].append(owner.time)
					
					if track["Loop"] == 2:
						track["Loop"] = 0
					else:
						track["Loop"] = 2
					selected_element = []
					break


func _on_loop_scalex_pressed():
	$loop_scalex.button_pressed = false
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "scalex":
					
					owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
					owner.undoHistory[-1].append(element.animation_list.duplicate(true))
					owner.undoHistory[-1].append(owner.time)
					
					if track["Loop"] == 2:
						track["Loop"] = 0
					else:
						track["Loop"] = 2
					selected_element = []
					break


func _on_loop_scaley_pressed():
	$loop_scaley.button_pressed = false
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "scaley":
					
					owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
					owner.undoHistory[-1].append(element.animation_list.duplicate(true))
					owner.undoHistory[-1].append(owner.time)
					
					if track["Loop"] == 2:
						track["Loop"] = 0
					else:
						track["Loop"] = 2
					selected_element = []
					break


func _on_loop_sprite_pressed():
	$loop_sprite.button_pressed = false
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "sprite_index":
					
					owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
					owner.undoHistory[-1].append(element.animation_list.duplicate(true))
					owner.undoHistory[-1].append(owner.time)
					
					if track["Loop"] == 2:
						track["Loop"] = 0
					else:
						track["Loop"] = 2
					selected_element = []
					break


func _on_loop_color_pressed():
	$loop_color.button_pressed = false
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "rgba":
					
					owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
					owner.undoHistory[-1].append(element.animation_list.duplicate(true))
					owner.undoHistory[-1].append(owner.time)
					
					if track["Loop"] == 2:
						track["Loop"] = 0
					else:
						track["Loop"] = 2
					selected_element = []
					break


func _on_loop_color_tl_pressed():
	$loop_color_tl.button_pressed = false
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "rgba_tl":
					
					owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
					owner.undoHistory[-1].append(element.animation_list.duplicate(true))
					owner.undoHistory[-1].append(owner.time)
					
					if track["Loop"] == 2:
						track["Loop"] = 0
					else:
						track["Loop"] = 2
					selected_element = []
					break

func _on_loop_color_bl_pressed():
	$loop_color_bl.button_pressed = false
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "rgba_bl":
					
					owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
					owner.undoHistory[-1].append(element.animation_list.duplicate(true))
					owner.undoHistory[-1].append(owner.time)
					
					if track["Loop"] == 2:
						track["Loop"] = 0
					else:
						track["Loop"] = 2
					selected_element = []
					break

func _on_loop_color_tr_pressed():
	$loop_color_tr.button_pressed = false
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "rgba_tr":
					
					owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
					owner.undoHistory[-1].append(element.animation_list.duplicate(true))
					owner.undoHistory[-1].append(owner.time)
					
					if track["Loop"] == 2:
						track["Loop"] = 0
					else:
						track["Loop"] = 2
					selected_element = []
					break


func _on_loop_color_br_pressed():
	$loop_color_br.button_pressed = false
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if owner.animation_idx < element.animation_list.size():
			for track in element.animation_list[owner.animation_idx]:
				if track["Motion"] == "rgba_br":
					
					owner.add_undo(element.setdummy, element.dummy, element.dummy(), "keyframe", element)
					owner.undoHistory[-1].append(element.animation_list.duplicate(true))
					owner.undoHistory[-1].append(owner.time)
					
					if track["Loop"] == 2:
						track["Loop"] = 0
					else:
						track["Loop"] = 2
					selected_element = []
					break


func updateEasingPreview():
	if selected_track != -1 and selected_keyframe != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		for track in element.animation_list[owner.animation_idx]:
			if track["Motion"] == trackName[selected_track]:
				if selected_keyframe +1 < track["Keyframes"].size():
					updateKeyframeSettings(track["Keyframes"][selected_keyframe], track["Keyframes"][selected_keyframe+1])


func _on_animation_list_gui_input(event):
	if event is InputEventKey and event.keycode == KEY_DELETE and event.pressed:
		if owner.animationList.size() != 0:
			owner.delAnimation()
