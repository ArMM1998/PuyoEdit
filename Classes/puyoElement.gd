extends Node2D
class_name PuyoElement

var selected = false
var id
var layer
var null_texture = load("res://Graphics/blank.png")

var render = true : set = setRender
var add_blend = false : set = setAddBlend
var hide_editor = false : set = setHideEditor

var flipX = false : set = setFlipX
var flipY = false : set = setFlipY

#var sprite_index_list : set = setSpriteIndexList

var inherit_position = [true, true] : set = setInheritPosition
var inherit_scale = [true, true] : set = setInheritScale
var inherit_angle = true : set = setInheritAngle
var inherit_color = true : set = setInheritColor

var element_name = "NewElement" : set = setName
var element_size = Vector2(16,16) : set = setSize
var pivot_point = Vector2(8,8) : set = setPivot

var visibility = true : set = setVisible
var positionX = 0 : set = setPositionX
var positionY = 0 : set = setPositionY
var angle = 0 : set = setAngle
var scalex = 1 : set = setScalex
var scaley = 1 : set = setScaley
var sprite_index = 0 : set = setSpriteIndex
var color = Color(1,1,1,1) : set = setColor
var color_tl = Color(1,1,1,1) : set = setColorTL
var color_bl = Color(1,1,1,1) : set = setColorBL
var color_tr = Color(1,1,1,1) : set = setColorTR
var color_br = Color(1,1,1,1) : set = setColorBR
var mixed_color
var sprite_list = [] : set = setSpriteList
var depth = 0 : set = set3dDepth
var name_order = -2424


var defaultSettings = {"visibility" : true,
						"positionX" : 0.0,
						"positionY" : 0.0,
						"angle" : 0.0,
						"scalex" : 1,
						"scaley" : 1,
						"sprite_index" : 0,
						"color" : Color(1,1,1,1),
						"color_tl" : Color(1,1,1,1),
						"color_bl" : Color(1,1,1,1),
						"color_tr" : Color(1,1,1,1),
						"color_br" : Color(1,1,1,1)}


##NODES##
var sprite_node = Node2D.new()
#var sprite_container = MarginContainer.new()
var sprite_rect = Sprite2D.new()

var shader_material = ShaderMaterial.new()

var transformTop = Marker2D.new()
var transformLeft = Marker2D.new()
var transformRight = Marker2D.new()
var transformBottom = Marker2D.new()
var transformBottomRight = Marker2D.new()
var transformTopRight = Marker2D.new()
var transformTopLeft = Marker2D.new()
var transformBottomLeft = Marker2D.new()


#ANIMATION SHIT idk
var saveDefaults = true

var animation_list = []

# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_child(transformTop)
	self.add_child(transformLeft)
	self.add_child(transformBottom)
	self.add_child(transformRight)
	self.add_child(transformBottomRight)
	self.add_child(transformTopRight)
	self.add_child(transformTopLeft)
	self.add_child(transformBottomLeft)
	
	shader_material.set_shader(load("res://Shaders/tint.gdshader"))
	sprite_rect.material = shader_material
	
	shader_material.set_shader_parameter("topleft", color_tl)
	shader_material.set_shader_parameter("bottomleft", color_bl)
	shader_material.set_shader_parameter("topright", color_tr)
	shader_material.set_shader_parameter("bottomright", color_br)
	shader_material.set_shader_parameter("range_min", Vector2(0,0))
	shader_material.set_shader_parameter("range_max", Vector2(1,1))
	shader_material.set_shader_parameter("flipx", flipX)
	shader_material.set_shader_parameter("flipy", flipY)
	
	sprite_rect.texture = null_texture
	#sprite_container.size = element_size
	#sprite_container.add_child(sprite_rect)
	sprite_node.add_child(sprite_rect)
	sprite_rect.scale = sprite_rect.texture.get_size()*element_size
	sprite_rect.centered = false
	sprite_rect.position = -(pivot_point)
	mixed_color = Color(1,1,1,1)
	self.add_child(sprite_node)

func restoreDefaults():
	var initialsaveDefaults = saveDefaults
	saveDefaults = false
	setVisible(defaultSettings["visibility"])
	
	setPositionX(defaultSettings["positionX"])
	setPositionY(defaultSettings["positionY"])
	setAngle(defaultSettings["angle"])
	
	setScalex(defaultSettings["scalex"])
	setScaley(defaultSettings["scaley"])
	
	setSpriteIndex(defaultSettings["sprite_index"])
	
	setColor(defaultSettings["color"])
	
	setColorTL(defaultSettings["color_tl"])
	setColorTR(defaultSettings["color_tr"])
	setColorBL(defaultSettings["color_bl"])
	setColorBR(defaultSettings["color_br"])
	saveDefaults = initialsaveDefaults

