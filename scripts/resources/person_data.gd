extends Resource
class_name PersonData

@export var stream: AudioStream
@export_range(0.002, 0.9) var epsilon: float = 0.1
@export_range(1, 128) var columns: int = 32
@export var max_frequency: float = 11050.0
