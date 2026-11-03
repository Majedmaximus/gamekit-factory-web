extends Control

const Puzzle = preload("res://scripts/puzzle_engine.gd")
const SAVE_FILE = "user://daily.json"

var engine = Puzzle.new()
var board: Array[int] = []
var buttons: Array[Button] = []
var moves: int = 0
var mode: String = "daily"
var language: String = "en"
var day_key: String = ""
var solved: bool = false
var title_label: Label
var sub_label: Label
var info_label: Label
var daily_button: Button
var random_button: Button
var language_button: Button
var share_button: Button
var grid: GridContainer

const STRINGS = {
    "en": {
        "title": "Slide 15",
        "sub": "Offline puzzle • Made with GameKit Factory",
        "daily": "Daily",
        "random": "New game",
        "language": "العربية",
        "moves": "Moves: %d",
        "help": "Slide a tile next to the empty square.",
        "won": "Solved in %d moves! Copy your result.",
        "share": "Copy result"
    },
    "ar": {
        "title": "لغز ١٥",
        "sub": "لعبة تعمل بدون إنترنت • GameKit Factory",
        "daily": "التحدي اليومي",
        "random": "لعبة جديدة",
        "language": "English",
        "moves": "الحركات: %d",
        "help": "حرّك قطعة مجاورة للمربع الفارغ.",
        "won": "أحسنت! اكتمل اللغز خلال %d حركة.",
        "share": "نسخ النتيجة"
    }
}

func text_for(key: String) -> String:
    return STRINGS[language][key]

func _ready() -> void:
    language = "ar" if OS.get_locale_language() == "ar" else "en"
    _build_ui()
    _set_language()
    _start_daily()

func _build_ui() -> void:
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 20)
    add_child(margin)

    var outer := VBoxContainer.new()
    outer.alignment = BoxContainer.ALIGNMENT_CENTER
    outer.add_theme_constant_override("separation", 18)
    margin.add_child(outer)

    title_label = Label.new()
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 38)
    outer.add_child(title_label)

    sub_label = Label.new()
    sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    outer.add_child(sub_label)

    var actions := HBoxContainer.new()
    actions.alignment = BoxContainer.ALIGNMENT_CENTER
    actions.add_theme_constant_override("separation", 8)
    outer.add_child(actions)
    daily_button = Button.new()
    daily_button.pressed.connect(_start_daily)
    actions.add_child(daily_button)
    random_button = Button.new()
    random_button.pressed.connect(_start_random)
    actions.add_child(random_button)
    language_button = Button.new()
    language_button.pressed.connect(_toggle_language)
    actions.add_child(language_button)

    grid = GridContainer.new()
    grid.columns = 4
    # Keep the numeric 4x4 board in its logical left-to-right order in Arabic.
    grid.layout_direction = Control.LAYOUT_DIRECTION_LTR
    grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    grid.add_theme_constant_override("h_separation", 4)
    grid.add_theme_constant_override("v_separation", 4)
    outer.add_child(grid)
    for index in range(16):
        var tile := Button.new()
        tile.custom_minimum_size = Vector2(68, 68)
        tile.add_theme_font_size_override("font_size", 25)
        tile.pressed.connect(_on_tile_pressed.bind(index))
        buttons.append(tile)
        grid.add_child(tile)

    info_label = Label.new()
    info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    outer.add_child(info_label)

    share_button = Button.new()
    share_button.pressed.connect(_copy_result)
    outer.add_child(share_button)

func _today_key() -> String:
    var d: Dictionary = Time.get_date_dict_from_system()
    return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]

func _daily_seed() -> int:
    var d: Dictionary = Time.get_date_dict_from_system()
    return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])

func _start_daily() -> void:
    day_key = _today_key()
    mode = "daily"
    moves = 0
    solved = false
    if not _restore_daily():
        board = engine.shuffled(_daily_seed())
    _render()

func _start_random() -> void:
    mode = "random"
    moves = 0
    solved = false
    board = engine.shuffled(int(Time.get_unix_time_from_system()) + int(Time.get_ticks_usec()))
    _render()

func _on_tile_pressed(index: int) -> void:
    if solved:
        return
    if engine.move_tile(board, index):
        moves += 1
        solved = engine.is_solved(board)
        if mode == "daily":
            _save_daily()
        _render()

func _toggle_language() -> void:
    language = "ar" if language == "en" else "en"
    _set_language()
    _render()

func _set_language() -> void:
    title_label.text = text_for("title")
    sub_label.text = text_for("sub")
    daily_button.text = text_for("daily")
    random_button.text = text_for("random")
    language_button.text = text_for("language")
    share_button.text = text_for("share")
    layout_direction = Control.LAYOUT_DIRECTION_RTL if language == "ar" else Control.LAYOUT_DIRECTION_LTR

func _render() -> void:
    if board.size() != 16:
        return
    var options: Array[int] = engine.neighbors(board.find(0))
    for i in range(16):
        buttons[i].text = "" if board[i] == 0 else str(board[i])
        buttons[i].disabled = solved or board[i] == 0 or not options.has(i)
    if solved:
        info_label.text = text_for("won") % moves
    else:
        info_label.text = (text_for("moves") % moves) + "\n" + text_for("help")
    share_button.visible = solved

func _copy_result() -> void:
    if solved:
        DisplayServer.clipboard_set("Slide 15 • %s • %d moves" % [day_key if mode == "daily" else "random", moves])

func _save_daily() -> void:
    var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({"day": day_key, "board": board, "moves": moves}))
    file.close()

func _restore_daily() -> bool:
    if not FileAccess.file_exists(SAVE_FILE):
        return false
    var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
    if file == null:
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return false
    var record: Dictionary = parsed
    if str(record.get("day", "")) != day_key:
        return false
    var values: Variant = record.get("board", [])
    if typeof(values) != TYPE_ARRAY or values.size() != 16:
        return false
    var restored: Array[int] = []
    for value in values:
        if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
            return false
        if float(value) != float(int(value)):
            return false
        restored.append(int(value))
    if not engine.is_solvable(restored):
        return false
    var saved_moves: Variant = record.get("moves", 0)
    if typeof(saved_moves) != TYPE_FLOAT and typeof(saved_moves) != TYPE_INT:
        return false
    if float(saved_moves) < 0 or float(saved_moves) != floor(float(saved_moves)) or float(saved_moves) > 10000000:
        return false
    board = restored
    moves = int(saved_moves)
    solved = engine.is_solved(board)
    return true