func smoothCurve(time, keyframe1, keyframe2):
	var time_diff = float(keyframe2["timestamp"]) - float(keyframe1["timestamp"])
	var time_ratio = 0.0
	if time_diff < 1:
		time_ratio = 0.0
	else:
		time_ratio = (time - float(keyframe1["timestamp"])) / time_diff
	var in_control = keyframe1["ease_in"]
	var out_control = keyframe1["ease_out"]
	var data_diff = float(keyframe2["data"]) - float(keyframe1["data"])
	var cubic_term = (data_diff * -2.0 + time_diff * (in_control + out_control))* time_ratio **3
	var quadratic_term = (data_diff * 3.0 - time_diff * (in_control * 2.0 + out_control)) * time_ratio ** 2
	var linear_term = time_diff * in_control * time_ratio
	var constant_term = float(keyframe1["data"])

	return cubic_term + quadratic_term + linear_term + constant_term

func _process(_delta):
	var parent = self.get_parent()
	if parent is PuyoElement and self.inherit_color:
		mixed_color = parent.mixed_color * color
	else:
		mixed_color = color
	shader_material.set_shader_parameter("color", mixed_color)
	
	
	if sprite_rect.texture is AtlasTexture:
		shader_material.set_shader_parameter("range_min", (sprite_rect.texture.region.position)/sprite_rect.texture.atlas.get_size())
		shader_material.set_shader_parameter("range_max", (sprite_rect.texture.region.size + sprite_rect.texture.region.position)/sprite_rect.texture.atlas.get_size())
	
	else:
		shader_material.set_shader_parameter("range_min", Vector2(0.0,0.0))
		shader_material.set_shader_parameter("range_max", Vector2(1.0,1.0))
	#update()
	
	var pos = Vector2(0,0)
	
	if not inherit_position[0] and not inherit_position[1]:
		var scene = get_root_parent(self)
		pos =  scene.puyo_canvas.global_position + Vector2(positionX, positionY)* scene.canvas_viewport.zoomLevel
		self.global_position = pos
	elif not inherit_position[0]:
		var scene = get_root_parent(self)
		pos =  Vector2(scene.puyo_canvas.global_position.x + positionX* scene.canvas_viewport.zoomLevel,self.global_position.y)
		self.global_position = pos
	elif not inherit_position[1]:
		var scene = get_root_parent(self)
		pos =  Vector2(self.global_position.x, scene.puyo_canvas.global_position.y + positionY* scene.canvas_viewport.zoomLevel)
		self.global_position = pos
	else:
		self.position = Vector2(positionX, positionY)
	
	if not inherit_angle:
		self.global_rotation_degrees = angle
	else:
		self.rotation_degrees = angle
	
	if not inherit_scale[0] and not inherit_scale[1]:
		var scene = get_root_parent(self)
		self.global_skew = 0
		
		self.global_scale = Vector2(scalex, scaley) * scene.canvas_viewport.zoomLevel
	
	elif not inherit_scale[0]:
		var scene = get_root_parent(self)
		self.global_skew = 0
		self.global_scale.x = scalex* scene.canvas_viewport.zoomLevel
	
	elif not inherit_scale[1]:
		var scene = get_root_parent(self)
		self.global_skew = 0
		self.global_scale.y = scaley* scene.canvas_viewport.zoomLevel
	
	else:
		self.scale = Vector2(scalex, scaley)
	
	
	
func get_root_parent(child):
	if child.get_parent().name == "main":
		return child.get_parent()
	else:
		return get_root_parent(child.get_parent())

func update():
	if sprite_list.size() > 0:
		if sprite_index != -1 and sprite_index < sprite_list.size():
			sprite_rect.texture = sprite_list[sprite_index]
		else:
			sprite_rect.texture = null_texture
	else:
		sprite_rect.texture = null_texture
	self.skew = 0
	setScalex(scalex)
	setScaley(scaley)
	setPosition(Vector2(positionX, positionY))
	setAngle(angle)
	

func linearInterpolation(given_time: float, lower_range_time: float, upper_range_time: float) -> float:
	var range_diff = upper_range_time - lower_range_time
	var time_diff = given_time - lower_range_time
	var interpolation_ratio = time_diff / range_diff
	
	if given_time > upper_range_time:
		return 1
	else:
		return interpolation_ratio

