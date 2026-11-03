extends SceneTree

const Game = preload("res://scripts/main.gd")
const SAVE_FILE = "user://daily.json"

func _initialize() -> void:
    call_deferred("_run_checks")

func _write_record(data: Dictionary) -> void:
    var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    assert(file != null, "Must be able to write test save")
    file.store_string(JSON.stringify(data))
    file.close()

func _run_checks() -> void:
    var game = Game.new()
    root.add_child(game)
    assert(game.grid != null)
    assert(game.grid.columns == 4)
    assert(game.grid.layout_direction == Control.LAYOUT_DIRECTION_LTR)
    assert(game.buttons.size() == 16)
    if game.language != "ar":
        game._toggle_language()
    assert(game.language == "ar")
    assert(game.layout_direction == Control.LAYOUT_DIRECTION_RTL)
    assert(game.grid.layout_direction == Control.LAYOUT_DIRECTION_LTR)
    assert(game.board.size() == 16)
    var first: Array[int] = game.board.duplicate()
    game._toggle_language()
    assert(game.language == "en")
    assert(game.board == first)

    var goal: Array[int] = game.engine.solved_board()
    var today: String = game._today_key()
    _write_record({"day": today, "board": goal, "moves": 4})
    assert(game._restore_daily(), "Valid record must restore")
    assert(game.moves == 4)
    assert(game.board == goal)
    assert(game.solved)

    var duplicate: Array = []
    var fractional: Array = []
    for n in goal:
        duplicate.append(n)
        fractional.append(n)
    duplicate[0] = duplicate[1]
    fractional[0] = 1.5
    var impossible: Array = []
    for n in goal:
        impossible.append(n)
    impossible[0] = 2
    impossible[1] = 1
    for record in [
        {"day": today, "board": duplicate, "moves": 3},
        {"day": today, "board": fractional, "moves": 3},
        {"day": today, "board": impossible, "moves": 3},
        {"day": today, "board": goal, "moves": -1},
        {"day": today, "board": goal, "moves": 2.5},
        {"day": today, "board": goal, "moves": "abc"},
        {"day": today, "board": goal, "moves": 10000000000},
        {"day": "2000-01-01", "board": goal, "moves": 2},
    ]:
        _write_record(record)
        assert(not game._restore_daily(), "Invalid daily record was accepted")
    var dir := DirAccess.open("user://")
    if dir != null:
        dir.remove("daily.json")
    print("PASS: Arabic LTR grid, switch language, valid and invalid save restore")
    quit(0)
