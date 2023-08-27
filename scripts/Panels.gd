extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func panelResize(window_size):
	if $toggle_panelBottom.button_pressed:
		$PanelLeft.size = Vector2(256, window_size[1]-32-16)
		$PanelRight.size = Vector2(256, window_size[1]-32-16)
		$toggle_panelBottom.position = Vector2(0, window_size[1])
	else:
		$PanelLeft.size = Vector2(256, window_size[1]-256-32-16)
		$PanelRight.size = Vector2(256, window_size[1]-256-32-16)
		$toggle_panelBottom.position = Vector2(0, window_size[1] - 256)
	
	$PanelTop.size = Vector2(window_size[0], 32)
	$PanelRight.position = Vector2(window_size[0]-256, 32+8)
	$PanelBottom.size = Vector2(window_size[0], 256)
	$PanelBottom.position = Vector2(0, window_size[1]-256)
	
	if $toggle_panelLeft.button_pressed:
		$toggle_panelLeft.position = Vector2(0, 40)
	else:
		$toggle_panelLeft.position = Vector2(256, 40)
	
	if $toggle_panelRight.button_pressed:
		$toggle_panelRight.position = Vector2(window_size[0]-8, 40)
	else:
		$toggle_panelRight.position = Vector2(window_size[0]-256-8, 40)
	
	$PanelLeft.visible = not $toggle_panelLeft.button_pressed
	$PanelRight.visible = not $toggle_panelRight.button_pressed
	$PanelBottom.visible = not $toggle_panelBottom.button_pressed
	
	panelLeftResize()

func panelLeftResize():
	$PanelLeft/ElementTree.size = Vector2(256-16, $PanelLeft.size[1]-$PanelLeft/ElementTree.position.y - 40)
	$PanelLeft/addElement.position = Vector2(10, $PanelLeft.size[1]-35)
	$PanelLeft/delElement.position = Vector2(256-34, $PanelLeft.size[1]-32)
	$PanelLeft/addLayer.position = Vector2(40, $PanelLeft.size[1]-35)

func togglePanels():
	owner.status_message.displayMessage("Panels toggled")
	$toggle_panelRight.button_pressed  = not $toggle_panelLeft.button_pressed
	$toggle_panelBottom.button_pressed = not $toggle_panelLeft.button_pressed
	$toggle_panelLeft.button_pressed   = not $toggle_panelLeft.button_pressed

func panelLeftToggle(_button_pressed):
	owner.status_message.displayMessage("Left pannel toggled")
	owner.windowResize()

func panelRightToggle(_button_pressed):
	owner.status_message.displayMessage("Right pannel toggled")
	owner.windowResize()

func panelBottomToggle(_button_pressed):
	owner.status_message.displayMessage("Bottom pannel toggled")
	owner.windowResize()
