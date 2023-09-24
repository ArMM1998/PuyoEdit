extends Panel
@onready var color = $ScrollContainer/Control/color
@onready var color_tl = $ScrollContainer/Control/color_tl
@onready var color_tr = $ScrollContainer/Control/color_tr
@onready var color_bl = $ScrollContainer/Control/color_bl
@onready var color_br = $ScrollContainer/Control/color_br


# Called when the node enters the scene tree for the first time.
func _ready():
	$ScrollContainer/Control/popupmenuMatchSize.index_pressed.connect(matchSizeScaled)
	$ScrollContainer/Control/popupmenuMatchSize.add_item("4x")
	$ScrollContainer/Control/popupmenuMatchSize.add_item("2x")
	$ScrollContainer/Control/popupmenuMatchSize.add_item("0.5x")
	$ScrollContainer/Control/popupmenuMatchSize.add_item("0.25x")
	$ScrollContainer/Control/PopupMenu.index_pressed.connect(SpriteSelected)
	$ScrollContainer/Control/elementName.text_changed.connect(updateName)
	$ScrollContainer/Control/elementName.text_submitted.connect(releaseFocus)
	
	$ScrollContainer/Control/render.toggled.connect(updateRender)
	$ScrollContainer/Control/additive.toggled.connect(updateAddBlend)
	
	$ScrollContainer/Control/width.value_changed.connect(updateSize)
	$ScrollContainer/Control/height.value_changed.connect(updateSize)
	
	$ScrollContainer/Control/pivotX.value_changed.connect(updatePivot)
	$ScrollContainer/Control/pivotY.value_changed.connect(updatePivot)
	
	$ScrollContainer/Control/flipx.toggled.connect(updateFlipX)
	$ScrollContainer/Control/flipy.toggled.connect(updateFlipY)
	
	$ScrollContainer/Control/visib.toggled.connect(updateVisib)

	$ScrollContainer/Control/posx.value_changed.connect(updatePos)
	$ScrollContainer/Control/posy.value_changed.connect(updatePos)
	
	$ScrollContainer/Control/scalex.value_changed.connect(updateScale)
	$ScrollContainer/Control/scaley.value_changed.connect(updateScale)
	
	$ScrollContainer/Control/angle.value_changed.connect(updateAngle)
	
	$ScrollContainer/Control/color.color_changed.connect(updateColor)
	
	$ScrollContainer/Control/color_tl.color_changed.connect(updateColorTL)
	$ScrollContainer/Control/color_tr.color_changed.connect(updateColorTR)
	$ScrollContainer/Control/color_bl.color_changed.connect(updateColorBL)
	$ScrollContainer/Control/color_br.color_changed.connect(updateColorBR)
	
	$ScrollContainer/Control/matchSize.pressed.connect(matchSize)
	$ScrollContainer/Control/matchSize.gui_input.connect(sizegui)
	$ScrollContainer/Control/centerPivot.pressed.connect(centerPivot)
	
	$ScrollContainer/Control/spritelist.item_clicked.connect(itemClicked)
	
	$ScrollContainer/Control/depth.value_changed.connect(updateDepth)
	$ScrollContainer/Control/HSlider.value_changed.connect(updateDepth)
	
var selected = -1
var changing = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	var is_3ds = owner.project_settings["platform"].find("3DS") != -1
	
	$ScrollContainer/Control/HSlider.visible = is_3ds
	$ScrollContainer/Control/Label13.visible = is_3ds
	$ScrollContainer/Control/Sprite2D.visible = is_3ds
	$ScrollContainer/Control/depth.visible = is_3ds
	
	if owner.selected_element != -1:
		$ScrollContainer.visible = true
	else:
		$ScrollContainer.visible = false
	
	
	if selected != owner.selected_element:
		update()
	
	selected = owner.selected_element

var updating = false


func _input(event):
	if event is InputEventMouseButton and not event.pressed:
		changing = false
#	if event is InputEventKey and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
#		releaseFocus(0)
#	if owner.timeline.has_focus() or owner.canvas_viewport.has_focus():
#		update()
	