func animate(current_time, anim_idx, screen_size, loop_update_fix = false):
	#time = round(time)
	var current_kf
	var next_kf
	var old_default = defaultSettings
	saveDefaults = false
	
	
	var time = current_time 
	#for motion in animation list
	if animation_list.size()-1 < anim_idx:
		pass
	else:
		for animation in animation_list[anim_idx]:
			if animation["Keyframes"].size() > 0:
				#print(animation)
				time = current_time
				if bool(animation["Loop"]) and animation["Keyframes"].size() > 1:
					if loop_update_fix:
						time = float(int(time*60) % int((animation["Keyframes"][animation["Keyframes"].size()-1]["timestamp"]+1)*60))/60
					else:
						time = float(int(time*60) % int((animation["Keyframes"][animation["Keyframes"].size()-1]["timestamp"])*60))/60
					
				#first keyframe doesn't start at 0
				if time < animation["Keyframes"][0]["timestamp"]:
					current_kf = animation["Keyframes"][0].duplicate()
					current_kf["tweening"] = 0
					next_kf = current_kf
				else:
					for keyframe in animation["Keyframes"]:
						current_kf = keyframe.duplicate()
						if animation["Keyframes"].find(keyframe)+1 == animation["Keyframes"].size():
							next_kf = current_kf
							current_kf["tweening"] = 0
						else:
							next_kf = animation["Keyframes"][animation["Keyframes"].find(keyframe)+1]
						
						if time >= current_kf["timestamp"] and time < next_kf["timestamp"]:
							break
				
				var value
				if animation["Motion"].find("rgb") != -1:
					if current_kf["tweening"] == 0:
						value = Color(current_kf["data"]["red"]/255.0, 
								current_kf["data"]["green"]/255.0,
								current_kf["data"]["blue"]/255.0,
								current_kf["data"]["alpha"]/255.0)
					else:
						value = Color(current_kf["data"]["red"]/255.0, 
								current_kf["data"]["green"]/255.0,
								current_kf["data"]["blue"]/255.0,
								current_kf["data"]["alpha"]/255.0).lerp(Color(next_kf["data"]["red"]/255.0, 
													next_kf["data"]["green"]/255.0,
													next_kf["data"]["blue"]/255.0,
													next_kf["data"]["alpha"]/255.0), linearInterpolation(time, current_kf["timestamp"], next_kf["timestamp"]))
					#print(value)
					
				elif current_kf["tweening"] == 0 or (animation["Motion"] == "hide" or animation["Motion"] == "sprite_index"):
					value = current_kf["data"]
				
				elif current_kf["tweening"] == 1:
					value = (current_kf["data"] + ((time - current_kf["timestamp"]) / (next_kf["timestamp"] - current_kf["timestamp"])) * (next_kf["data"] - current_kf["data"]))
					#value = smoothCurve(time,current_kf, next_kf)
					
				elif current_kf["tweening"] == 2:
					value = smoothCurve(time,current_kf, next_kf)
					
				if animation["Motion"] == "posx":
					setPositionX(value*screen_size[0])
				elif animation["Motion"] == "posy":
					setPositionY(value*screen_size[1])
				
				elif animation["Motion"] == "hide":
					setVisible(not bool(int(value)))
				
				elif animation["Motion"] == "scalex":
					setScalex(value)
					update()
					
				elif animation["Motion"] == "scaley":
					setScaley(value)
					update()
					
				elif animation["Motion"] == "angle":
					setAngle(-value)
				
				elif animation["Motion"] == "sprite_index":
					setSpriteIndex(value)
				
				elif animation["Motion"] == "rgba":
					setColor(value)
				
				elif animation["Motion"] == "rgba_tl":
					setColorTL(value)
				
				elif animation["Motion"] == "rgba_bl":
					setColorBL(value)
				
				elif animation["Motion"] == "rgba_tr":
					setColorTR(value)
				
				elif animation["Motion"] == "rgba_br":
					setColorBR(value)
				
			
		
	defaultSettings = old_default


func setRender(value):
	render = value
	self.sprite_node.visible = render
	
func setAddBlend(value):
	add_blend = value
	if add_blend:
		shader_material.set_shader(load("res://Shaders/tint_add.gdshader"))
	else:
		shader_material.set_shader(load("res://Shaders/tint.gdshader"))
	
	shader_material.set_shader_parameter("topleft", color_tl)
	shader_material.set_shader_parameter("bottomleft", color_bl)
	shader_material.set_shader_parameter("topright", color_tr)
	shader_material.set_shader_parameter("bottomright", color_br)
	shader_material.set_shader_parameter("flipx", flipX)
	shader_material.set_shader_parameter("flipy", flipY)
	
	#replace this
	
	shader_material.set_shader_parameter("range_min", Vector2(0,0))
	shader_material.set_shader_parameter("range_max", Vector2(1,1))

