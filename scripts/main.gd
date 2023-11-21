extends Node2D

var current_version = "0.6.1"

var changelog = "
NEW FEATURES:
-A grid will now appear when using the sprite editor and after zooming in at least 400%.
-A grid will now appear when using the lock to grid button.
-You can customize the lock grid's size in pixels in the user settings aswell as toggle its visibility. (If it's on but not visible, it will still snap.)
-You can turn off bilinear filtering for sprites while using Wii as the target platform. (It will still be filtered it in the editor)

FIXES:
-Checkerboard background is now darker to help visibility.
"


const appname = "Puyo Puyo Animation Studio"

@onready var layer_2_panels = $Layer2_Panels
@onready var fileDialog = $Layer3_Popups/FileDialog
@onready var accept_dialog = $Layer3_Popups/AcceptDialog
@onready var dir_dialog = $Layer3_Popups/dirDialog
@onready var about = $Layer3_Popups/About
@onready var canvas_viewport = $Layer1_Canvas/CanvasViewport
@onready var puyo_canvas = $Layer1_Canvas/CanvasViewport/Center/Canvas
@onready var status_message = $Layer1_Canvas/CanvasViewport/status_message
@onready var element_list = $Layer2_Panels/PanelLeft/ElementTree
@onready var loop = $Layer2_Panels/PanelBottom/loop
@onready var panel_right = $Layer2_Panels/PanelRight
@onready var panel_bottom = $Layer2_Panels/PanelBottom
@onready var timeline = $Layer2_Panels/PanelBottom/timeline
@onready var settings = $Layer3_Popups/Settings


var undoHistory = []
var redoHistory = []
var ghostElements = []
const maxUndo = 256
var centerHead = false
var backupTimer = 0
var backupTimeLimit = 120
var fullscreen = false
signal texture_dir_task_finished


var project_settings = {"platform" : "PSP",
						"field" : [44,32,124,222],
						"hide_field" : true,
						"screen_size" : [480,272],
						"screen_anchor" : [0,0],
						"texture_dir" : "",
						"file_path" : ""}

var user_settings = {"platform" : "PSP", #Default
					"hide_field" : true,
					"filedialog_dir" : "",
					"hide_panel_left" : false,
					"hide_panel_right" : false,
					"hide_panel_bottom" : false,
					"hide_screen" : false,
					"hide_axis" : false,
					"boot_up_times": 0,
					"autobackup" : true,
					"backuptimer" : 120,
					"auto_update" : true}

var platformSettings = []
var textureList = []
var spriteCropList = []
var animationList = []

var selected_layer = -1
var selected_element = -1
var LayerList = []


# Called when the node enters the scene tree for the first time.
func _ready():
	$Layer3_Popups/SaveDialog.add_filter("*.json")
	texture_dir_task_finished.connect(updatePathLabel)
	var file = FileAccess.open("res://settings/platform_settings.json", FileAccess.READ)
	platformSettings = JSON.parse_string(file.get_as_text())
	file.close()
	
	var userData = FileAccess.open(OS.get_user_data_dir() + "/user.json", FileAccess.READ)
	if not userData is FileAccess:
		#$Layer3_Popups/About.popup()
		var newuserData = FileAccess.open(OS.get_user_data_dir() + "/user.json", FileAccess.WRITE)
		#print(OS.get_user_data_dir() + "/user.json")
		newuserData.store_string(JSON.stringify(user_settings))
		newuserData.close()
	else:
		user_settings = JSON.parse_string(userData.get_as_text())
		userData.close()
	
	if not "auto_update" in user_settings:
		user_settings["auto_update"] = true
	
	$Layer3_Popups/Settings/Node2D/btn_check_updates.button_pressed = user_settings["auto_update"]
	
	if "autobackup" in user_settings:
		autobackup = user_settings["autobackup"]
		backupTimeLimit = user_settings["backuptimer"]
		
	else:
		user_settings["autobackup"] = autobackup
		user_settings["backuptimer"] = backupTimeLimit
	
	$Layer3_Popups/Settings/Node2D/btn_autosave.button_pressed = autobackup
	$Layer3_Popups/Settings/Node2D/autosave_interval.value = backupTimeLimit / 60
	
	
	if user_settings["platform"] not in platformSettings:
		user_settings["platform"] = "PSP"
	
	if "version" not in user_settings:
		$Layer3_Popups/Changelog.dialog_text = changelog
		$Layer3_Popups/Changelog.popup()
		user_settings["version"] = current_version
	else:
		if user_settings["version"] != current_version:
			$Layer3_Popups/Changelog.dialog_text = changelog
			$Layer3_Popups/Changelog.popup()
			user_settings["version"] = current_version
	
	
	#update project_settings
	project_settings["platform"] = user_settings["platform"]
	project_settings["field"] = platformSettings[user_settings["platform"]]["field"]
	project_settings["screen_size"] = platformSettings[user_settings["platform"]]["screen_size"]
	project_settings["hide_field"] = user_settings["hide_field"]
	
	
	$Layer2_Panels/toggle_panelLeft.button_pressed = user_settings["hide_panel_left"]
	$Layer2_Panels/toggle_panelRight.button_pressed = user_settings["hide_panel_right"]
	$Layer2_Panels/toggle_panelBottom.button_pressed = user_settings["hide_panel_bottom"]
	
	if user_settings["filedialog_dir"] != "":
		$Layer3_Popups/FileDialog.current_dir = user_settings["filedialog_dir"]
		$Layer3_Popups/SaveDialog.current_dir = user_settings["filedialog_dir"]
		$Layer3_Popups/dirDialog.current_dir = user_settings["filedialog_dir"]
	$Layer1_Canvas/CanvasViewport.resetZoom()
	
	
	fileDialog.connect("file_selected", loadJsonFile)
	fileDialog.connect("canceled", noFileSelected)
	
	dir_dialog.connect("canceled", noDirSelected)
	
	$Layer2_Panels/PanelTop/platformLabel.text = "Target Platform " + project_settings["platform"]

	
	# warning-ignore:return_value_discarded
	get_tree().get_root().connect("size_changed", Callable(self, "windowResize"))
	windowResize()
	
	$Layer1_Canvas/CanvasViewport.updateObjectPositions()
	if FileAccess.file_exists(OS.get_user_data_dir() + "/backup.json"):
		$Layer3_Popups/FileDialog.current_dir = user_settings["filedialog_dir"]
		loadJsonFile(OS.get_user_data_dir() + "/backup.json", true)
		DirAccess.remove_absolute(OS.get_user_data_dir() + "/backup.json")
	else:
		newFile()
	
	#Just a bit of fun because why not lol
	if user_settings["boot_up_times"] == 2424:
		user_settings["boot_up_times"] += 1
	else:
		status_message.displayMessage("Animation Editor initialized.", true)
		user_settings["boot_up_times"] += 1
	

func animate():
	for layer in LayerList:
		for element in layer:
			element.animate(time, animation_idx, project_settings["screen_size"])

