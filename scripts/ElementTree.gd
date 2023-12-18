extends Tree


@onready var scene = owner.get_parent().get_parent()

var pressed = false
var ignore_selected = false
@onready var tree = self
var root
var itemList = []
var collapsedlist = []

# Called when the node enters the scene tree for the first time.
func _ready():
	root = tree.create_item()
	self.set_column_title(0,"Element Name")
	self.set_column_title(1,"ID")
	self.set_column_expand(0, true)
	self.set_column_custom_minimum_width(0, 7)
	tree.hide_root = true
	updateList()
	pass # Replace with function body.
	
func updateList():
	getcollapsed()
	itemList = []
	var layerList = scene.LayerList
	tree.clear()
	root = tree.create_item()
	var layer_idx = 0
	for layer in layerList:
		var layerItem = tree.create_item()
		itemList.append(layerItem)
		layerItem.set_text(0, "Layer " + str(layer_idx))
		for obj in layer:
			if obj is PuyoElement:
				if not obj.get_parent() is PuyoElement:
					var item = tree.create_item(layerItem)
					item.set_text(0 ,obj.element_name)
					item.set_text(1, str(obj.id))
					addChildrenToTree(obj, item)
					itemList.append(item)
		layer_idx+= 1
	
	if collapsedlist != []:
		for item in itemList:
			for collapsedItem in collapsedlist:
				if collapsedItem[0] == item.get_text(0) and collapsedItem[1] == item.get_text(1) and collapsedItem[2] == int(getLayerIndex(item)):
					item.set_collapsed(true)

func addChildrenToTree(node, parentItem):
	for child in node.get_children():
		if child is PuyoElement:
			var item = tree.create_item(parentItem)
			item.set_text(0, child.element_name)
			item.set_text(1, str(child.id))
			if child.get_child_count() > 9:
				addChildrenToTree(child, item)
			itemList.append(item)

			
func updateSelected():
	ignore_selected = true
	#var focus = scene.canvas_viewport.has_focus
	self.grab_focus()
	if scene.selected_element != -1:
		for item in itemList:
			#print(int(item.get_text(1)))
			if int(item.get_text(1)) == scene.selected_element and getLayerIndex(item) == scene.selected_layer:
				self.set_selected(item, 0)
				self.scroll_to_item(item, true)
	else:
		for item in itemList:
			if item.get_text(0).find("Layer ") != -1 and int(item.get_text(0).split(" ")[1]) == scene.selected_layer:
				self.set_selected(item, 0)

	ignore_selected = false
	
func _on_item_selected():
	if not ignore_selected:
		if self.get_selected().get_text(0).find("Layer") != -1:
			scene.selected_element = -1
			scene.selected_layer = int(self.get_selected().get_text(0).split(" ")[1])
		else:
			scene.selected_element = int(self.get_selected().get_text(1))
			scene.selected_layer = getLayerIndex(self.get_selected())
		get_parent().get_parent().get_parent().panel_right.update()
		
#Take an item from the tree and determine which "layer" it's on
func getLayerIndex(item):
	if item.get_text(0).find("Layer ") != -1:
		return int(item.get_text(0).split(" ")[1])
		
	var parent = item.get_parent()
	if parent == null:
		return -100
	if parent.get_text(0).find("Layer ") != -1:
		return int(parent.get_text(0).split(" ")[1])
	else:
		return getLayerIndex(parent)

var mouse_state = "none"
var dropping_at = -100
var element_id = -100
var layer_id = -100

var draggingRange = 8
var startingMousePos : Vector2 

var holdingCtrl = false


