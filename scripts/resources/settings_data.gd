extends Resource
class_name SettingsData

@export var audio_bus_Layout: AudioBusLayout
@export_range(1.0, 100) var epsilon_multiplier: float = 1.0
@export_range(30, 99) var similarity_threshold: float = 75.0