func windowResize():
	
	if not fullscreen:
		$Layer2_Panels.panelResize(get_viewport_rect().size)
		var viewport_width = 0
		var viewport_height = 0
		var viewport_position = Vector2(0,0)
		if $Layer2_Panels/toggle_panelLeft.button_pressed:
			viewport_position = Vector2(8,40)
			viewport_width = get_viewport_rect().size[0] - 16
		else:
			viewport_position = Vector2(264,40)
			viewport_width = get_viewport_rect().size[0] - 272
		
		if not $Layer2_Panels/toggle_panelRight.button_pressed:
			viewport_width -= 256
		
		if $Layer2_Panels/toggle_panelBottom.button_pressed:
			viewport_height = get_viewport_rect().size[1] - 48
		else:
			viewport_height = get_viewport_rect().size[1] - 304
		
		$Layer1_Canvas/CanvasViewport.size = Vector2(viewport_width, viewport_height)
		$Layer1_Canvas/CanvasViewport/status_message.position = Vector2(8,viewport_height - 18)
		$Layer1_Canvas/CanvasViewport.position = viewport_position
		$Layer2_Panels/PanelTop/platformLabel.position = Vector2(get_viewport_rect().size[0] - $Layer2_Panels/PanelTop/platformLabel.get_rect().size[0] - 8, 8)
		$Layer1_Canvas/CanvasViewport/focusIndicator.set_point_position(1, Vector2(canvas_viewport.size[0], 1))
		$Layer1_Canvas/CanvasViewport/focusIndicator.set_point_position(2, Vector2(canvas_viewport.size[0], canvas_viewport.size[1]))
		$Layer1_Canvas/CanvasViewport/focusIndicator.set_point_position(3, Vector2(1, canvas_viewport.size[1]))
		$Layer1_Canvas/CanvasViewport/cursorPosLabel.position = canvas_viewport.size - Vector2(190, 20)
		
		$Layer2_SpriteEditor_Panels/PanelLeft.size = Vector2(256,get_viewport_rect().size[1])
		$Layer2_SpriteEditor_Panels/PanelLeft/ItemList.size = Vector2(240,get_viewport_rect().size[1] - 80)

		$Layer2_SpriteEditor_Canvas/Control.size = get_viewport_rect().size
		
		$Layer2_Panels/PanelRight/ScrollContainer.size = $Layer2_Panels/PanelRight.size - $Layer2_Panels/PanelRight/ScrollContainer.position - Vector2(0,16)
		
		$Layer2_SpriteEditor_Canvas/close.global_position = Vector2(get_viewport_rect().size[0]-40,0)
		$Layer2_SpriteEditor_Canvas/SpinBox.global_position = get_viewport_rect().size - Vector2(100,40)
		$Layer2_SpriteEditor_Panels/PanelLeft/texture_pathBTN.position = Vector2(225,$Layer2_SpriteEditor_Panels/PanelLeft.size.y - 40)
		$Layer2_SpriteEditor_Panels/PanelLeft/texture_path.position = Vector2(8,$Layer2_SpriteEditor_Panels/PanelLeft.size.y - 32)
		
		$Layer1_Canvas/CanvasViewport/checkbg.size = get_viewport_rect().size + Vector2(256,256)
		
		$Layer2_Panels/PanelBottom/timeline/background.size = $Layer2_Panels/PanelBottom.size - $Layer2_Panels/PanelBottom/timeline/background.position - Vector2(528,40)
		$Layer2_Panels/PanelBottom/timeline/background/ColorRect.size.x = $Layer2_Panels/PanelBottom/timeline/background.size.x + 160
		$Layer2_Panels/PanelBottom/timeline/background/ColorRect2.size.x = $Layer2_Panels/PanelBottom/timeline/background.size.x
		$Layer2_Panels/PanelBottom/timeline/background/ColorRect3.size.x = $Layer2_Panels/PanelBottom/timeline/background.size.x
		$Layer2_Panels/PanelBottom/timeline/background/ColorRect4.size.x = $Layer2_Panels/PanelBottom/timeline/background.size.x
		$Layer2_Panels/PanelBottom/timeline/background/ColorRect5.size.x = $Layer2_Panels/PanelBottom/timeline/background.size.x
		$Layer2_Panels/PanelBottom/timeline/background/ColorRect6.size.x = $Layer2_Panels/PanelBottom/timeline/background.size.x
		$Layer2_Panels/PanelBottom/timeline/background/ColorRect7.size.x = $Layer2_Panels/PanelBottom/timeline/background.size.x
		
		$Layer2_Panels/PanelBottom/timeline/focus.points[2] = Vector2($Layer2_Panels/PanelBottom/timeline/background/ColorRect7.size.x, 1)
		$Layer2_Panels/PanelBottom/timeline/focus.points[3] = $Layer2_Panels/PanelBottom/timeline/background.size - Vector2(1,1)
		
		$Layer2_Panels/PanelBottom/timeline.size = $Layer2_Panels/PanelBottom/timeline/background.size
		$Layer2_Panels/PanelBottom/cosmeticShit/highlight.size.x = $Layer2_Panels/PanelBottom/timeline/background.size.x + 128
		
		$Layer2_Panels/PanelBottom/frameTime.position = Vector2($Layer2_Panels/PanelBottom.size.x - 256-78, 6)
		$Layer2_Panels/PanelBottom/speed.position = Vector2($Layer2_Panels/PanelBottom.size.x - 460, 16)
		$Layer2_Panels/PanelBottom/HScrollBar.size.x = $Layer2_Panels/PanelBottom/timeline/background.size.x
		
		$Layer2_Panels/PanelBottom/keyframeSettings.position = Vector2($Layer2_Panels/PanelBottom.size.x - 248,4)
		$Layer1_Canvas/CanvasViewport/LockToGrid.position.x = canvas_viewport.size.x - 32
		$Layer2_Panels/PanelBottom/ColorRect.size = $Layer2_Panels/PanelBottom.size
	else:
		$Layer1_Canvas/CanvasViewport.size = get_viewport_rect().size
		$Layer1_Canvas/CanvasViewport.position = Vector2(0,0)
		$Layer1_Canvas/CanvasViewport/focusIndicator.set_point_position(1, Vector2(-1, -1))
		$Layer1_Canvas/CanvasViewport/focusIndicator.set_point_position(2, Vector2(-1, -1))
		$Layer1_Canvas/CanvasViewport/focusIndicator.set_point_position(3, Vector2(-1, -1))
		#$Layer1_Canvas/CanvasViewport/cursorPosLabel.position = canvas_viewport.size - Vector2(190, 20)
		$Layer1_Canvas/CanvasViewport/checkbg.size = get_viewport_rect().size + Vector2(256,256)
	
func smoothCurve(kf_time, keyframe1, keyframe2):
	var time_diff = float(keyframe2["timestamp"]) - float(keyframe1["timestamp"])
	var time_ratio = 0.0
	if time_diff < 1:
		time_ratio = 0.0
	else:
		time_ratio = (kf_time - float(keyframe1["timestamp"])) / time_diff
	var in_control = keyframe1["ease_in"]
	var out_control = keyframe1["ease_out"]
	var data_diff = float(keyframe2["data"]) - float(keyframe1["data"])
	var cubic_term = (data_diff * -2.0 + time_diff * (in_control + out_control))* time_ratio **3
	var quadratic_term = (data_diff * 3.0 - time_diff * (in_control * 2.0 + out_control)) * time_ratio ** 2
	var linear_term = time_diff * in_control * time_ratio
	var constant_term = float(keyframe1["data"])

	return cubic_term + quadratic_term + linear_term + constant_term


var holdingCtrl = false

func restore_children(element, selectedLayer):
	for child in element.get_children():
		if child is PuyoElement:
			LayerList[selectedLayer].insert(child.id, child)
			restore_children(child,selectedLayer)

var time = 0.0
@export var animation_idx = 0 : set = setAnimIdx
var animation_max_time = 60
var playing = false 

func setAnimIdx(idx):
	for layer in LayerList:
		for element in layer:
			element.restoreDefaults()
	
	animation_idx = idx
	if animation_idx <= animationList.size()-1:
		animation_max_time = animationList[idx]["length"]
	
	for layer in LayerList:
		for element in layer:
			element.animate(time, animation_idx, project_settings["screen_size"])

var autobackup = true

func _process(delta):
	
	#auto backup
	if autobackup:
		if backupTimer >= backupTimeLimit:
			backupTimer = 0
			backupSave()
		else:
			backupTimer += 1*delta
	
	if $Layer2_Panels/PanelBottom/speed.value == 0:
		$Layer2_Panels/PanelBottom/speed.value = 0.1

	if $Layer2_Panels/PanelBottom/loop.button_pressed:
		$Layer2_Panels/PanelBottom/loop.modulate = Color(0.5,0.5,1)
	else:
		$Layer2_Panels/PanelBottom/loop.modulate = Color(1,1,1)
	
	
	if $Layer2_Panels/PanelBottom/autoplay.button_pressed:
		$Layer2_Panels/PanelBottom/autoplay.modulate = Color(0.5,0.5,1)
	else:
		$Layer2_Panels/PanelBottom/autoplay.modulate = Color(1,1,1)
	
	
	var time_scale = $Layer2_Panels/PanelBottom/speed.value
	$Layer2_Panels/PanelBottom/speed/playbackSpeedLabel.text = "Playback Speed:     " + str(time_scale) + "x"
	if playing:
		$Layer2_Panels/PanelBottom/playPause.icon = load("res://Graphics/timeline/pause.png")
		$Layer1_Canvas/CanvasViewport.draggingPivot = false
		$Layer1_Canvas/CanvasViewport.draggingElement = false
		$Layer1_Canvas/CanvasViewport.draggingScaleX = false
		$Layer1_Canvas/CanvasViewport.draggingScaleY = false
		$Layer1_Canvas/CanvasViewport.draggingAngle = false
		$"Layer2_Panels/PanelRight/ScrollContainer/Control/ColorRect".visible = true
		$Layer1_Canvas/CanvasViewport/ElementStuff.visible = false
		if animationList.size() == 0 or animation_idx > animationList.size()-1:
			status_message.displayMessage("No animation to play.")
			playing = false
			$"Layer2_Panels/PanelRight/ScrollContainer/Control/ColorRect".visible = false
			$Layer1_Canvas/CanvasViewport/ElementStuff.visible = true
			for layer in LayerList:
				for element in layer:
					element.saveDefaults = true
		else:
			status_message.displayMessage("Playing \"" + animationList[animation_idx]["name"] + "\" - Frame " + str(int(time)))
		time += (60*time_scale)*delta
		
		if time >= animation_max_time:
			
			time = 0.0
			
			if $Layer2_Panels/PanelBottom/autoplay.button_pressed:
				if animation_idx < animationList.size()-1:
					#print(animation_idx, " - ", animationList.size())
					setAnimIdx(animation_idx+1)
					$Layer2_Panels/PanelBottom.selected_element = []
				elif not $Layer2_Panels/PanelBottom/loop.button_pressed:
					playing = false
					$Layer2_Panels/PanelBottom/HScrollBar.value = 0
					setAnimIdx(0)
					$Layer2_Panels/PanelBottom.selected_element = []
			
			elif not $Layer2_Panels/PanelBottom/loop.button_pressed:
				playing = false
				#$Layer2_Panels/PanelBottom/HScrollBar.value = 0 
				
		if $Layer2_Panels/PanelBottom/timeline/Head.global_position.x > $Layer2_Panels/PanelBottom.size.x - 264 or $Layer2_Panels/PanelBottom/timeline/Head.global_position.x < 256:
			#print("off screen")
			$Layer2_Panels/PanelBottom/HScrollBar.value = time
		
		for layer in LayerList:
			for element in layer:
				element.animate(time, animation_idx, project_settings["screen_size"])
