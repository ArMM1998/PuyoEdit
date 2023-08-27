extends Panel


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_add_element_pressed():
	if owner.selected_element != -1:
		owner.newElement(owner.selected_element)
	else:
		owner.newElement()


func _on_del_element_pressed():
	if owner.selected_element != -1:
		var element = owner.LayerList[owner.selected_layer][owner.selected_element]
		owner.delElement(element, true)
	

func _on_add_layer_pressed():
	owner.newLayer()
