@tool
extends Node3D

class_name CubeCustom

const wall_white = preload("res://addons/polyrinthe/wall_white.tscn")
var _wall_material: StandardMaterial3D

const sphere = preload("res://addons/polyrinthe/sphere.tscn")
const distFromCenter: float = 5.2 
const rotationAngle: float = PI/2
const wallValue: int = -1
const outSideWallValue: int = -2
var _spec_scale: float

var _debug: bool
var _showWall: bool
var _triColor: bool

const _connection: bool = false

## Initializes the cube with its position, visual/debug parameters and instantiates its walls.
## Optionally adds a colored sphere marker if the cube is the start or end of the maze.
## [param center] World position of the cube's center.
## [param arr] Array of 6 values representing the state of each face (backward, forward, left, right, down, up).
## [param depth] Depth of the cube in the graph (used to determine if it is the start or end room).
## [param deepest] Maximum depth reached in the graph (used to determine if this cube is the end room).
## [param debug] If true, enables debug visuals such as start/end sphere markers.
## [param showWall] If true, instantiates the walls around the cube.
## [param triColor] If true, uses a three-color gradient for debug elements (unused directly in this function but stored for later use).
## [param new_wall_material] Material to apply to the instantiated walls; if null, keeps the default material.
## [param new_scale] Scale factor applied to the cube and its walls.
func _init(center: Vector3, arr: Array[int], depth: float, deepest: float,
			debug: bool = false, showWall: bool = true, triColor: bool = true,
			new_wall_material: StandardMaterial3D = null, new_scale: float = 1.0):
	
	position = center
	_debug = debug
	_showWall = showWall
	_triColor = triColor
	
	if new_wall_material != null:
		_wall_material = new_wall_material
	_spec_scale = new_scale
	
	instantiate_cube(arr, depth, deepest)
	if _debug:
		if depth == 0:
			var sphereStart = sphere.instantiate()
			sphereStart.get_child(0).mesh.material.albedo_color = Color(1, 1, 1, 1)
			add_child(sphereStart)
			sphereStart.scale = scale * _spec_scale
		elif depth == deepest:
			var sphereEnd = sphere.instantiate()
			sphereEnd.get_child(0).mesh.material.albedo_color = Color(0, 0, 0, 1)
			add_child(sphereEnd)
			sphereEnd.scale = scale * _spec_scale

## Instantiates the walls around the cube based on the given connection array.
## [param arr] Array of 6 values representing the state of each face (backward, forward, left, right, down, up).
## [param depth] Depth of the cube in the graph (not directly used in wall computation but passed for future use/context).
## [param size] Size of the cube (not directly used in wall computation but passed for future use/context).
func instantiate_cube(arr: Array[int], depth: float, size: float) -> void:
	# (backward, forward, left, right, down, up)
	if _showWall:
		if arr[0] == wallValue:
			instatiate_wall_free(Vector3(0,0,distFromCenter*_spec_scale), Vector3(-2*rotationAngle,0,0))
		if arr[1] == wallValue:
			instatiate_wall_free(Vector3(0,0,-distFromCenter*_spec_scale), Vector3(0,0,0))
	
		if arr[2] == wallValue:
			instatiate_wall_free(Vector3(-distFromCenter*_spec_scale,0,0), Vector3(0,rotationAngle,0))
		if arr[3] == wallValue:
			instatiate_wall_free(Vector3(distFromCenter*_spec_scale,0,0), Vector3(0,-rotationAngle,0))
		
		if arr[4] == wallValue:
			instatiate_wall_free(Vector3(0,-distFromCenter*_spec_scale,0), Vector3(rotationAngle,0,0))
		if arr[5] == wallValue:
			instatiate_wall_free(Vector3(0,distFromCenter*_spec_scale,0), Vector3(-rotationAngle,0,0))

## Instantiates a free-standing wall (not attached to a grid) at the given position and rotation, with configured visual properties (LOD, material, scale).
## [param pos] Local position of the wall relative to the cube's center.
## [param rot] Rotation (in radians, as Euler angles) to apply to the wall.
func instatiate_wall_free(pos: Vector3, rot: Vector3) -> void:
	var wallTmp = wall_white.instantiate()
	
	wallTmp.set_position(pos)
	wallTmp.set_rotation(rot)
	
	wallTmp.get_child(0).lod_bias = 0.5
	wallTmp.get_child(0).visibility_range_end = 161
	
	wallTmp.scale = Vector3(_spec_scale, _spec_scale, _spec_scale)
	
	var mesh = wallTmp.get_children()[0] as MeshInstance3D;
	mesh.material_override = _wall_material
	
	add_child(wallTmp)

## Returns the current position of the cube, corresponding to its center.
func getCenter() -> Vector3:
	return position

## Removes all children of the cube (instantiated walls) and frees their memory.
func clean() -> void:
	for i in self.get_children():
		self.remove_child(i)
		i.queue_free()

## Callback automatically called when the node exits the scene tree. Frees the current node.
func _exit_tree():
	self.queue_free()