#				if not playing:
#					element.restoreDefaults()
#				else:
#
				
		
		panel_right.update()
	else:
		$Layer2_Panels/PanelBottom/playPause.icon = load("res://Graphics/timeline/play.png")
		$"Layer2_Panels/PanelRight/ScrollContainer/Control/ColorRect".visible = false
		$"Layer1_Canvas/CanvasViewport/ElementStuff".visible = true
		for layer in LayerList:
			for element in layer:
				#print(element, "element")
				element.saveDefaults = true
	$Layer2_Panels/PanelBottom/frameTime.value = round(time) 
	$Layer2_Panels/PanelBottom/timeline/Head.position = Vector2((time*(16*$Layer2_Panels/PanelBottom.zoomLevel)-$Layer2_Panels/PanelBottom/HScrollBar.value*(16*$Layer2_Panels/PanelBottom.zoomLevel)), 0)



func toggleSpriteEditor():
	$Layer1_Canvas.visible = not $Layer1_Canvas.visible
	$Layer2_Panels.visible = not $Layer2_Panels.visible
	
	$Layer2_SpriteEditor_Canvas.visible = not $Layer2_SpriteEditor_Canvas.visible
	$Layer2_SpriteEditor_Panels.visible = not $Layer2_SpriteEditor_Panels.visible
	$Layer2_SpriteEditor_Panels/PanelLeft/ItemList.update()
	if $Layer2_SpriteEditor_Canvas.visible:
		$Layer2_SpriteEditor_Canvas/Control.grab_focus()
	else:
		$Layer1_Canvas/CanvasViewport.grab_focus()
		for layer in LayerList:
			for element in layer:
				element.update()

func _input(event):
	
	
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and $Layer2_Panels/PanelBottom/timeline.has_focus():
		playing = not playing

	
	if event is InputEventKey and event.keycode == KEY_S and event.pressed and holdingCtrl:
		startSaveTask(false)
	
	if event is InputEventKey and event.keycode == KEY_O and event.pressed and holdingCtrl:
		startOpenFileTask()
	
#	if event is InputEventKey and event.keycode == KEY_F2 and event.pressed:
#		$Layer1_Canvas/CanvasViewport.resetZoom()
	
	if event is InputEventKey and event.keycode == KEY_E and holdingCtrl and event.pressed:
		toggleSpriteEditor()
	if event is InputEventKey and event.keycode == KEY_CTRL:
		holdingCtrl = event.pressed
	if event is InputEventKey and event.keycode == KEY_Z and holdingCtrl and event.pressed:
		if len(undoHistory) > 0 and not $Layer1_Canvas/CanvasViewport.undoBlock:
			var undo = undoHistory[len(undoHistory)-1]
			status_message.displayMessage("Undo last action.")
			if undo[3] == "value": #undoing a value change
				var params = undo[1].call()
				undo[0].call(undo[2])
				add_redo(undo[0], undo[1], params, undo[3], undo[4])
				selected_element = undo[4].id
				selected_layer = undo[4].layer
				element_list.updateSelected()
			
			elif undo[3] == "keyframe":
				var params = undo[1].call()
				undo[0].call(undo[2])
				add_redo(undo[0], undo[1], params, undo[3], undo[4])
				redoHistory[-1].append(undo[4].animation_list.duplicate(true))
				redoHistory[-1].append(undo[6])
				selected_element = undo[4].id
				selected_layer = undo[4].layer
				element_list.updateSelected()
				undo[4].animation_list = undo[5].duplicate(true)
				time = undo[6]
				animate()
				$Layer2_Panels/PanelBottom.selected_element = []
				$Layer2_Panels/PanelBottom.updateEasingPreview()
			
			elif undo[3] == "deletion": #undoing element deletion
				
				#Fill up the layer list with a bunch of strings, to occupy space for insertion.
				for i in range(64):
					LayerList[undo[4].layer].append("")
				#set the selected element to -1 temporarily top stop process(delta) from breaking
				selected_element = -1
				undo[0].call(undo[2]) #Restore parent
				LayerList[undo[4].layer].insert(undo[2].id, undo[2]) #re-insert the element in the list
				
				restore_children(undo[2], undo[4].layer) #restore all children.
				
				#remove all strings
				var newArray = []
				for item in LayerList[undo[4].layer]:
					if not item is String:
						newArray.append(item)
				LayerList[undo[4].layer] = newArray
				
				#set the selected element
				selected_element = undo[2].id
				selected_layer = undo[2].layer
				updateElementIDs()
				$Layer2_Panels/PanelLeft/ElementTree.updateList()
				element_list.updateSelected()
				
				ghostElements.pop_at(len(ghostElements)-1)
				add_redo(undo[0], undo[1], undo[2], undo[3], undo[4])
				
			elif undo[3] == "creation":
				unCreateElement(undo[2])
			
			elif undo[3] == "layerlist":
				add_redo(LayerList.duplicate(true), undo[1], undo[2], undo[3], undo[4])
				LayerList = undo[0].duplicate(true)
				selected_layer = undo[1]
				selected_element = undo[2]
			
			elif undo[3] == "hierarchy":
				add_redo(undo[1].get_parent(), undo[1], undo[2], undo[3], LayerList.duplicate(true))
				undo[1].reparent(undo[0])
				undo[1].update()
				LayerList = undo[4].duplicate(true)
				
				updateElementIDs()
				selected_layer = undo[1].layer
				selected_element = undo[1].id
			
			elif undo[3] == "layerDel":
				add_redo(undo[0], undo[1], undo[2], undo[3], undo[4])
				selected_layer = undo[1]
				LayerList.insert(undo[0], [])
			elif undo[3] == "delAnim":
				add_redo("", undo[1], undo[2], undo[3], undo[4])
				animationList.append(undo[2])
				animation_idx = undo[1]
				var layer_idx = 0
				for layer in LayerList:
					var element_idx = 0
					for element in layer:
#						undo[0][layer_idx]
						element.animation_list.append(undo[0][layer_idx][element_idx].duplicate(true))
						element_idx += 1
					layer_idx+=1
				$Layer2_Panels/PanelBottom.updateAnimList()
			undoHistory.pop_back()
			checkGhosts(-1)
			$Layer2_Panels/PanelRight.update()
			$Layer2_Panels/PanelLeft/ElementTree.updateList()
			$Layer2_Panels/PanelLeft/ElementTree.updateSelected()
			
			updateElementsettings()

	if event is InputEventKey and event.keycode == KEY_Y and holdingCtrl and event.pressed:
		if len(redoHistory) > 0 and not $Layer1_Canvas/CanvasViewport.undoBlock:
			var redo = redoHistory[len(redoHistory)-1]
			status_message.displayMessage("Redo last action.")
			if redo[3] == "value":
				var params = redo[1].call()
				redo[0].call(redo[2])
				add_undo(redo[0], redo[1], params, redo[3], redo[4], false)
				selected_element = redo[4].id
				selected_layer = redo[4].layer
				element_list.updateSelected()
			
			if redo[3] == "keyframe":
				var params = redo[1].call()
				redo[0].call(redo[2])
				add_undo(redo[0], redo[1], params, redo[3], redo[4], false)
				var oldAnim = redo[4].animation_list.duplicate(true)
				undoHistory[-1].append(oldAnim)
				undoHistory[-1].append(redo[6])
				selected_element = redo[4].id
				selected_layer = redo[4].layer
				redo[4].animation_list = redo[5].duplicate(true)
				time = redo[6]
				element_list.updateSelected()
				animate()
				$Layer2_Panels/PanelBottom.selected_element = []
				$Layer2_Panels/PanelBottom.updateEasingPreview()
			
			elif redo[3] == "deletion":
				delElement(redo[2], true, true)
			
			elif redo[3] == "creation":
				#Fill up the layer list with a bunch of strings, to occupy space for insertion.
				for i in range(64):
					LayerList[redo[4].layer].append("")
				#set the selected element to -1 temporarily top stop process(delta) from breaking
				selected_element = -1
				redo[0].call(redo[2]) #Restore parent
				LayerList[redo[4].layer].insert(redo[2].id, redo[2]) #re-insert the element in the list
				
				restore_children(redo[2], redo[4]) #restore all children.
				
				#remove all strings
				var newArray = []
				for item in LayerList[redo[4].layer]:
					if not item is String:
						newArray.append(item)
				LayerList[redo[4].layer] = newArray
				
				#set the selected element
				selected_element = redo[2].id
				selected_layer = redo[2].layer
				updateElementIDs()
				
				ghostElements.pop_at(len(ghostElements)-1)
				add_undo(redo[0], redo[1], redo[2], redo[3], redo[4], false)
			
			elif redo[3] == "layerlist":
				add_undo(LayerList.duplicate(true), redo[1], redo[2], redo[3], redo[4], false)
				LayerList = redo[0].duplicate(true)
				selected_layer = redo[1]
				selected_element = redo[2]
				
			
			elif redo[3] == "hierarchy":
				add_undo(redo[1].get_parent(), redo[1], redo[2], redo[3], LayerList.duplicate(true), false)
				redo[1].reparent(redo[0])
				redo[1].update()
				LayerList = redo[4].duplicate()
				
				updateElementIDs()
				selected_layer = redo[1].layer
				selected_element = redo[1].id
			
			elif redo[3] == "layerDel":
				add_undo(redo[0], redo[1], redo[2], redo[3], redo[4], false)
				LayerList.pop_at(redo[0])
				selected_layer = redo[1]
			elif redo[3] == "delAnim":
				delAnimation(false)
				$Layer2_Panels/PanelBottom.updateAnimList()
			
			
			redoHistory.pop_back()
			checkGhosts(+1)
			$Layer2_Panels/PanelLeft/ElementTree.updateList()
			$Layer2_Panels/PanelLeft/ElementTree.updateSelected()
			$Layer2_Panels/PanelRight.update()
			updateElementsettings()