func update():
	updating = true
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element] 
		$ScrollContainer/Control/depth.value = element.depth
		$ScrollContainer/Control/HSlider.value = element.depth
		$ScrollContainer/Control/elementName.text = element.element_name
		$ScrollContainer/Control/render.button_pressed = element.render
		$ScrollContainer/Control/additive.button_pressed = element.add_blend
		
		$ScrollContainer/Control/width.value = element.element_size.x
		$ScrollContainer/Control/height.value = element.element_size.y
		
		$ScrollContainer/Control/pivotX.value = element.pivot_point.x
		$ScrollContainer/Control/pivotY.value = element.pivot_point.y
		
		$ScrollContainer/Control/flipx.button_pressed = element.flipX
		$ScrollContainer/Control/flipy.button_pressed = element.flipY
		

		$ScrollContainer/Control/spritelist.clear()
		
		for i in element.sprite_list:
			$ScrollContainer/Control/spritelist.add_icon_item(i)
		$ScrollContainer/Control/spritelist.add_icon_item(load("res://Graphics/add_sprite.png"))
		if element.sprite_index != -1 and element.sprite_list.size() != 0:
			$ScrollContainer/Control/spritelist.select(element.sprite_index)
		
		$ScrollContainer/Control/visib.button_pressed = element.visibility
		
		$ScrollContainer/Control/posx.value = element.positionX
		$ScrollContainer/Control/posy.value = element.positionY
		
		$ScrollContainer/Control/scalex.value = element.scalex
		$ScrollContainer/Control/scaley.value = element.scaley
		
		$ScrollContainer/Control/angle.value = element.angle
		
		$ScrollContainer/Control/color.color = element.color
		
		$ScrollContainer/Control/color_tl.color = element.color_tl
		$ScrollContainer/Control/color_tr.color = element.color_tr
		$ScrollContainer/Control/color_bl.color = element.color_bl
		$ScrollContainer/Control/color_br.color = element.color_br
		
	updating = false

func updateName(string):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		
		if not changing:
			owner.add_undo(element.setName, element.getName, element.getName(), "value", element)
		changing = true
		
		element.setName(string.replace(" ", "_"))
		$"../PanelLeft/ElementTree".updateList()
		$"../PanelLeft/ElementTree".updateSelected()
		$ScrollContainer/Control/elementName.grab_focus()

func updateRender(value):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		owner.add_undo(element.setRender, element.getRender, element.getRender(), "value", element)
		element.setRender(value)

func updateAddBlend(value):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		owner.add_undo(element.setAddBlend, element.getAddBlend, element.getAddBlend(), "value", element)
		element.setAddBlend(value)

func updateSize(_value):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if not changing:
			owner.add_undo(element.setSize, element.getSize, element.getSize(), "value", element)
		changing = true
		
		element.setSize(Vector2($ScrollContainer/Control/width.value, $ScrollContainer/Control/height.value))

func updatePivot(_value):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if not changing:
			owner.add_undo(element.setPivot, element.getPivot, element.getPivot(), "value", element)
		
		changing = true
		
		element.setPivot(Vector2($ScrollContainer/Control/pivotX.value, $ScrollContainer/Control/pivotY.value))

func updateFlipX(value):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		owner.add_undo(element.setFlipX, element.getFlipX, element.getFlipX(), "value", element) 
		element.setFlipX(value)

func updateFlipY(value):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		owner.add_undo(element.setFlipY, element.getFlipY, element.getFlipY(), "value", element)
		element.setFlipY(value)

func updateVisib(value):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		owner.add_undo(element.setVisible, element.getVisible, element.getVisible(), "value", element)
		owner.canvas_viewport.checkKeyframeSaving(element, int(not value), "hide")
		element.setVisible(value)
		

func updatePos(_value):
	if not updating and not owner.timeline.has_focus():
		releaseFocus(0)
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if not changing:
			owner.add_undo(element.setPosition, element.getPosition, element.getPosition(), "value", element) 
		
		
		changing = true
		
		owner.canvas_viewport.checkKeyframeSaving(element, $ScrollContainer/Control/posx.value / owner.project_settings["screen_size"][0], "posx")
		owner.canvas_viewport.checkKeyframeSaving(element, $ScrollContainer/Control/posy.value / owner.project_settings["screen_size"][1], "posy")
		
		element.setPosition(Vector2($ScrollContainer/Control/posx.value, $ScrollContainer/Control/posy.value))