func _on_gui_input(event):
	
	if self.has_focus():
		if event is InputEventKey and event.keycode == KEY_F2 and scene.selected_element != -1:
			scene.panel_right.element_name.grab_focus()
			scene.panel_right.element_name.select_all()
		if event is InputEventMouseButton and (event.button_index == 1 or event.button_index == 2):
			if event.pressed:
				mouse_state = "clicked"
				startingMousePos = event.position
			else:
				mouse_state = "none"
				if dropping_at != -100 and element_id != -100 and layer_id != -100:
					#print(dropping_at, " ", element_id, " ", layer_id)
					drag_and_drop(element_id, layer_id)
					dropping_at = -100
					element_id = -100
					layer_id = -100
				
		if event is InputEventMouseMotion and mouse_state == "clicked" and ((abs(event.position.x - startingMousePos.x) > draggingRange or abs(event.position.y - startingMousePos.y) > draggingRange) and get_item_at_position(event.position) != self.get_selected()):
			mouse_state = "dragging"
			
		if event is InputEventMouseMotion and mouse_state == "dragging" and self.get_selected():
			self.drop_mode_flags = DROP_MODE_ON_ITEM
			
			if get_item_at_position(event.position) != null:
				if event.position.y < 128:
					var item_to_scroll = get_item_at_position(event.position).get_prev_in_tree()
					if item_to_scroll != null:
						self.scroll_to_item(item_to_scroll)
				elif event.position.y > self.size.y - 32:
					var item_to_scroll = get_item_at_position(event.position).get_next_in_tree()
					if item_to_scroll != null:
						self.scroll_to_item(item_to_scroll)
			
			
			if self.get_selected().get_text(0).find("Layer ") == -1:
				if self.drop_mode_flags == DROP_MODE_ON_ITEM:
					if get_item_at_position(event.position) != null:
						dropping_at = get_drop_section_at_position(event.position)
						element_id = int(get_item_at_position(event.position).get_text(1))
						if get_item_at_position(event.position).get_text(0).find("Layer") != -1:
							element_id = -1
						layer_id = int(getLayerIndex(get_item_at_position(event.position)))
				else:
					print("between")
		else:
			self.drop_mode_flags = 0
	
	else:
		holdingCtrl = false
	
func drag_and_drop(id, layer):
	var selected_element = scene.LayerList[scene.selected_layer][scene.selected_element]
	if id == -1:
		scene.status_message.displayMessage(selected_element.element_name + " moved to Layer " + str(layer_id) + ".")
		scene.add_undo(selected_element.get_parent(), selected_element, "none", "hierarchy", scene.LayerList.duplicate(true))
		scene.change_layer(selected_element, layer)
		selected_element.reparent(scene.puyo_canvas)
		selected_element.update()
		updateList()
		updateSelected()
	elif id <= scene.LayerList[layer].size()-1:
		var dropped_at
		if id != -1:
			dropped_at = scene.LayerList[layer][id]
		else:
			dropped_at = false
		
		
		if dropped_at:
			# Drag element into it's own parent, so ignore it?
			if dropped_at == selected_element.get_parent():
				return
				
			# Drag an element into another element (that isn't it's parent or an ancestor)
			elif not selected_element.is_ancestor_of(dropped_at) and not (dropped_at == selected_element):
				scene.status_message.displayMessage(selected_element.element_name + " reparented.")
				scene.add_undo(selected_element.get_parent(), selected_element, "none", "hierarchy", scene.LayerList.duplicate(true))
				if selected_element.layer != dropped_at.layer:
					scene.change_layer(selected_element, layer)
				selected_element.reparent(dropped_at)
				selected_element.update()
				updateList()
				updateSelected()
		
		else:
			if scene.selected_layer != layer:
				#print("what")
				#Layer change only.
				scene.status_message.displayMessage(selected_element.element_name + " moved to Layer " + str(layer_id) + ".")
				scene.add_undo(selected_element.get_parent(), selected_element, "none", "hierarchy", scene.LayerList.duplicate(true))
				scene.change_layer(selected_element, layer)
				selected_element.reparent(scene.puyo_canvas)
				selected_element.update()
				updateList()
				updateSelected()

func getcollapsed():
	collapsedlist = []
	for item in itemList:
		if item.collapsed:
			collapsedlist.append([item.get_text(0), item.get_text(1), int(getLayerIndex(item))])


func depthCollapse(item, depth):
	if depth == 0:
		item.set_collapsed(true)
	else:
		for child in item.get_children():
			depthCollapse(child, depth-1)

func nameCollapse(string):
	for item in itemList:
		if item.get_text(0).to_lower().find(string) != -1:
			item.set_collapsed(true)

func layerCollapse(depth):
	for item in itemList:
		if item.get_text(0).find("Layer ") != -1:
			for child in item.get_children():
				depthCollapse(child, depth-1)