func checkGhosts(hp):
	var elementidx = 0
	for element in ghostElements:
		if element[0] <= 0:
			if not element[1] == null:
				element[1].queue_free()
			ghostElements.pop_at(elementidx)
		else:
			element[0] += hp
		elementidx +=1


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		user_settings["filedialog_dir"] = fileDialog.current_dir
		
		user_settings["hide_panel_left"] = $Layer2_Panels/toggle_panelLeft.button_pressed
		user_settings["hide_panel_right"] = $Layer2_Panels/toggle_panelRight.button_pressed
		user_settings["hide_panel_bottom"] = $Layer2_Panels/toggle_panelBottom.button_pressed
		
		var newuserData = FileAccess.open(OS.get_user_data_dir() + "/user.json", FileAccess.WRITE)
		#print(OS.get_user_data_dir() + "/user.json")
		newuserData.store_string(JSON.stringify(user_settings, "\t", false))
		newuserData.close()
		backupSave()
		
		
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		$Layer1_Canvas/CanvasViewport.holdingMoveKey = false
		$Layer1_Canvas/CanvasViewport.holdingAlt = false
		$Layer1_Canvas/CanvasViewport.draggingPivot = false
		$Layer1_Canvas/CanvasViewport.draggingElement = false
		$Layer1_Canvas/CanvasViewport.draggingScaleX = false
		$Layer1_Canvas/CanvasViewport.draggingScaleY = false
		$Layer1_Canvas/CanvasViewport.draggingAngle = false

func add_redo(setter, getter, params, type, element):
	if len(redoHistory) >= maxUndo:
		redoHistory.pop_at(0)
	redoHistory.append([setter, getter, params, type, element])

func add_undo(setter, getter, params, type, element, clear = true):
	if clear:
		redoHistory = []
		checkGhosts(-1)
	if len(undoHistory) >= maxUndo:
		undoHistory.pop_at(0)
	undoHistory.append([setter, getter, params, type, element])

func updateTargetPlatform(platform_name):
	status_message.displayMessage("Platform set to: " + platform_name + ".")
	
	var newScreen_size = platformSettings[platform_name]["screen_size"]
	var oldScreen_size = project_settings["screen_size"]
	
	for layer in LayerList:
		for element in layer:
			for animation in element.animation_list:
				for motion in animation:
					if motion["Motion"] == "posx":
						for keyframe in motion["Keyframes"]:
							keyframe["data"] = (keyframe["data"]*oldScreen_size[0])/newScreen_size[0]
							if keyframe["ease_in"] != 0:
								keyframe["ease_in"] = (keyframe["ease_in"]*oldScreen_size[0])/newScreen_size[0]
							if keyframe["ease_out"] != 0:
								keyframe["ease_out"] = (keyframe["ease_out"]*oldScreen_size[0])/newScreen_size[0]
					if motion["Motion"] == "posy":
						for keyframe in motion["Keyframes"]:
							keyframe["data"] = (keyframe["data"]*oldScreen_size[1])/newScreen_size[1]
							if keyframe["ease_in"] != 0:
								keyframe["ease_in"] = (keyframe["ease_in"]*oldScreen_size[1])/newScreen_size[1]
							if keyframe["ease_out"] != 0:
								keyframe["ease_out"] = (keyframe["ease_out"]*oldScreen_size[1])/newScreen_size[1]
	
	
	project_settings["platform"] = platform_name
	project_settings["field"] = platformSettings[platform_name]["field"]
	project_settings["screen_size"] = platformSettings[platform_name]["screen_size"]
	user_settings["platform"] = platform_name
	$Layer2_Panels/PanelTop/platformLabel.text = "Target Platform " + project_settings["platform"]
	if not fullscreen:
		$Layer1_Canvas/CanvasViewport.resetZoom()
	else:
		$Layer1_Canvas/CanvasViewport.fillZoom()
	$Layer1_Canvas/CanvasViewport.updateObjectPositions()

func toggleField():
	status_message.displayMessage("Field visibility toggled.")
	project_settings["hide_field"] = not project_settings["hide_field"]
	user_settings["hide_field"] = project_settings["hide_field"]
	$Layer1_Canvas/CanvasViewport.updateObjectPositions()

func toggleScreen():
	status_message.displayMessage("Screen visibility toggled.")
	user_settings["hide_screen"] = not user_settings["hide_screen"]
	$Layer1_Canvas/CanvasViewport.updateObjectPositions()

func toggleAxis():
	status_message.displayMessage("Axis visibility toggled.")
	user_settings["hide_axis"] = not user_settings["hide_axis"]
	$Layer1_Canvas/CanvasViewport.updateObjectPositions()
#####FILE STUFF####



func newFile():
	resetVariables()
	get_viewport().title = appname + " v" + current_version
	project_settings["file_path"] = ""
	project_settings["texture_dir"] = ""
	updatePathLabel()
	textureList = []
	$Layer2_SpriteEditor_Canvas/Control/Center/Canvas/texture.texture = null
	$Layer2_SpriteEditor_Panels/PanelLeft/ItemList.update()
	for child in $Layer2_SpriteEditor_Canvas/Control/Center/Canvas/other_crops.get_children():
		child.queue_free()
	
	
	$Layer2_Panels/PanelBottom.updateAnimList()
	status_message.displayMessage("New file created")
	
func resetVariables():
	time = 0
	playing = false
	animation_idx = 0
	animationList = []
	animation_max_time = 0
	updatePathLabel()
	spriteCropList = []
	
	for element in ghostElements:
		if element[1]:
			element[1].queue_free()
	ghostElements = []
	$Layer2_SpriteEditor_Panels/PanelLeft/ItemList.ignore = true
	$Layer2_SpriteEditor_Canvas/SpinBox.value = 0
	$Layer2_SpriteEditor_Canvas/SpinBox.max_value = 0
	$Layer2_SpriteEditor_Panels/PanelLeft/ItemList.ignore = false
	$Layer2_SpriteEditor_Panels/PanelLeft/ItemList.selected = -1
	$Layer2_SpriteEditor_Panels/PanelLeft/ItemList.update()
	
	undoHistory = []
	redoHistory = []
	for layer in LayerList:
		for element in layer:
			element.queue_free()
	selected_layer = -1
	selected_element = -1
	LayerList = []
	$Layer2_Panels/PanelLeft/ElementTree.itemList = []
	$Layer1_Canvas/CanvasViewport.resetZoom()
	$Layer2_Panels/PanelLeft/ElementTree.updateList()


func list_files_in_directory(path):
	var files = []
	var file_list = DirAccess.get_files_at(path)
	

	for file in file_list:
		if file == "":
			break
		elif not file.begins_with(".") and file.find(".import") == -1:
			if file.find(".png") != -1 or file.find(".PNG") != -1:
				files.append(path + "/" + file)
	#print(files)
	return files

func startOpenFileTask():
	$Layer3_Popups/FileDialog.current_dir = user_settings["filedialog_dir"]
	fileDialog.add_filter("*.json")
	fileDialog.popup()
	
var cancelled = false

func loadJsonFile(file_path, backup = false):
	
	if not backup:
		user_settings["filedialog_dir"] = $Layer3_Popups/FileDialog.current_dir
	get_viewport().title = appname + " v" + current_version + " : " + file_path
	var jsonFile = FileAccess.open(file_path, FileAccess.READ)
	var jsonData = JSON.parse_string(jsonFile.get_as_text())
	fileDialog.hide()
	var loadReady = false
	#File is broken?
	if not jsonData is Dictionary:
		accept_dialog.dialog_text = "Not a valid json file."
		accept_dialog.popup()
	
	else:	#File is not broken
		#but is file formated correctly?
		if "Misc. Info" in jsonData and "Sprite Crops" in jsonData and "Element Banks" in jsonData and "Animations" in jsonData:
			if "Editor Settings" in jsonData: #YES!
				selectedTextureDir(jsonData["Editor Settings"]["Texture Dir"])
				if len(textureList) != 0: #Does the path even exist/have png files in it?
					loadReady = true
				else:	#if not, then ask user for it
					if jsonData["Sprite Crops"] != []:
						accept_dialog.dialog_text = "Please select a folder with the sprites as PNG files."
						accept_dialog.popup()
						await accept_dialog.confirmed
						startTextureDirTask()
						await self.texture_dir_task_finished
						if project_settings["texture_dir"] != "" and not cancelled:	#Did user select anything or nah?
							loadReady = true
							#make check here if there's any textures loaded.
						else:
							cancelled = false
							dir_dialog.hide()
							accept_dialog.dialog_text = "Cancelled or no PNG files found."
							accept_dialog.popup()
					else: #no sprite crops, so just load anyway lol
						loadReady = true
			else: #Oh well, let's check if it has sprite crops
				if len(jsonData["Sprite Crops"]) != 0: #It does, so let's ask the user to select a directory with it's sprites
					accept_dialog.dialog_text = "Please select a folder with the sprites as PNG files."
					accept_dialog.popup()
					await accept_dialog.confirmed
					startTextureDirTask()
					await self.texture_dir_task_finished
					if project_settings["texture_dir"] != "" and not cancelled:	#Did user select anything or nah?
						loadReady = true
						#make check here if there's any textures loaded.
					else:
						cancelled = false
						dir_dialog.hide()
						accept_dialog.dialog_text = "Cancelled or no PNG files found."
						accept_dialog.popup()
				else: #it doesn't so i guess it doesn't matter.
					loadReady = true
		else:
			accept_dialog.dialog_text = "Not a valid animation json file."
			accept_dialog.popup()
		
		if loadReady:
			if backup:
				project_settings["file_path"] = jsonData["Editor Settings"]["file_dir"]
				get_viewport().title = appname + " v" + current_version + " : " + jsonData["Editor Settings"]["file_dir"]
			else:
				project_settings["file_path"] = file_path
			status_message.displayMessage("Loaded: " + file_path + ".", true)
			LoadData(jsonData)
	cancelled = false
	
