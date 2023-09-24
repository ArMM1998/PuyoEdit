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
	elif owner.selected_layer < owner.LayerList.size() and owner.selected_layer != -1:
		if owner.LayerList[owner.selected_layer].size() == 0:
			owner.delLayer(owner.selected_layer)
		else:
			owner.status_message.displayMessage("Cannot delete layer containing elements.", true)
	$ElementTree.updateSelected()

func _on_add_layer_pressed():
	owner.newLayer()