func updateScale(_value):
	if not updating and not owner.timeline.has_focus():
		releaseFocus(0)
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if not changing:
			owner.add_undo(element.setScale, element.getScale, element.getScale(), "value", element)
		
		changing = true
		
		owner.canvas_viewport.checkKeyframeSaving(element, $ScrollContainer/Control/scalex.value, "scalex")
		owner.canvas_viewport.checkKeyframeSaving(element, $ScrollContainer/Control/scaley.value, "scaley")
		
		element.setScale(Vector2($ScrollContainer/Control/scalex.value, $ScrollContainer/Control/scaley.value))

func updateAngle(value):
	if not updating and not owner.timeline.has_focus():
		releaseFocus(0)
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if not changing:
			owner.add_undo(element.setAngle, element.getAngle, element.getAngle(), "value", element)
		
		changing = true
		owner.canvas_viewport.checkKeyframeSaving(element, -value, "angle")
		
		element.setAngle(value)
	
func updateColor(value):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		
		if not changing:
			owner.add_undo(element.setColor, element.getColor, element.getColor(), "value", element)
		changing = true
		var data  = {"red": value.r8,
						"green": value.g8,
						"blue": value.b8,
						"alpha": value.a8}
		
		owner.canvas_viewport.checkKeyframeSaving(element, data, "rgba")
		
		element.setColor(value)

func updateColorTL(value):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if not changing:
			owner.add_undo(element.setColorTL, element.getColorTL, element.getColorTL(), "value", element)
		
		changing = true
		
		
		var data  = {"red": value.r8,
						"green": value.g8,
						"blue": value.b8,
						"alpha": value.a8}
		owner.canvas_viewport.checkKeyframeSaving(element, data, "rgba_tl")
		
		element.setColorTL(value)

func updateColorBL(value):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if not changing:
			owner.add_undo(element.setColorBL, element.getColorBL, element.getColorBL(), "value", element)
		changing = true
		var data  = {"red": value.r8,
						"green": value.g8,
						"blue": value.b8,
						"alpha": value.a8}
		owner.canvas_viewport.checkKeyframeSaving(element, data, "rgba_bl")
		
		element.setColorBL(value)

func updateColorTR(value):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if not changing:
			owner.add_undo(element.setColorTR, element.getColorTR, element.getColorTR(), "value", element)
		changing = true
		var data = {"red": value.r8,
						"green": value.g8,
						"blue": value.b8,
						"alpha": value.a8}
		owner.canvas_viewport.checkKeyframeSaving(element, data, "rgba_tr")
		
		element.setColorTR(value)

func updateColorBR(value):
	if not updating:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		if not changing:
			owner.add_undo(element.setColorBR, element.getColorBR, element.getColorBR(), "value", element)
		changing = true
		var data  = {"red": value.r8,
						"green": value.g8,
						"blue": value.b8,
						"alpha": value.a8}
		owner.canvas_viewport.checkKeyframeSaving(element, data, "rgba_br")
		
		element.setColorBR(value)

func matchSize():
	var element = owner.LayerList[owner.selected_layer][owner.selected_element]
	owner.add_undo(element.setSize, element.getSize, element.getSize(), "value", element)
	var w = 16
	var h = 16
	
	if element.sprite_list.size() != 0:
		if element.sprite_index == -1 or element.sprite_index > element.sprite_list.size():
			w = 16
			h = 16
		else:
			w = element.sprite_list[element.sprite_index].region.size.x
			h = element.sprite_list[element.sprite_index].region.size.y
	
	element.setSize(Vector2(w,h))
	update()

func matchSizeScaled(index):
	
	var size_scale = 1
	
	if index == 0:
		size_scale = 4
	elif index == 1:
		size_scale = 2
	elif index == 2:
		size_scale = 0.5
	elif index == 3:
		size_scale = 0.25
	
	var element = owner.LayerList[owner.selected_layer][owner.selected_element]
	owner.add_undo(element.setSize, element.getSize, element.getSize(), "value", element)
	var w = 16
	var h = 16
	
	if element.sprite_list.size() != 0:
		if element.sprite_index == -1 or element.sprite_index > element.sprite_list.size():
			w = 16
			h = 16
		else:
			w = element.sprite_list[element.sprite_index].region.size.x * size_scale
			h = element.sprite_list[element.sprite_index].region.size.y * size_scale
	
	element.setSize(Vector2(w,h))
	update()
	
	