func noFileSelected():
	cancelled = true
	dir_dialog.hide()
	accept_dialog.dialog_text = "Cancelled"
	$Layer3_Popups/FileDialog.hide()
	accept_dialog.popup()

func startTextureDirTask():
	dir_dialog.current_dir = fileDialog.current_dir
	dir_dialog.popup()

func reloadTextures(_dummy):
	selectedTextureDir(project_settings["texture_dir"])

var png_list

func selectedTextureDir(selected_dir):
	if selected_dir != "":
		png_list = list_files_in_directory(selected_dir)
		if len(png_list) != 0:
			for child in $directory_watcher.get_children():
				child.queue_free()
			var dwatcher = DirectoryWatcher.new()
			dwatcher.add_scan_directory(selected_dir)
			dwatcher.scan_delay = 1
			dwatcher.files_modified.connect(reloadTextures)
			$directory_watcher.add_child(dwatcher)
			textureList = []
			project_settings["texture_dir"] = selected_dir
			
			for png in png_list:
				var done = false
				var cycles = 0
				while not done:
					cycles += 1
					#print(png)
					var img = Image.new()
					img.load(png)
					var tex = ImageTexture.create_from_image(img)
					#$Layer3_Popups/Sprite2D.texture = tex
					if tex:
						done = true
						textureList.append(tex)
					if cycles > 4000: #can't so continue anyway?
						done = true
					
			
			for sprite in spriteCropList:
				if sprite.texIDX in range(textureList.size()):
					sprite.setOgTexture(textureList[sprite.texIDX], sprite.texIDX)
				else:
					sprite.setOgTexture(textureList[0], 0)
			$Layer2_SpriteEditor_Panels/PanelLeft/ItemList.update()
	emit_signal("texture_dir_task_finished")

func noDirSelected():
	cancelled = true
	emit_signal("texture_dir_task_finished")

signal savepathTaskFinished

func startSaveTask(updatepath = false):
	if project_settings["file_path"] == "":
		getSavePathTask()
		await savepathTaskFinished
		if project_settings["file_path"] != "":
			saveAt(project_settings["file_path"], false, updatepath)
	else:
		saveAt(project_settings["file_path"],false, updatepath)

var oldfilepath

func startSaveAsTask():
	oldfilepath = project_settings["file_path"]
	project_settings["file_path"] = ""
	getSavePathTask()
	await savepathTaskFinished
	if project_settings["file_path"] != "":
		saveAt(project_settings["file_path"])
	else:
		project_settings["file_path"] = oldfilepath


func _on_save_dialog_file_selected(path):
	if path.right(5) != ".json":
		path += ".json"
	
	project_settings["file_path"] = path
	savepathTaskFinished.emit()

func getSavePathTask():
	$Layer3_Popups/SaveDialog.current_dir = user_settings["filedialog_dir"]
	$Layer3_Popups/SaveDialog.popup()

func saveAt(path, backup = false, update_path = false):
	var new_json = formatAnimationData()
	if backup:
		new_json["Editor Settings"]["file_dir"] = project_settings["file_path"]
		status_message.displayMessage("Backup made at : " + path)
	else:
		if update_path:
			user_settings["filedialog_dir"] = $Layer3_Popups/SaveDialog.current_dir
		get_viewport().title = appname + " v" + current_version + " : " + path
		status_message.displayMessage("Saved at: " + path, true)
	new_json =  JSON.stringify(new_json, "\t", false)
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	
	file.store_string(new_json)
	file.close()
	
func formatAnimationData():
	var anim_data_json = {}
	
	var spriteCrops = []
	for crop in spriteCropList:
		var JsonCrop = {}
		JsonCrop["texture"] = crop.texIDX
		#print(crop.original_tex)
		JsonCrop["top_left_X"] = crop.cropping_positions[0]
		JsonCrop["top_left_Y"] = crop.cropping_positions[1]
		JsonCrop["bottom_right_X"] = crop.cropping_positions[2]
		JsonCrop["bottom_right_Y"] = crop.cropping_positions[3]
		spriteCrops.append(JsonCrop)
	
	var elementBanks = []
	for bank in LayerList:
		var JsonBankList = []
		for element in bank:
			var JsonElement = {}
			JsonElement["Index"] = element.id
			JsonElement["Name"] = element.element_name
			if element.get_parent() is PuyoElement:
				JsonElement["Parent"] = element.get_parent().id
			else:
				JsonElement["Parent"] = -1
			JsonElement["Unknown Flag 0"] = 1
			JsonElement["Render Flag"] = int(element.render)
			JsonElement["Unknown Flag 1"] = 1
			JsonElement["2D Polygon"] = [(- element.pivot_point[0]) / project_settings["screen_size"][0], #
										(- element.pivot_point[1]) / project_settings["screen_size"][1],  #
										
										(- element.pivot_point[0]) / project_settings["screen_size"][0],  #
										(element.element_size[1] - element.pivot_point[1]) / project_settings["screen_size"][1],   #
										
										(element.element_size[0] - element.pivot_point[0]) / project_settings["screen_size"][0],   #
										(- element.pivot_point[1]) / project_settings["screen_size"][1],  #
										
										(element.element_size[0] - element.pivot_point[0]) / project_settings["screen_size"][0],   #
										(element.element_size[1] - element.pivot_point[1]) / project_settings["screen_size"][1]]   #
			
			var inheritance = 16 + 32 + 64 + 128 + 28672
			
			if element.inherit_position[0] and element.inherit_position[1]:
				inheritance += 1 + 256 + 512
			elif element.inherit_position[0]:
				inheritance += 256
			elif element.inherit_position[1]:
				inheritance += 512
			
			if element.inherit_scale[0] and element.inherit_scale[1]:
				inheritance += 4 + 1024 + 2048
			elif element.inherit_scale[0]:
				inheritance += 1024
			elif element.inherit_scale[1]:
				inheritance += 2048
				
			if element.inherit_angle:
				inheritance+= 2
			
			if element.inherit_color:
				inheritance+= 8
			
			
			JsonElement["Unknown Values"] = [32767, inheritance, 0]
			
			var flipValue = 0
			if element.flipX and element.flipY:
				flipValue = 12
			elif element.flipX:
				flipValue = 04
			elif element.flipY:
				flipValue = 08
			if element.filter_wii:
				flipValue+= 16
			JsonElement["Render Settings"] = {"dodge_blend" : int(element.add_blend),
											"unknown_1" : flipValue,
											"unknown_2": 5}
			var spriteIDXList = []
			
			for sprite in element.sprite_list:
				var idx = 0
				for crop in spriteCropList:
					if sprite == crop.texture:
						spriteIDXList.append(idx)
					idx+= 1
			
			JsonElement["Sprite List"] = spriteIDXList
			JsonElement["Default Settings"] = {"hide" : int(not element.visibility),
												"posx" : element.defaultSettings["positionX"] / project_settings["screen_size"][0],
												"posy" : element.defaultSettings["positionY"] / project_settings["screen_size"][1],
												"angle" : -element.defaultSettings["angle"],
												"scalex" : element.defaultSettings["scalex"],
												"scaley" : element.defaultSettings["scaley"],
												"sprite_index" : element.defaultSettings["sprite_index"],
												"rgba" : {"red": element.defaultSettings["color"].r8,
															"green": element.defaultSettings["color"].g8,
															"blue":  element.defaultSettings["color"].b8,
															"alpha": element.defaultSettings["color"].a8},
															
												"rgba_tl" : {"red":  element.defaultSettings["color_tl"].r8,
															"green": element.defaultSettings["color_tl"].g8,
															"blue":  element.defaultSettings["color_tl"].b8,
															"alpha": element.defaultSettings["color_tl"].a8},
															
												"rgba_bl" : {"red":  element.defaultSettings["color_bl"].r8,
															"green": element.defaultSettings["color_bl"].g8,
															"blue":  element.defaultSettings["color_bl"].b8,
															"alpha": element.defaultSettings["color_bl"].a8},
							
												"rgba_tr" : {"red":  element.defaultSettings["color_tr"].r8,
															"green": element.defaultSettings["color_tr"].g8,
															"blue":  element.defaultSettings["color_tr"].b8,
															"alpha": element.defaultSettings["color_tr"].a8},
							
												"rgba_br" : {"red":  element.defaultSettings["color_br"].r8,
															"green": element.defaultSettings["color_br"].g8,
															"blue":  element.defaultSettings["color_br"].b8,
															"alpha": element.defaultSettings["color_br"].a8},
												"audio_cue?" : 0,
												"3d_depth" : element.depth,
												"unk_motion" : 0}
			if element.name_order != -2424:
				JsonElement["Name Index"] = element.name_order
			JsonBankList.append(JsonElement)
		elementBanks.append(JsonBankList)
	
	var jsonAnimList = []
	for animation in range(len(animationList)):
		var JsonAnims = []
		for bank in LayerList:
			var JsonBankList = []
			for element in bank:
				var animation_list
				if animation > element.animation_list.size()-1:
					animation_list = {"Index" : element.id+1, "Animations": []}
				else:
					animation_list = {"Index" : element.id+1, "Animations": element.animation_list[animation]}
				
				JsonBankList.append(animation_list)
			JsonAnims.append(JsonBankList)
		jsonAnimList.append({"Name" : animationList[animation]["name"],
							"Length Range" : [0, animationList[animation]["length"]],
							"Element Banks" : JsonAnims})
	anim_data_json = {
		"Editor Settings": {
			"Texture Dir": project_settings["texture_dir"]
		},
		"Misc. Info" : {
		"Header Magic": platformSettings[project_settings["platform"]]["magic"],
		"Aspect Ratio": platformSettings[project_settings["platform"]]["aspect"],
		"Screen Size": str(project_settings["screen_size"][0]) + "x" + str(project_settings["screen_size"][1]),
		"Byte Order": platformSettings[project_settings["platform"]]["endianness"]
		},
		"Unk. Patterns": [],
		"Sprite Crops": spriteCrops,
		"Element Banks": elementBanks,
		"Animations": jsonAnimList}
	return (anim_data_json)
