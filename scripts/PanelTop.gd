extends Panel

var platforms = ["Wii 16:9", "Wii 4:3", "PS2", "PSP", "3DS top", "3DS bottom", "DS", "Mobile"]
# Called when the node enters the scene tree for the first time.
func _ready():
	$MenuButton_File.set_focus_mode(true)
	
	$MenuButton_File.get_popup().add_item("New")
	$MenuButton_File.get_popup().add_item("Open")
	$MenuButton_File.get_popup().add_separator()
	$MenuButton_File.get_popup().add_item("Save")
	$MenuButton_File.get_popup().add_item("Save As...")
	$MenuButton_File.get_popup().add_separator()
	$MenuButton_File.get_popup().add_item("Exit")
	
	var platform_menu = PopupMenu.new()
	platform_menu.name = "platform_menu"
	super.add_child(platform_menu)
	
	platform_menu.add_item("Wii 16:9")
	platform_menu.add_item("Wii 4:3")
	platform_menu.add_item("PS2")
	platform_menu.add_item("PSP")
	platform_menu.add_item("3DS Top")
	platform_menu.add_item("3DS Bottom")
	platform_menu.add_item("NDS")
	platform_menu.add_item("Mobile")
	
	
	$MenuButton_Project.get_popup().add_item("Sprite Editor")
	$MenuButton_Project.get_popup().add_submenu_item("Target Platform", platform_menu.get_path())
	$MenuButton_Project.get_popup().add_separator()
	$MenuButton_Project.get_popup().add_item("(A) Toggle Axis")
	$MenuButton_Project.get_popup().add_item("(S) Toggle Screen")
	$MenuButton_Project.get_popup().add_item("(F) Toggle Field")
	$MenuButton_Project.get_popup().add_separator()
	$MenuButton_Project.get_popup().add_item("Add new animation")
	
	
	$MenuButton_Help.get_popup().add_item("About")
	$MenuButton_Help.get_popup().add_item("How to Use")
	$MenuButton_Help.get_popup().add_icon_item(load("res://Graphics/misc/smal_cofi.png"),"Support me")
	
	$MenuButton_File.get_popup().connect("id_pressed", fileMenu)
	$MenuButton_Project.get_popup().connect("id_pressed", projectMenu)
	$MenuButton_Help.get_popup().connect("id_pressed", helpMenu)
	platform_menu.connect("id_pressed", platformMenu)

func fileMenu(item_id):
	#print(item_id)
	if item_id == 0:
		owner.newFile()
	if item_id == 1:
		owner.startOpenFileTask()
	if item_id == 3:
		owner.startSaveTask()
	if item_id == 4:
		owner.startSaveAsTask()
	if item_id == 6:
		get_tree().quit()
		
	$MenuButton_File.release_focus()

func projectMenu(item_id):
	if item_id == 0:
		owner.toggleSpriteEditor()
	
	if item_id == 3:
		owner.toggleAxis()
	if item_id == 4:
		owner.toggleScreen()
	if item_id == 5:
		owner.toggleField()
	
	if item_id == 7:
		owner.addAnimation()
	
	$MenuButton_Project.release_focus()

func helpMenu(item_id):
	if item_id == 0:
		owner.about.popup()
		await owner.about.confirmed
	if item_id == 1:
		
		OS.shell_open("https://docs.google.com/document/d/1hvHQTxsCdjIkRdY6yn8P2_9U6CVT1cY_T7exJMBxgPw/view")
	if item_id == 2:
		OS.shell_open("https://ko-fi.com/armm1998")
	$MenuButton_Help.release_focus()

func platformMenu(item_id):
	owner.updateTargetPlatform(platforms[item_id])
	$MenuButton_Project.release_focus()
