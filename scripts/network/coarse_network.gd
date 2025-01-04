@tool
class_name CoarseNetwork
extends Resource

const Octree = preload("res://addons/skelerealms/scripts/network/octree.gd")

@export var octree: Octree ## Octree of indexes to positions.
@export var positions := PackedVector3Array() ## Positions of nodes.
@export var connections := PackedInt32Array() ## Connections between nodes.
@export var portals := PackedInt32Array() ## Indexes for portals
@export var portal_connections := PackedInt32Array() ## Connections between portals in the same world
@export var portal_destinations: Dictionary[int, Dictionary] = {} ## Portal destinations.