###PuyoElementStuff###

func updateElementIDs():
	var layerid = 0
	var zindex = 0
	
	for layer in LayerList:
		var elementid = 0
		for element in layer:
			if element is PuyoElement:
				element.layer = layerid
				element.id = elementid
				element.z_index = zindex
				element.z_as_relative = false
				elementid += 1
				zindex+=1
		layerid += 1

func newElement(parent = -1, undo = true):
	if selected_layer != -1:
		

		
		status_message.displayMessage("New element created.")
		var puyoElement = PuyoElement.new()
		var newName = ensure_unique_element_name("NewElement")
		puyoElement.setName(newName)
		var parent_elem = -1
		if parent != -1:
			parent_elem = LayerList[selected_layer][parent]
		#selected_element = puyoElement.id
		if parent <= -1:
			puyo_canvas.add_child(puyoElement)
			LayerList[selected_layer].append(puyoElement)
		else:
			
			var newID = parent
			for child in LayerList[selected_layer][parent].get_children():
				if child is PuyoElement:
					newID = child.id
			
			
			LayerList[selected_layer][parent].add_child(puyoElement)
			LayerList[selected_layer].insert(newID+1, puyoElement)
		updateElementIDs()
		if parent != -1:
			selected_element = parent_elem.id
		for anim in animationList:
			puyoElement.animation_list.append([])
		
		puyoElement.global_position = $Layer1_Canvas/CanvasViewport.global_position + $Layer1_Canvas/CanvasViewport.get_rect().size/2
		puyoElement.setPosition(puyoElement.position)
		$Layer2_Panels/PanelLeft/ElementTree.updateList()
		$Layer2_Panels/PanelLeft/ElementTree.updateSelected()
		
		#add undo
		if undo:
			add_undo(puyoElement.get_parent().add_child, puyoElement.get_parent, puyoElement, "creation", puyoElement)
		else:
			add_undo(puyoElement.get_parent().add_child, puyoElement.get_parent, puyoElement, "creation", puyoElement,false)
		
	else:
		status_message.displayMessage("Cannot create element. Create a new layer first.")

func addGhostElement(hp, element):
	var not_in = true
	
	for i in ghostElements:
		if i[1] == element:
			not_in = false
	if not_in:
		ghostElements.append([hp, element])


func delElement(element, tree = false, redo = false):
	
	if tree:
		add_undo(element.get_parent().add_child, element.get_parent, element, "deletion", element, not redo)
		
		#add_undo(element.get_parent().add_child, element.get_parent, element, "deletion", selected_layer) #Problem here when re-doing a deletion, it clears the re-do history when It shouldn't
		selected_element = -1
		status_message.displayMessage(element.element_name + " deleted.")
		element.get_parent().remove_child(element)
	
	for child in element.get_children():
		if child is PuyoElement:
			delElement(child, false, redo)
	
	var idx = LayerList[element.layer].find(element)
	LayerList[element.layer].pop_at(idx)
	
	addGhostElement(maxUndo+2, element)
	
	if tree:
		updateElementIDs()
		$Layer2_Panels/PanelLeft/ElementTree.updateList()
		$Layer2_Panels/PanelLeft/ElementTree.updateSelected()
	

func unCreateElement(element):
	add_redo(element.get_parent().add_child, element.get_parent, element, "creation", element)
	if selected_element > -1:
		selected_element -= 1
	element.get_parent().remove_child(element)
	
	for child in element.get_children():
		if child is PuyoElement:
			unCreateElement(child)
			
	var idx = LayerList[element.layer].find(element)
	LayerList[element.layer].pop_at(idx)
	addGhostElement(maxUndo+2, element)
	
	updateElementIDs()
	$Layer2_Panels/PanelLeft/ElementTree.updateList()
	$Layer2_Panels/PanelLeft/ElementTree.updateSelected()



func newLayer(clear = true):
	status_message.displayMessage("New layer created.")
	add_undo(LayerList.duplicate(true), selected_layer, selected_element, "layerlist", "none", clear)
	
	LayerList.append([])
	selected_element = -1
	selected_layer = LayerList.size()-1
	
	updateElementIDs()
	$Layer2_Panels/PanelLeft/ElementTree.updateList()
	$Layer2_Panels/PanelLeft/ElementTree.updateSelected()
	
func ensure_unique_element_name(name_to_check: String) -> String:
	
	var name_no_number = ""
	var name_count = ""
	for i in name_to_check:
		if not i.is_valid_int():
			name_no_number += i
		else:
			name_count+= i
	name_count = int(name_count)
	name_to_check = name_no_number
	
	var new_name = name_to_check
	
	var used_names = [name_to_check]
	
	for layer in LayerList:
		for element in layer:
			used_names.append(element.element_name)
	
	while new_name in used_names:
		new_name = name_to_check + str(name_count)
		name_count += 1

	return new_name


func _on_canvas_viewport_selected_element():
	$Layer2_Panels/PanelLeft/ElementTree.updateSelected()

func move_element_up():
	pass
	$Layer2_Panels/PanelLeft/ElementTree.ignore_selected = true
	if selected_element < LayerList[selected_layer].size() - 1 and selected_element != -1:
		var temp = LayerList[selected_layer][selected_element]
		LayerList[selected_layer][selected_element] = LayerList[selected_layer][selected_element + 1]
		LayerList[selected_layer][selected_element + 1] = temp
		selected_element += 1
		updateElementIDs()
		$Layer2_Panels/PanelLeft/ElementTree.updateList()
		$Layer2_Panels/PanelLeft/ElementTree.updateSelected()
		status_message.displayMessage("Moved " + LayerList[selected_layer][selected_element].element_name + " up.")
		add_undo(move_element_down, "up", "none", "move_element", LayerList[selected_layer][selected_element])
	$Layer2_Panels/PanelLeft/ElementTree.ignore_selected = false

func move_element_down():
	pass
	$Layer2_Panels/PanelLeft/ElementTree.ignore_selected = true
	if selected_element > 0 and selected_element != -1:
		var temp = LayerList[selected_layer][selected_element]
		LayerList[selected_layer][selected_element] = LayerList[selected_layer][selected_element - 1]
		LayerList[selected_layer][selected_element - 1] = temp
		selected_element -= 1
		updateElementIDs()
		status_message.displayMessage("Moved " + LayerList[selected_layer][selected_element].element_name + " down.")
		add_undo(move_element_up, "down", "none", "move_element", LayerList[selected_layer][selected_element])
		$Layer2_Panels/PanelLeft/ElementTree.updateList()
		$Layer2_Panels/PanelLeft/ElementTree.updateSelected()
	$Layer2_Panels/PanelLeft/ElementTree.ignore_selected = false

func unpackArray(array): #How much bad code do you want in your project? The answer is yes.
	var newArray = []
	for item in array:
		if item is Array:
			for item2 in item:
				if item2 not in newArray:
					newArray.append(item2)
		else:
			newArray.append(item)
	return newArray


func get_hierarchy_order(element):
	var hierarchy : Array
	hierarchy.append(element.id)
	for child in element.get_children():
		if child is PuyoElement:
			hierarchy.append(child.id)
			hierarchy.append(get_hierarchy_order(child))
	hierarchy = unpackArray(hierarchy)
	return hierarchy

func fix_hierarchy(input_array):
	var new_array = input_array.duplicate()
	new_array.sort()
	
	var fixed_sorted = []
	
	if new_array.max() != new_array.size()-1:
		var cnt = new_array.min()
		for i in new_array:
			fixed_sorted.append(cnt)
			cnt += 1
		
		var output_array = input_array.duplicate()
		
		cnt = 0
		for i in output_array:
			output_array[cnt] = fixed_sorted[new_array.find(i)]
			cnt += 1
		
		return output_array
	else:
		return input_array


