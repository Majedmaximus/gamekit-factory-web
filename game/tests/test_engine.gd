extends SceneTree

const Puzzle = preload("res://scripts/puzzle_engine.gd")

func _initialize() -> void:
    var p = Puzzle.new()
    var goal: Array[int] = p.solved_board()
    assert(goal.size() == 16)
    assert(p.valid_board(goal))
    assert(p.is_solvable(goal))
    assert(p.is_solved(goal))
    assert(not p.move_tile(goal, 0))
    assert(p.move_tile(goal, 14))
    assert(not p.is_solved(goal))
    assert(p.move_tile(goal, 15))
    assert(p.is_solved(goal))
    for i in range(100):
        var a: Array[int] = p.shuffled(i + 123)
        var b: Array[int] = p.shuffled(i + 123)
        assert(a == b)
        assert(p.valid_board(a))
        assert(p.is_solvable(a))
        assert(not p.is_solved(a))
        assert(p.neighbors(a.find(0)).size() >= 2)
    print("PASS: PuzzleEngine deterministic shuffle, legal moves, validation")
    quit(0)
