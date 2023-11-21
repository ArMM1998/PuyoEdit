extends Node2D

var grid_size = Vector2(1,1)
var grid_color = Color(0.8, 0.8, 0.8, 0.3)
var grid_visible = false
var grid_pos = Vector2(0, 0)
var start_point = Vector2(0,0)
var end_point = Vector2(0,0)

func _draw():
	if grid_visible:
		var color = grid_color

		# Calculate the number of grid lines needed within the range
		var num_lines_x = int((end_point.x - start_point.x) / grid_size.x) + 1
		var num_lines_y = int((end_point.y - start_point.y) / grid_size.y) + 1

		# Draw vertical lines
		for i in range(num_lines_x):
			var x = start_point.x + i * grid_size.x
			draw_line(Vector2(x, start_point.y), Vector2(x, end_point.y), color)

		# Draw horizontal lines
		for i in range(num_lines_y):
			var y = start_point.y + i * grid_size.y
			draw_line(Vector2(start_point.x, y), Vector2(end_point.x, y), color)


func update_grid():
	grid_color = Color(0.8, 0.8, 0.8, 0.15)
	visible = false
	visible = grid_visible

func set_grid_pos(grid_position):
	grid_pos = grid_position
	update_grid()

# Setter functions to update grid properties
func set_grid_size(size, cell_size):
	end_point = size
	grid_size = cell_size
	update_grid()

func set_grid_visibility(visib):
	grid_visible = visib
	update_grid()