func change_layer(element, layer, is_child = false, hierarchy = []):
	selected_layer = layer
	if not is_child:
		hierarchy = get_hierarchy_order(element)
		
		#"floor" the hierarchy or whatever.
		while hierarchy.min() != LayerList[layer].size():
			if hierarchy.min() > LayerList[layer].size():
				var idx = 0
				for i in hierarchy:
					hierarchy[idx] -= 1
					idx += 1
			elif hierarchy.min() < LayerList[layer].size():
				var idx = 0
				for i in hierarchy:
					hierarchy[idx] += 1
					idx += 1
		
		hierarchy = fix_hierarchy(hierarchy)
		for item in hierarchy:
			LayerList[layer].append("")
	
	if element.layer != layer:
		#print(hierarchy)
		var index = hierarchy[0]
		#print(LayerList[layer])
		hierarchy.pop_at(0)
		LayerList[layer][index] = element
		LayerList[element.layer].pop_at(element.id)
		updateElementIDs()
		for child in element.get_children():
			if child is PuyoElement:
				change_layer(child, layer, true, hierarchy)
	if not is_child:
		selected_element = element.id
	
		for i in range(LayerList[layer].size() - 1, -1, -1):
			if typeof(LayerList[layer][i]) == TYPE_STRING:
				LayerList[layer].pop_at(i)
			
	
func move_element_back():
	$Layer2_Panels/PanelLeft/ElementTree.ignore_selected = true
	if selected_element > 0 and selected_element != -1:
		var temp = LayerList[selected_layer][selected_element]
		LayerList[selected_layer].pop_at(selected_element)
		LayerList[selected_layer].push_front(temp)
		selected_element = 0
		updateElementIDs()
		status_message.displayMessage("Moved " + LayerList[selected_layer][selected_element].element_name + " to back.")
		$Layer2_Panels/PanelLeft/ElementTree.updateList()
	$Layer2_Panels/PanelLeft/ElementTree.ignore_selected = false

func move_element_front():
	$Layer2_Panels/PanelLeft/ElementTree.ignore_selected = true
	if selected_element < LayerList[selected_layer].size() - 1 and selected_element != -1:
		var temp = LayerList[selected_layer][selected_element]
		LayerList[selected_layer].pop_at(selected_element)
		LayerList[selected_layer].push_back(temp)
		updateElementIDs()
		selected_element = temp.id
		status_message.displayMessage("Moved " + LayerList[selected_layer][selected_element].element_name + " to front.")
		$Layer2_Panels/PanelLeft/ElementTree.updateList()
	$Layer2_Panels/PanelLeft/ElementTree.ignore_selected = false

func get_platform(size, header = ""):
	if header == "DSIF" or header == "NGIF":
		for platform in platformSettings:
			if platformSettings[platform]["screen_size"][0] == size[0] and platformSettings[platform]["screen_size"][1] == size[1]:
				return platform
	else:
		for platform in platformSettings:
			if platformSettings[platform]["magic"] == header:
				return platform
	return "PSP"

func LoadData(data):
	
	resetVariables()
	var screen_size = [int(data["Misc. Info"]["Screen Size"].split("x")[0]), int(data["Misc. Info"]["Screen Size"].split("x")[1])]
	var platform = get_platform(screen_size, data["Misc. Info"]["Header Magic"])
	#print(platform)
	updateTargetPlatform(platform)
	
	
	for crop in data["Sprite Crops"]:
		var spritecrop = PuyoSprite.new()
		if crop["texture"] > textureList.size()-1:
			spritecrop.setOgTexture(load("res://Graphics/del.png"), crop["texture"])
		else:
			spritecrop.setOgTexture(textureList[crop["texture"]], crop["texture"])
		spritecrop.setCrop([crop["top_left_X"],
							crop["top_left_Y"],
							crop["bottom_right_X"],
							crop["bottom_right_Y"],
							])
		spriteCropList.append(spritecrop)
		#print(crop)
	
	var layer_idx = 0
	for layer in data["Element Banks"]:
		newLayer()
		var element_idx = 0
		selected_layer = layer_idx
		for element in layer:
			newElement(-1, false)
			var new_element = LayerList[layer_idx][element_idx]
			
#			if element["Sprite List"].size() > 0:
#				if element["Sprite List"][0] != -1:
#					new_element.sprite_rect.texture = spriteCropList[element["Sprite List"][0]]
			new_element.setName(element["Name"])
			var newspritelist = []
			for i in element["Sprite List"]:
				if i != -1:
					newspritelist.append(spriteCropList[i].texture)
			
			new_element.setSpriteList(newspritelist)
			new_element.setSpriteIndex(element["Default Settings"]["sprite_index"])
			
			var flip = element["Render Settings"]["unknown_1"]
			
			if flip == 0 or flip == 4 or flip == 8 or flip == 12:
				new_element.setFiltering(false)
			
			
			if flip == 4 or flip == 20 or flip == 36 or flip == 52:
				new_element.setFlipX(true)
			if flip == 8 or flip == 24 or flip == 40 or flip == 56:
				new_element.setFlipY(true)
			if flip == 12 or flip == 28 or flip == 44 or flip == 60:
				new_element.setFlipX(true)
				new_element.setFlipY(true)
			
			var inheritance_flags = intToBinaryString(int(element["Unknown Values"][1]))
			
#			if inheritance_flags[0] == "1":
#				inheritance_flags[8] = "1"
#				inheritance_flags[9] = "1"
#
#			if inheritance_flags[2] == "1":
#				inheritance_flags[10] = "1"
#				inheritance_flags[11] = "1"
			
			new_element.inherit_position = [bool(int(inheritance_flags[8])),bool(int(inheritance_flags[9]))]
			new_element.inherit_scale = [bool(int(inheritance_flags[10])),bool(int(inheritance_flags[11]))]
			new_element.inherit_angle = bool(int(inheritance_flags[1]))
			new_element.inherit_color = bool(int(inheritance_flags[3]))
			
			
			new_element.setSize(Vector2(-(element["2D Polygon"][0]*project_settings["screen_size"][0]) + element["2D Polygon"][6]*project_settings["screen_size"][0],
										-(element["2D Polygon"][1]*project_settings["screen_size"][1]) + element["2D Polygon"][7]*project_settings["screen_size"][1]))
			new_element.setPivot(Vector2(-element["2D Polygon"][0]*project_settings["screen_size"][0] , -element["2D Polygon"][1]*project_settings["screen_size"][1]))
			new_element.setColor(Color(element["Default Settings"]["rgba"]["red"]/255, element["Default Settings"]["rgba"]["green"]/255, element["Default Settings"]["rgba"]["blue"]/255, element["Default Settings"]["rgba"]["alpha"]/255))
			new_element.setColorTL(Color(element["Default Settings"]["rgba_tl"]["red"]/255, element["Default Settings"]["rgba_tl"]["green"]/255, element["Default Settings"]["rgba_tl"]["blue"]/255, element["Default Settings"]["rgba_tl"]["alpha"]/255))
			new_element.setColorTR(Color(element["Default Settings"]["rgba_tr"]["red"]/255, element["Default Settings"]["rgba_tr"]["green"]/255, element["Default Settings"]["rgba_tr"]["blue"]/255, element["Default Settings"]["rgba_tr"]["alpha"]/255))
			new_element.setColorBL(Color(element["Default Settings"]["rgba_bl"]["red"]/255, element["Default Settings"]["rgba_bl"]["green"]/255, element["Default Settings"]["rgba_bl"]["blue"]/255, element["Default Settings"]["rgba_bl"]["alpha"]/255))
			new_element.setColorBR(Color(element["Default Settings"]["rgba_br"]["red"]/255, element["Default Settings"]["rgba_br"]["green"]/255, element["Default Settings"]["rgba_br"]["blue"]/255, element["Default Settings"]["rgba_br"]["alpha"]/255))
			new_element.set3dDepth(element["Default Settings"]["3d_depth"])
			
			if "Name Index" in element:
				new_element.name_order = element["Name Index"]
			new_element.setRender(bool(element["Render Flag"]))
			new_element.setAddBlend(bool(element["Render Settings"]["dodge_blend"]))
			new_element.update()
			element_idx += 1
			
		layer_idx += 1
	
	layer_idx = 0
	for layer in data["Element Banks"]:
		var element_idx = 0
		for element in layer:
			var puyoElement = LayerList[layer_idx][element_idx]
			if element["Parent"] != -1:
				puyoElement.reparent(LayerList[layer_idx][element["Parent"]])
			puyoElement.setPosition(Vector2(element["Default Settings"]["posx"]*project_settings["screen_size"][0],
											element["Default Settings"]["posy"]*project_settings["screen_size"][1]))
			
			puyoElement.setScale(Vector2(element["Default Settings"]["scalex"], element["Default Settings"]["scaley"]))
			
			puyoElement.setAngle(-element["Default Settings"]["angle"])
			puyoElement.setVisible(not bool(element["Default Settings"]["hide"]))
			
			puyoElement.skew = 0
			element_idx+= 1
		layer_idx+= 1
	
	
	for jsonAnim in data["Animations"]:
		animation_max_time = data["Animations"][0]["Length Range"][1]
		animationList.append({"name" : jsonAnim["Name"], 
								"length" : jsonAnim["Length Range"][1]})
		layer_idx = 0
		for layer in jsonAnim["Element Banks"]:
			var element_idx = 0
			for element_anim in layer:
				var element = LayerList[layer_idx][element_idx]
				#print(layer_idx, " - ", element_idx)
				#print(element_anim)
				element.animation_list.append(element_anim["Animations"])
				
				element_idx += 1
			
			layer_idx += 1
	$Layer2_Panels/PanelLeft/ElementTree.updateList()
	$Layer2_Panels/PanelLeft/ElementTree.updateSelected()
	undoHistory = []
	$Layer2_SpriteEditor_Panels/PanelLeft/ItemList.selected = 0
	$Layer2_SpriteEditor_Panels/PanelLeft/ItemList.update()
	$Layer2_SpriteEditor_Canvas/Control._on_zoom_label_pressed()
	$Layer2_Panels/PanelBottom.updateAnimList()
	#$Layer2_Panels/PanelLeft/ElementTree.layerCollapse(2)
	#$Layer2_Panels/PanelLeft/ElementTree.nameCollapse("null")
	
	