func setHideEditor(value):
	hide_editor = value
	self.sprite_rect.visible = not hide_editor

func setFlipX(value):
	flipX = value
	self.sprite_rect.flip_h = value
	shader_material.set_shader_parameter("flipx", flipX)

func setFlipY(value):
	flipY = value
	self.sprite_rect.flip_v = value
	shader_material.set_shader_parameter("flipy", flipY)

#func setSpriteIndexList(value):
#	sprite_index_list = value

func setInheritPosition(value):
	inherit_position = value
	update()

func setInheritScale(value):
	inherit_scale = value
	update()

func setInheritAngle(value):
	inherit_angle = value
	update()

func setInheritColor(value):
	inherit_color = value
	update()

func setName(value):
	element_name = value
	self.name = value + "_" + str(self.layer) + ":" + str(self.id)

func setSize(value):
	element_size = value
	if element_size == Vector2(0,0):
		element_size = Vector2(16,16)
	self.update()

func getPivot():
	return pivot_point

func setPivot(value):
	pivot_point = value
	sprite_rect.position = -(pivot_point)

func setVisible(value):
	visibility = value
	self.visible = visibility
	
	if saveDefaults:
		defaultSettings["visibility"] = visibility
	
func setPositionX(value):
	positionX = value
	
	if saveDefaults:
		defaultSettings["positionX"] = positionX

func setPositionY(value):
	positionY = value
	
	if saveDefaults:
		defaultSettings["positionY"] = positionY

func getAngle():
	return angle

func setAngle(value):
	angle = value
	rotation_degrees = angle
	
	if saveDefaults:
		defaultSettings["angle"] = angle

func setScale(value):
	setScalex(value[0])
	setScaley(value[1])
	

func getScale():
	return Vector2(scalex, scaley)
func getScaley():
	return scaley

func getScalex():
	return scalex

func setScaley(value):
	scaley = value
	
	if sprite_rect.texture is AtlasTexture:
		sprite_rect.scale = element_size/(sprite_rect.texture.region.size)
	else:
		sprite_rect.scale = (sprite_rect.texture.get_size()*element_size)
	self.scale = Vector2(scalex, scaley)
	
	
	if saveDefaults:
		defaultSettings["scaley"] = scaley
	
func setScalex(value):
	scalex = value
	if sprite_rect.texture is AtlasTexture:
		sprite_rect.scale = element_size/(sprite_rect.texture.region.size)
	else:
		sprite_rect.scale = (sprite_rect.texture.get_size()*element_size)
	self.scale = Vector2(scalex, scaley)
	
	if saveDefaults:
		defaultSettings["scalex"] = scalex
	
func setSpriteIndex(value):
	if value < -1:
		value = -1
	sprite_index = value
	
	if saveDefaults:
		defaultSettings["sprite_index"] = sprite_index
	
	update()

func setColor(value):
	color = value
	
	if saveDefaults:
		defaultSettings["color"] = color

func setColorTL(value):
	color_tl = value
	shader_material.set_shader_parameter("topleft", color_tl)
	
	if saveDefaults:
		defaultSettings["color_tl"] = color_tl
	

func setColorBL(value):
	color_bl = value
	shader_material.set_shader_parameter("bottomleft", color_bl)
	
	if saveDefaults:
		defaultSettings["color_bl"] = color_bl
	

func setColorTR(value):
	color_tr = value
	shader_material.set_shader_parameter("topright", color_tr)
	
	if saveDefaults:
		defaultSettings["color_tr"] = color_tr

func setColorBR(value):
	color_br = value
	shader_material.set_shader_parameter("bottomright", color_br)
	
	if saveDefaults:
		defaultSettings["color_br"] = color_br
	
func getPosition():
	return Vector2(positionX, positionY)

func setPosition(value):
	setPositionX(value[0])
	setPositionY(value[1])

func setSpriteList(value):
	sprite_list = value
	update()

func set3dDepth(value):
	depth = value

func getSize():
	return element_size

func getFlipX():
	return flipX

func getFlipY():
	return flipY

func getVisible():
	return visibility

func getColor():
	return color

func getColorTL():
	return color_tl

func getColorBL():
	return color_bl

func getColorTR():
	return color_tr
	
func getColorBR():
	return color_br

func getRender():
	return render

func getAddBlend():
	return add_blend

func getName():
	return element_name

func getSpriteIndex():
	return sprite_index

func dummy():
	return ""

func setdummy(_dum):
	pass

func getSpriteList():
	return sprite_list