func centerPivot():
	var element = owner.LayerList[owner.selected_layer][owner.selected_element]
	owner.add_undo(element.setPivot, element.getPivot, element.getPivot(), "value", element)
	var newpivot = element.element_size/2
	newpivot.x = round(newpivot.x)
	newpivot.y = round(newpivot.y)
	element.setPivot(newpivot)
	update()
	
var newSprite = false

func itemClicked(index:int, _at_position : Vector2, mouse_btn):
	var element = owner.LayerList[owner.selected_layer][owner.selected_element]
	owner.add_undo(element.setSpriteIndex, element.getSpriteIndex, element.getSpriteIndex(), "value", element)
	if element.sprite_list.size() > index:
		newSprite = false
		if mouse_btn == 1:
			element.setSpriteIndex(index)
			owner.canvas_viewport.checkKeyframeSaving(element, index, "sprite_index")
			
		elif mouse_btn == 2:
			element.setSpriteIndex(index)
			owner.canvas_viewport.checkKeyframeSaving(element, index, "sprite_index")
			self.update()
			showSpriteList(true)
	else:
		newSprite = true
		showSpriteList()


func showSpriteList(del = false):
	$ScrollContainer/Control/PopupMenu.position = get_global_mouse_position()
	$ScrollContainer/Control/PopupMenu.clear()
	$ScrollContainer/Control/PopupMenu.size = Vector2(0,0)
	
	
	for sprite in owner.spriteCropList:
		$ScrollContainer/Control/PopupMenu.add_icon_item(resizeTexture(sprite,80), "")
	if del:
		$ScrollContainer/Control/PopupMenu.add_icon_item(load("res://Graphics/del.png"), "")
	
	$ScrollContainer/Control/PopupMenu.popup()


func resizeTexture(sprite, max_size):

	var resized_img = sprite.texture.get_atlas().duplicate()
	
	var width = (sprite.cropping_positions[2] - sprite.cropping_positions[0])*(resized_img.get_size().x)
	var height = (sprite.cropping_positions[3] - sprite.cropping_positions[1])*(resized_img.get_size().y)

	#print(width, " ", height)
	
	var max_dimension = max(width, height)
	var scale_factor = 1.0
	if max_dimension > max_size:
		scale_factor = float(max_size) / float(max_dimension)
	if scale_factor > 1.0:
		scale_factor = 1.0
	
	resized_img.set_size_override(resized_img.get_size()*scale_factor)
	
	var cropped = AtlasTexture.new()
	
	cropped.atlas = resized_img
	cropped.region = Rect2(sprite.texture.region.position*scale_factor, sprite.texture.region.size*scale_factor)
	
	
	return cropped


func SpriteSelected(idx):
	var element = owner.LayerList[owner.selected_layer][owner.selected_element]
	owner.add_undo(element.setSpriteList, element.getSpriteList, element.sprite_list.duplicate(true), "value", element)
	if newSprite:
		element.sprite_list.append(owner.spriteCropList[idx].texture)
		element.setSpriteIndex(element.sprite_list.size()-1)
	else:
		if idx <= owner.spriteCropList.size()-1:
			element.sprite_list[element.sprite_index] = owner.spriteCropList[idx].texture
			element.update()
		else:
			element.sprite_list.remove_at(element.sprite_index)
			element.setSpriteIndex(element.sprite_index-1)
		
		if element.sprite_list.size() > 0 and element.sprite_index < 0:
			element.setSpriteIndex(0)
		
	self.update()

func releaseFocus(_dummy):
	owner.canvas_viewport.grab_focus()

func sizegui(event):
	if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		$ScrollContainer/Control/popupmenuMatchSize.position = get_global_mouse_position()
		$ScrollContainer/Control/popupmenuMatchSize.popup()

func updateDepth(dummy):
	var element = owner.LayerList[owner.selected_layer][owner.selected_element]
	
	if $ScrollContainer/Control/depth.value == int(dummy):
		element.set3dDepth($ScrollContainer/Control/depth.value)
		
		$ScrollContainer/Control/HSlider.value = $ScrollContainer/Control/depth.value
	else:
		element.set3dDepth($ScrollContainer/Control/HSlider.value)
		$ScrollContainer/Control/depth.value = $ScrollContainer/Control/HSlider.value
