extends Control

@export var settings: SettingsData
@export var people: Array[PersonData]
@export var current_person_index: int = 0
@export var input_audio_analyzer: AudioAnalyzer
@export var expected_audio_analyzer: AudioAnalyzer
@export var correctness_label: Label
@export var avarage_label: Label

@export var input_frame_data: Dictionary = {}
@export var expected_frame_data: Dictionary = {}

@export var frame_data: Dictionary = {}
@export var epsilon: float = 0.002

@export var similarities: Array[float] = []
var was_reset: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_audio_analyzer.frame_analyzed.connect(_on_frame_analyzed)
	expected_audio_analyzer.frame_analyzed.connect(_on_frame_analyzed)
	expected_audio_analyzer.stream_finished.connect(_on_stream_finished)
	
	set_current_person()
	
func set_current_person():
	print("Setting up person %d" % current_person_index)
	var current_person := people[current_person_index]
	expected_audio_analyzer.stop()
	expected_audio_analyzer.stream = current_person.stream
	epsilon = current_person.epsilon
	
	_set_analyzer_options(input_audio_analyzer, current_person)
	_set_analyzer_options(expected_audio_analyzer, current_person)
	
	expected_audio_analyzer.play.call_deferred()
	
func _set_analyzer_options(analyzer: AudioAnalyzer, person: PersonData):
	analyzer.columns = person.columns
	analyzer.FREQ_MAX = person.max_frequency

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func update_frame_correctness(frame_number: int):
	var diff = []
	var correct_frequencies = 0.0
	var total_frequencies = 0.0
	
	#if not frame_data.has(frame_number):
		#correctness_label.text = ""
		#return
	
	var data: Dictionary = frame_data[frame_number]
	var diffs = {}
	var tmp = []
	for analyzer_name in data:
		tmp.append(data[analyzer_name])
		
	var buff_1: Array[float] = tmp[0]
	var buff_2: Array[float] = tmp[1]
	
	var len := mini(buff_1.size(), buff_2.size()) # should be the same, but just in case
	for i in len:
		if is_zero_approx(buff_1[i]) or is_zero_approx(buff_2[i]):
			continue
		
		var current_diff = absf(buff_1[i] - buff_2[i])
		diff.append(current_diff)
		total_frequencies +=1
		if current_diff <= epsilon * settings.epsilon_multiplier:
			correct_frequencies += 1
	
	if total_frequencies > 0:
		var correctedness: float = ((correct_frequencies / total_frequencies) * 100)
		correctness_label.text = "%d%%" % correctedness

		similarities.append(correctedness)
	else:
		correctness_label.text = ""

func _on_frame_analyzed(analyzer_name: StringName, frame_number: int, fft: Array[float]) -> void:
	var data: Dictionary = frame_data.get_or_add(frame_number, {})
	data[analyzer_name] = fft
	
	if data.keys().size() == 2:
		await get_tree().process_frame
		update_frame_correctness.call_deferred(frame_number)

func _on_stream_finished() -> void:
	var avg_similarity: float = 0
	if similarities.size() > 0:
		avg_similarity = similarities.reduce(sum, 0) / similarities.size()
	print("avg: %d%%" % avg_similarity)
	avarage_label.text = "avg: %d%%" % avg_similarity
	#await get_tree().process_frame
	similarities.clear()
	#frame_data.clear()
	#for key in frame_data:
		#for another_key in frame_data[key]:
			#frame_data[key][another_key].fill(0.0)
			
	if avg_similarity >= settings.similarity_threshold:
		input_audio_analyzer.stop()
		expected_audio_analyzer.stop()
		await get_tree().create_timer(1).timeout
		
		for key in frame_data:
			for another_key in frame_data[key]:
				frame_data[key][another_key].fill(0.0)
		_pass_person()
	else:
		input_audio_analyzer.reset.call_deferred()
		expected_audio_analyzer.reset.call_deferred()

func _pass_person():
	current_person_index += 1
	if current_person_index >= people.size():
		end_game()
	else:
		set_current_person() 

func end_game():
	expected_audio_analyzer.stop()
	print("Congratulations!")
	
func sum(accum, number):
	return accum + number
