@tool
extends Node

class_name CubeGraph

var neighbors = []
var neighborsConnected = []
var lastVisited = 0 # deprecated
var visited:Array[bool] = []
var processing:Array[bool] = []

var _size: int
var nbrNeighbors: int
var wallValue: int
var outsideWallValue: int

var tags = [] # tab of tab of tag
var current_tag = [] # tab of tag (current state if needed)
var default_tag_value = []

var is_flat: bool = false

## Initializes the graph with maze size, wall values, neighbor count, and optional default tag values.
## Initializes all internal arrays: visited, processing, neighbors, neighborsConnected, and tags.
## Calls _constructNeig and _replaceValueForOutsideWalls to finalize setup.
## [param mazeSize] Number of rooms per side of the cubic maze (creates a cube of size³ rooms).
## [param wallV] Value representing a closed/invalid wall connection between neighbors (default: -1).
## [param outWallV] Value representing an outside wall boundary (default: -2).
## [param nbrN] Number of possible neighbors per room (default: 6 for 3D).
## [param def_tag_value] Default tag values for depth and debug_color (default: [-1, -1]).
func _init(mazeSize: int = 3, wallV: int = -1, outWallV: int = -2, 
		nbrN: int = 6, def_tag_value:Array = [-1, -1]):
	_size = mazeSize
	nbrNeighbors = nbrN
	wallValue = wallV
	outsideWallValue = outWallV
	
	if len(def_tag_value) < 2 || def_tag_value[0] != -1 || def_tag_value[1] != -1:
		default_tag_value = [-1, -1]
		push_error("Special tags initialisation failed -> default_tag_value set 
				to his minimal form: [-1, -1] for [depth, debug_color]")
	else:
		default_tag_value = def_tag_value.duplicate()
	
	for i in range(len(default_tag_value)):
		tags.append([])
	current_tag = default_tag_value.duplicate()
	current_tag[1] = 0 # color
	
	for i in range(getNbrRoom()):
		# TODO see if Array.resise() or something like this is usable here
		visited.append(false)
		processing.append(false)
		neighbors.append([])
		neighborsConnected.append([])
		for j in range(nbrNeighbors):
			neighborsConnected[i].append(wallValue)
		
		for j in range(len(default_tag_value)):
			tags[j].append(default_tag_value[j])
	
	current_tag[1] = 0
	
	_constructNeig()
	_replaceValueForOutsideWalls(neighborsConnected)

## Constructs the neighbor indices for all rooms based on the cubic grid topology (backward, forward, left, right, down, up).
## Automatically marks boundary rooms with wallValue on their outer faces.
func _constructNeig():
	# (backward, forward, left, right, down, up)
	var roomsNumber = getNbrRoom()
	var faceSize = getNbrRoomOnASide()
	
	if roomsNumber <= 1: # no neighbors in these cases
		return
	
	for i in range(faceSize): 
		# backward + forward
		neighbors[i].insert(0, wallValue) # backward is empty for the front side
		neighbors[i].insert(1, i + faceSize); # forward
		
		for j in range(1, _size - 1):
			neighbors[i + j * faceSize].insert(0, i + (j - 1) * faceSize) # backward
			neighbors[i + j * faceSize].insert(1, i + (j + 1) * faceSize) # forward
		
		neighbors[i + (_size - 1) * faceSize].insert(0, i + (_size - 2) * faceSize) # backward
		neighbors[i + (_size - 1) * faceSize].insert(1, wallValue) # forward is empty for the back side
	
	for i in range(faceSize): 
		# left + right
		neighbors[i * _size].insert(2, wallValue) # left is empty for the left side
		neighbors[i * _size].insert(3, i * _size + 1) # right
		
		for j in range(1, _size - 1):
			neighbors[i * _size + j].insert(2, i * _size + j - 1) # left
			neighbors[i * _size + j].insert(3, i * _size + j + 1) # right
			
		neighbors[i * _size + _size - 1].insert(2, i * _size + _size - 2) # left
		neighbors[i * _size + _size - 1].insert(3, wallValue) # right is empty for the right side
	
	var floorC = 0
	for i in range(faceSize): 
		# down + up
		neighbors[i%_size + floorC*faceSize].insert(4, wallValue) # down is empty for the down side
		neighbors[i%_size + floorC*faceSize].insert(5, i%_size + floorC*faceSize + _size) # up
		
		for j in range(1, _size - 1):
			neighbors[i%_size + floorC*faceSize + j*_size].insert(4, i%_size + floorC*faceSize + (j - 1)*_size) # down
			neighbors[i%_size + floorC*faceSize + j*_size].insert(5, i%_size + floorC*faceSize + (j + 1)*_size) # up
		
		neighbors[i%_size + floorC*faceSize + (_size - 1) * _size].insert(4, i%_size + floorC*faceSize + (_size - 2) * _size) # down
		neighbors[i%_size + floorC*faceSize + (_size - 1) * _size].insert(5, wallValue) # up is empty for the up side

		if i%_size == _size - 1:
			floorC += 1
	
	#print(neighbors)

## Enables or disables the "flat" mode of the cube graph (2D generation instead of 3D).
## [param flat_or_not] True to enable flat mode, false to return to standard 3D mode.
func flatten(flat_or_not: bool = true) -> void:
	is_flat = flat_or_not

## Replaces the wall values corresponding to the maze's outer faces with the configured outside wall value, for each affected room in the given array.
## [param array] Array of connections for all rooms, modified in place.
func _replaceValueForOutsideWalls(array):
	# (backward, forward, left, right, down, up)
	for i in range(getNbrRoom()):
		if i < getNbrRoomOnASide():
			array[i].remove_at(0)
			array[i].insert(0, outsideWallValue)
		if i > getNbrRoom() - getNbrRoomOnASide() - 1:
			array[i].remove_at(1)
			array[i].insert(1, outsideWallValue)
		
		if i%getNbrRoomOnASide() < _size:
			array[i].remove_at(4)
			array[i].insert(4, outsideWallValue)
		if i%getNbrRoomOnASide() > getNbrRoomOnASide() - _size - 1:
			array[i].remove_at(5)
			array[i].insert(5, outsideWallValue)
		
		if i%_size == 0:
			array[i].remove_at(2)
			array[i].insert(2, outsideWallValue)
		if i%_size == _size - 1:
			array[i].remove_at(3)
			array[i].insert(3, outsideWallValue)

## Builds and returns a copy of the raw neighbors array (not filtered by connection) for the given room id.
## [param id] Identifier of the room whose neighbors are requested.
## [return] Array of neighbor identifiers (per direction).
func getNeighbors(id: int) -> Array[int]:
	var neighborsForId : Array[int] = []
	#neighbors[id] = neighbors[id].filter(func(number): return number != -1)
	#print("id: ", id, ", _size: ", len(neighbors[id]), ", neighbors[id]: ", neighbors[id])
	for i in range(nbrNeighbors):
		#print("i: ", i, ", neighbors[id][i]: ", neighbors[id][i])
		neighborsForId.append(neighbors[id][i])
	
	return neighborsForId

## Returns the neighbors connected to the given room that are "following" it in graph depth (used to trace connections of the main path).
## [param id] Identifier of the room whose following neighbors are requested.
## [return] Array of connected neighbor identifiers that follow in depth.
func getNextNeighbors(id: int) -> Array[int]:
	var neighborsForId : Array[int] = []
	for i in range(nbrNeighbors):
		if neighborsConnected[id][i] > -1 && isFollowing(id, neighborsConnected[id][i]):
			neighborsForId.append(neighborsConnected[id][i])
	return neighborsForId

## Builds and returns a copy of the connected neighbors array (open walls) for the given room id.
## [param id] Identifier of the room whose connections are requested.
## [return] Array of connected neighbor identifiers (per direction).
func getNeighborsConnection(id) -> Array[int]:
	var neighborsForId : Array[int] = []
	for i in range(nbrNeighbors):
		neighborsForId.append(neighborsConnected[id][i])
	return neighborsForId

## Returns the neighbors connected to the given room that have not yet been visited.
## [param id] Identifier of the room whose unvisited connected neighbors are requested.
## [return] Array of unvisited connected neighbor identifiers.
func getNeighborsConnectionNotVisited(id) -> Array[int]:
	var neighborsForId : Array[int] = []
	for i in range(nbrNeighbors):
		if not isVisited(neighborsConnected[id][i]):
			neighborsForId.append(neighborsConnected[id][i])
	return neighborsForId

## Returns the raw neighbors (not necessarily connected) of the given room that have not yet been visited.
## [param id] Identifier of the room whose unvisited neighbors are requested.
## [param only2D] If true, restricts the search to neighbors in the horizontal plane (ignores up/down).
## [return] Array of unvisited neighbor identifiers.
func getNotVisitedNeighbors(id: int, only2D:bool = false):
	var neighborsForId : Array[int] = []
	var nbrNeighborsNeeded = nbrNeighbors
	if only2D :
		nbrNeighborsNeeded = getNbrNeighborsFor2D()
	for i in range(nbrNeighborsNeeded):
		if not isVisited(neighbors[id][i]):
			neighborsForId.append(neighbors[id][i])
	return neighborsForId

## Returns the raw neighbors of the given room that are not currently being processed.
## [param id] Identifier of the room whose non-processing neighbors are requested.
## [param only2D] If true, restricts the search to neighbors in the horizontal plane (ignores up/down).
## [return] Array of non-processing neighbor identifiers.
func getNotProcessingNeighbors(id: int, only2D:bool = false):
	var neighborsForId : Array[int] = []
	var nbrNeighborsNeeded = nbrNeighbors
	if only2D :
		nbrNeighborsNeeded = getNbrNeighborsFor2D()
	for i in range(nbrNeighborsNeeded):
		if not isProcessing(neighbors[id][i]):
			neighborsForId.append(neighbors[id][i])
	return neighborsForId

## Returns neighbors that are neither being processed nor visited, optionally filtered to 2D only.
## [param id] The room index to query.
## [param only2D] If true, excludes up/down neighbors (default: false).
## [return] Array of unvisited and unprocessed neighbor indices.
func getNotProcNotVisiNeighbors(id: int, only2D:bool = false):
	var neighborsForId : Array[int] = []
	var nbrNeighborsNeeded = nbrNeighbors
	if only2D :
		nbrNeighborsNeeded = getNbrNeighborsFor2D()
	for i in range(nbrNeighborsNeeded):
		if not isProcessing(neighbors[id][i]) and not isVisited(neighbors[id][i]):
			neighborsForId.append(neighbors[id][i])
	return neighborsForId

## Returns the number of neighbors per room in 2D mode (excluding up and down faces).
## [return] Total neighbor count for 2D traversal (nbrNeighbors - 2).
func getNbrNeighborsFor2D() -> int:
	return nbrNeighbors - 2

## Connects two neighboring rooms by updating neighborsConnected bidirectionally, opening the passage between them.
## Prints an error (not blocking) if the two rooms are not actual neighbors.
## [param id1] First room index.
## [param id2] Second room index.
func connectNeighbors(id1: int, id2: int) -> void:
	if not areNeighbors(id1, id2):
		print("ERROR : cannot connect ", id1, " and ", id2, ", they are not Neighbors !")
		return
	
	# left, right
	if id1 + 1 == id2:
		neighborsConnected[id1][3] = id2
		neighborsConnected[id2][2] = id1
	elif id1 - 1 == id2:
		neighborsConnected[id1][2] = id2
		neighborsConnected[id2][3] = id1
	
	# backward, forward
	elif id1 + getNbrRoomOnASide() == id2:
		neighborsConnected[id1][1] = id2
		neighborsConnected[id2][0] = id1
	elif id1 - getNbrRoomOnASide() == id2:
		neighborsConnected[id1][0] = id2
		neighborsConnected[id2][1] = id1
	
	# down, up
	elif id1 + _size == id2:
		neighborsConnected[id1][5] = id2
		neighborsConnected[id2][4] = id1
	elif id1 - _size == id2:
		neighborsConnected[id1][4] = id2
		neighborsConnected[id2][5] = id1

## Disconnects two neighboring rooms by restoring a wall between them, if they are indeed neighbors.
## [param id1] Identifier of the first room.
## [param id2] Identifier of the second room (must be a neighbor of id1).
func disconnectNeighbors(id1: int, id2: int) -> void:
	if not areNeighbors(id1, id2):
		print("ERROR : cannot disconnect ", id1, " and ", id2, ", they are not Neighbors !")
		return
	
	# left, right
	if id1 + 1 == id2:
		neighborsConnected[id1][3] = wallValue
		neighborsConnected[id2][2] = wallValue
	if id1 - 1 == id2:
		neighborsConnected[id1][2] = wallValue
		neighborsConnected[id2][3] = wallValue
	
	# backward, forward
	if id1 + getNbrRoomOnASide() == id2:
		neighborsConnected[id1][1] = wallValue
		neighborsConnected[id2][0] = wallValue
	if id1 - getNbrRoomOnASide() == id2:
		neighborsConnected[id1][0] = wallValue
		neighborsConnected[id2][1] = wallValue
	
	# down, up
	if id1 + _size == id2:
		neighborsConnected[id1][5] = wallValue
		neighborsConnected[id2][4] = wallValue
	if id1 - _size == id2:
		neighborsConnected[id1][4] = wallValue
		neighborsConnected[id2][5] = wallValue

## Checks whether two given rooms are currently connected (open wall between them).
## [param id1] Identifier of the first room.
## [param id2] Identifier of the second room.
## [return] True if the two rooms are connected, false otherwise.
func areConnected(id1: int, id2: int) -> bool:
	if (isInRange(id1) && isInRange(id2)):
		for i in neighborsConnected[id1]:
			if i == id2:
				return true
	return false

## Checks whether two given rooms are neighbors in the graph (regardless of their connection state).
## [param id1] Identifier of the first room.
## [param id2] Identifier of the second room.
## [return] True if the two rooms are neighbors, false otherwise.
func areNeighbors(id1: int, id2: int) -> bool:
	if (isInRange(id1) && isInRange(id2)):
		for i in neighbors[id1]:
			if i == id2:
				return true
	return false

## Returns the total number of rooms (cubes) in the maze.
## [return] Total number of rooms, equal to the size cubed.
func getNbrRoom() -> int:
	return _size * _size * _size

## Returns the number of rooms present on one side (one layer) of the maze.
## [return] Number of rooms on one side, squared.
func getNbrRoomOnASide() -> int:
	return _size * _size

## Returns the number of tag categories defined per room.
## [return] Number of tag dimensions stored.
func get_nbr_tag() -> int:
	return len(default_tag_value)

## Returns the debug color associated with the given room (tag index 1).
## [param id] Room index to query.
## [return] Color value as an integer tag.
func getColor(id: int) -> int:
	return get_tag(id, 1)

## Returns the traversal depth of the given room (tag index 0).
## [param id] Room index to query.
## [return] Depth value as an integer tag.
func getDepth(id: int) -> int:
	return get_tag(id, 0)

## Returns the maximum depth reached across all rooms.
## [return] The deepest depth value currently stored.
func get_deepest() -> int:
	return get_current_tag(0)

## Retrieves a specific tag value for a given room.
## [param room_id] Index of the room to query.
## [param tag_id] Index of the tag to retrieve (0 = depth, 1 = debug_color, etc.).
## [return] The tag value, or -1 if room_id or tag_id is out of range.
func get_tag(room_id: int, tag_id: int) -> int:
	if not isInRange(room_id) || not tag_id < len(tags):
		return -1
	return tags[tag_id][room_id]

func get_current_tag(tag_id: int) -> int:
	if not tag_id < len(tags):
		return -1
	return current_tag[tag_id]

## Sets the traversal depth for a given room (tag index 0).
## Updates the global maximum depth if the new value exceeds the current maximum.
## [param id] Room index to update.
## [param depth] New depth value to assign.
func setDepth(id: int, depth: int) -> void:
	set_tag(id, 0, depth)

## Sets a specific tag value for a given room and updates the global current_tag if the value exceeds the current maximum.
## [param room_id] Index of the room to update.
## [param tag_id] Index of the tag to set (0 = depth, 1 = debug_color, etc.).
## [param value] New value to assign.
## [return] True if the update was successful, false if room_id or tag_id is out of range.
func set_tag(room_id:int, tag_id:int, value:int) -> bool:
	if not isInRange(room_id) || not tag_id < len(tags):
		return false
	
	tags[tag_id][room_id] = value
	if current_tag[tag_id] < value:
		current_tag[tag_id] = value
	
	return true

## Copies the depth tag (index 0) into the debug color tag (index 1) for all rooms.
## Used to visualize depth as a color gradient on the maze.
func setColorFromDepth() -> void:
	tags[1] = tags[0].duplicate()

## Checks whether a room index is within the valid range of the maze.
## [param id] Room index to validate.
## [return] True if id is within valid bounds.
func isInRange(id: int) -> bool:
	return id < getNbrRoom() && id >= 0

## Checks whether a tag index is within the valid range of defined tags.
## [param tag_id] Tag index to validate.
## [return] True if tag_id is within valid bounds.
func isTagInRange(tag_id: int) -> bool:
	return tag_id < len(default_tag_value)

## Returns true if the room has been visited, or if the index is out of range.
## [param id] Room index to check.
## [return] True if visited or out of range.
func isVisited(id: int) -> bool:
	return not isInRange(id) || visited[id]

## Marks a room as visited (or unvisited) and updates lastVisited to track the most recently visited room.
## [param id] Room index to update.
## [param value] True to mark as visited, false to mark as unvisited (default: true).
func setVisited(id: int, value: bool = true) -> void:
	if not isInRange(id): return
	visited[id] = value
	lastVisited = id

## Returns true if the room is currently being processed, or if the index is out of range.
## [param id] Room index to check.
## [return] True if processing or out of range.
func isProcessing(id: int) -> bool:
	return not isInRange(id) || processing[id]

## Sets the processing state of a room (true = under evaluation, false = idle).
## [param id] Room index to update.
## [param value] True to mark as processing, false to mark as idle (default: true).
func setProcessing(id: int, value: bool = true) -> void:
	if not isInRange(id): return
	processing[id] = value

## Determines whether the first given room precedes the second in graph depth (used to orient the connections of the main path).
## [param id_first] Identifier of the first room.
## [param id_second] Identifier of the second room.
## [return] True if id_first has a lower depth than id_second, false otherwise.
func isFollowing(id_first: int, id_second: int) -> bool:
	return isInRange(id_first) && isInRange(id_second) && getDepth(id_first) < getDepth(id_second)

## Checks whether the given room has a neighbor above it.
## [param id] Identifier of the room to test.
## [return] True if an upper neighbor exists, false otherwise.
func hasUpNeighbors(id: int) -> bool:
	return neighbors[id][5] > -1

## Returns the identifier of the neighbor located above the given room.
## [param id] Identifier of the room whose upper neighbor is requested.
## [return] Identifier of the upper neighbor.
func getUpNeighbors(id: int) -> int:
	return neighbors[id][5]

## Fully resets the graph's state: depth, color and visited status of all rooms.
func reset_Depth_Color_Visited():
	lastVisited = 0
	current_tag[0] = 0
	current_tag[1] = 0
	tags[0].clear()
	tags[1].clear()
	visited.clear()
	for i in range(getNbrRoom()):
		tags[0].append(-1)
		tags[1].append(-1)
		visited.append(false)

## Resets only the depth values of all rooms in the graph.
func resetDepth():
	current_tag[0] = 0
	tags[0].clear()
	for i in range(getNbrRoom()):
		tags[0].append(-1)

## Resets only the color values of all rooms in the graph.
func resetColor():
	current_tag[1] = 0
	tags[1].clear()
	for i in range(getNbrRoom()):
		tags[1].append(-1)

## Resets the visited status of all rooms in the graph (no room is marked as visited).
func resetVisited():
	lastVisited = 0
	visited.clear()
	for i in range(getNbrRoom()):
		visited.append(false)

# duplicate from CubeCustom (TODO: simplify)
## Computes a color representing a room's depth, as a normalized gradient (two-color or three-color).
## [param depth] Current depth of the room.
## [param maxDepth] Maximum depth reached in the graph (used to normalize the ratio).
## [param triColor] If true, uses a three-color gradient (red-green-blue); otherwise, uses a two-color gradient (red-blue).
## [return] Vector representing the computed color (R, G, B components), normalized.
func computeColor(depth: float, maxDepth: float, triColor: bool = true) -> Vector3:
	if not triColor:
		var ratio = (depth/(maxDepth-1.))
		return Vector3(1 - ratio, 0, ratio).normalized()
		
	var redRatio = 0
	var greenRatio = 0
	var blueRatio = 0
	
	if depth < maxDepth/2. :
		redRatio = 1 - (depth/((maxDepth-1)/2.))
		greenRatio = (depth/((maxDepth-1)/2.))/2
		blueRatio = 0
		#print(depth, " ", redRatio)
	else :
		redRatio = 0
		greenRatio = 1 - (depth/((maxDepth-1)/2.))/2
		blueRatio = 1 - (2 - (depth/((maxDepth-1)/2.)))
		#print(depth, " ", greenRatio, " ", blueRatio)
	
	#print(depth/maxDepth, " ", 1 - ratio, " ", ratio)
	return Vector3(redRatio, greenRatio, blueRatio).normalized()

## Instantiates a pyramid (4-faces mesh) visually representing a connection between two rooms, oriented and colored according to the given parameters.
## [param center_pos] Position of the starting room's center (base of the pyramid).
## [param distFromCenter] Distance and direction vector towards the connected neighboring room (determines the pyramid's orientation).
## [param color] Color to apply to the pyramid.
func instantiate_pyramid(center_pos: Vector3, distFromCenter: Vector3, color: Vector3):
	var base_distFromCenter: float = distFromCenter.length()/10.
	var vertices = PackedVector3Array()
	var point1:Vector3
	var point2:Vector3
	var point3:Vector3
	var point4:Vector3
	
	if distFromCenter.x != 0:
		point1 = Vector3(0, base_distFromCenter, base_distFromCenter)
		point2 = Vector3(0, -base_distFromCenter, base_distFromCenter)
		point3 = Vector3(0, -base_distFromCenter, -base_distFromCenter)
		point4 = Vector3(0, base_distFromCenter, -base_distFromCenter)
	elif distFromCenter.y != 0:
		point1 = Vector3(base_distFromCenter, 0, base_distFromCenter)
		point2 = Vector3(-base_distFromCenter, 0, base_distFromCenter)
		point3 = Vector3(-base_distFromCenter, 0, -base_distFromCenter)
		point4 = Vector3(base_distFromCenter, 0, -base_distFromCenter)
	else:
		point1 = Vector3(base_distFromCenter, base_distFromCenter, 0)
		point2 = Vector3(-base_distFromCenter, base_distFromCenter, 0)
		point3 = Vector3(-base_distFromCenter, -base_distFromCenter, 0)
		point4 = Vector3(base_distFromCenter, -base_distFromCenter, 0)
	
	# 4 faces :
	vertices.push_back(point1)
	vertices.push_back(distFromCenter)
	vertices.push_back(point2)
	
	vertices.push_back(point2)
	vertices.push_back(distFromCenter)
	vertices.push_back(point3)

	vertices.push_back(point3)
	vertices.push_back(distFromCenter)
	vertices.push_back(point4)

	vertices.push_back(point4)
	vertices.push_back(distFromCenter)
	vertices.push_back(point1)
	
	# base (square (triangle x 2)):
	vertices.push_back(point1)
	vertices.push_back(point2)
	vertices.push_back(point3)
	
	vertices.push_back(point3)
	vertices.push_back(point4)
	vertices.push_back(point1)
	
	
	# Initialize the ArrayMesh.
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
	m.position = center_pos
	
	var newMaterial = StandardMaterial3D.new()
	newMaterial.albedo_color = Color(color.x, color.y, color.z, 1)
	m.material_override = newMaterial
	
	return m

## Clears all internal data structures and removes/frees all child nodes from the graph.
## Call this before freeing or reinitializing the graph to avoid memory leaks.
func clean():
	neighbors.clear()
	neighborsConnected.clear()
	current_tag.clear()
	lastVisited = 0
	visited.clear()
	processing.clear()
	tags.clear()
	
	for i in self.get_children():
		self.remove_child(i)
		i.queue_free()
