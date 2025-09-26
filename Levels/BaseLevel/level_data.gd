# level_data.gd
extends Resource
class_name LevelData

@export var level_name: String
@export var display_name: String
@export var scene_path: String
@export var level_image: CompressedTexture2D
@export var bronze_time: float = 60.0
@export var silver_time: float = 30.0
@export var gold_time: float = 15.0
@export var level_index: int = 1

@export var collectible_tracks: Array[TrackData]
