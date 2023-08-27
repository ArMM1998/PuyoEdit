extends TextureButton


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var hover = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if hover:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND)
	

func _on_mouse_entered():
	hover = true


func _on_mouse_exited():
	hover = false


func _on_visibility_changed():
	hover = false


func _on_pressed():
	OS.shell_open("https://ko-fi.com/armm1998")
	hover = false