func intToBinaryString(number: int) -> String:
	var binaryString = ""
	var quotient = number

	while quotient > 0:
		var remainder = quotient % 2
		binaryString = str(remainder) + binaryString
		@warning_ignore("integer_division")
		quotient = quotient / 2
	
	if binaryString.length() < 15:
		while binaryString.length() < 15:
			binaryString += "0"
			
	var final_string = ""
	for i in binaryString:
		final_string = i + final_string
	
	return final_string

func newAnimation(anim_name = "defaultAnim", length = 60):
	add_undo({"name" : anim_name, "length" : length}, "none", "none", "none", "animation_creation", "none")
	animationList.append({"name" : anim_name, "length" : length})

func newSpriteCrop():
	if textureList.size() != 0:
		var spriteCrop = PuyoSprite.new()
		spriteCrop.setOgTexture(textureList[$Layer2_SpriteEditor_Canvas/SpinBox.value], $Layer2_SpriteEditor_Canvas/SpinBox.value)
		
#		if $Layer2_SpriteEditor_Panels/PanelLeft/ItemList.selected != -1:
#			spriteCrop.setCrop(spriteCropList[$Layer2_SpriteEditor_Panels/PanelLeft/ItemList.selected].cropping_positions)
#		else:
#
		spriteCrop.setCrop([0.0,0.0,1.0,1.0])
		spriteCropList.append(spriteCrop)
	else:
		$Layer3_Popups/AcceptDialog.dialog_text = "There are no images loaded.\n\nSet a directory that contains PNG files to add a new sprite."
		$Layer3_Popups/AcceptDialog.popup()
		



func _on_texture_path_btn_pressed():
	startTextureDirTask()

func updatePathLabel():
	if project_settings["texture_dir"] != "":
		
		$Layer2_SpriteEditor_Panels/PanelLeft/texture_path.text = project_settings["texture_dir"]
	else:
		$Layer2_SpriteEditor_Panels/PanelLeft/texture_path.text = "No texture path set."
	for layer in LayerList:
		for element in layer:
			element.update()

func addAnimation():
	animationList.append({"name": "new_animation", "length" : 60})
	
	for layer in LayerList:
		for element in layer:
			element.animation_list.append([])
	
	animation_idx = animationList.size()-1
	$Layer2_Panels/PanelBottom.updateAnimList()



func _on_save_dialog_canceled():
	savepathTaskFinished.emit()


func duplicate_element(elem = false, parent = false):
	if selected_layer != -1 and selected_element != -1:
		var element = LayerList[selected_layer][selected_element]
		
		if elem:
			element = elem
		
		var duplicatedElement = PuyoElement.new()
		
		if parent:
			parent.add_child(duplicatedElement)
		else:
			element.get_parent().add_child(duplicatedElement)
		
		for child in element.get_children():
			if child is PuyoElement:
				duplicate_element(child, duplicatedElement)
		
		
		duplicatedElement.setRender(element.render)
		duplicatedElement.setAddBlend(element.add_blend)
		duplicatedElement.setHideEditor(element.hide_editor)
		duplicatedElement.setFlipX(element.flipX)
		duplicatedElement.setFlipY(element.flipY)
		duplicatedElement.setInheritPosition(element.inherit_position)
		duplicatedElement.setInheritScale(element.inherit_scale)
		duplicatedElement.setInheritAngle(element.inherit_angle)
		duplicatedElement.setInheritColor(element.inherit_color)
		duplicatedElement.setName(ensure_unique_element_name(element.element_name))
		duplicatedElement.setSize(element.element_size)
		duplicatedElement.setPivot(element.pivot_point)
		duplicatedElement.setSpriteList(element.sprite_list.duplicate())
		duplicatedElement.setVisible(element.visibility)
		duplicatedElement.setPosition(Vector2(element.positionX, element.positionY))
		duplicatedElement.setAngle(element.angle)
		duplicatedElement.setScalex(element.scalex)
		duplicatedElement.setScaley(element.scaley)
		duplicatedElement.setSpriteIndex(element.sprite_index)
		duplicatedElement.setColor(element.color)
		duplicatedElement.setColorTL(element.color_tl)
		duplicatedElement.setColorBL(element.color_bl)
		duplicatedElement.setColorTR(element.color_tr)
		duplicatedElement.setColorBR(element.color_br)
		duplicatedElement.depth = element.depth
		duplicatedElement.animation_list = element.animation_list.duplicate(true)
		duplicatedElement.defaultSettings = element.defaultSettings.duplicate(true)
		
		LayerList[selected_layer].insert(element.id+1, duplicatedElement)
		updateElementIDs()
		selected_element = duplicatedElement.id
		$Layer2_Panels/PanelLeft/ElementTree.updateList()
		element_list.updateSelected()
		
		add_undo(duplicatedElement.get_parent().add_child, duplicatedElement.get_parent, duplicatedElement, "creation", duplicatedElement,false)

func backupSave():
	var save_backup = false
	for layer in LayerList:
		for element in layer:
			save_backup = true
	
	if spriteCropList != []:
		save_backup = true
	if save_backup:
		saveAt(OS.get_user_data_dir() + "/backup.json", true)

func toggle_fullscreen():
	fullscreen = not fullscreen
	if fullscreen:
		$Layer1_Canvas/CanvasViewport/LockToGrid.button_pressed = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		$Layer1_Canvas/CanvasViewport/status_message.position = Vector2(-100,-100)
		$Layer1_Canvas/CanvasViewport/maximize_view.position = Vector2(-100,-100)
		$Layer1_Canvas/CanvasViewport/LockToGrid.position = Vector2(-100,-100)
		$Layer1_Canvas/CanvasViewport/zoomLabel.position = Vector2(-100,-100)
		$Layer1_Canvas/CanvasViewport/cursorPosLabel.position = Vector2(-100,-100)
		$Layer2_Panels.visible = false
		$Layer1_Canvas/CanvasViewport.fillZoom()
		
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		$Layer1_Canvas/CanvasViewport/status_message.position = Vector2(-100,-100)
		$Layer1_Canvas/CanvasViewport/maximize_view.position = Vector2(56, 8)
		$Layer1_Canvas/CanvasViewport/LockToGrid.position = Vector2(-100,8)
		$Layer1_Canvas/CanvasViewport/zoomLabel.position = Vector2(8,8)
		$Layer2_Panels.visible = true
		$Layer1_Canvas/CanvasViewport.fillZoom()
	windowResize()

func delLayer(layer_idx):
	#print("why")
	LayerList.pop_at(layer_idx)
	add_undo(layer_idx, selected_layer, "", "layerDel", "")
	if selected_layer != 0 or LayerList.size() == 0:
		selected_layer-=1
	selected_element = -1
	$Layer2_Panels/PanelLeft/ElementTree.updateList()
	
func updateElementsettings():
	for layer in LayerList:
		for element in layer:
			element.restoreDefaults()
	
	animate()

func delAnimation(undo = true):
	#print("???")
	var restore_animation = []
	var layer_idx = 0
	for layer in LayerList:
		restore_animation.append([])
		for element in layer:
			restore_animation[layer_idx].append(element.animation_list[animation_idx].duplicate(true))
			element.animation_list.pop_at(animation_idx)
		layer_idx+= 1
	var animation_settings = animationList[animation_idx].duplicate(true)
	add_undo(restore_animation, animation_idx, animation_settings, "delAnim", "", undo)
	animationList.pop_at(animation_idx)
	if animation_idx != 0:
		animation_idx-= 1
	$Layer2_Panels/PanelBottom.updateAnimList()
	$Layer2_Panels/PanelBottom/AnimationList.select(animation_idx)

func popupUpdate(version):
	$Layer3_Popups/Update.dialog_text = "New version found: " + version + ". \nDo you wish to download it?"
	$Layer3_Popups/Update.popup()
	


func _on_update_confirmed():
	OS.shell_open("https://github.com/ArMM1998/PuyoEdit/releases")

func clipboardElement():
	pass
	


func _on_btn_autosave_pressed():
	user_settings["autobackup"] = $Layer3_Popups/Settings/Node2D/btn_autosave.button_pressed
	autobackup = $Layer3_Popups/Settings/Node2D/btn_autosave.button_pressed


func _on_autosave_interval_changed(_dummy):
	user_settings["backuptimer"] = $Layer3_Popups/Settings/Node2D/autosave_interval.value * 60
	backupTimeLimit = $Layer3_Popups/Settings/Node2D/autosave_interval.value * 60


func _on_btn_check_updates_pressed():
	user_settings["auto_update"] = $Layer3_Popups/Settings/Node2D/btn_check_updates.button_pressed
