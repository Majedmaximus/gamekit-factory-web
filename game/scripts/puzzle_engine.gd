extends RefCounted
class_name PuzzleEngine

const WIDTH: int = 4
const COUNT: int = WIDTH * WIDTH

func solved_board() -> Array[int]:
    var result: Array[int] = []
    for n in range(1, COUNT):
        result.append(n)
    result.append(0)
    return result

func valid_board(board: Array[int]) -> bool:
    if board.size() != COUNT:
        return false
    var seen: Dictionary = {}
    for n in board:
        if n < 0 or n >= COUNT or seen.has(n):
            return false
        seen[n] = true
    return seen.size() == COUNT

func is_solvable(board: Array[int]) -> bool:
    if not valid_board(board):
        return false
    var inversions: int = 0
    for i in range(COUNT):
        if board[i] == 0:
            continue
        for j in range(i + 1, COUNT):
            if board[j] != 0 and board[i] > board[j]:
                inversions += 1
    var empty_row_from_bottom: int = WIDTH - int(board.find(0) / WIDTH)
    return (inversions + empty_row_from_bottom) % 2 == 1

func is_solved(board: Array[int]) -> bool:
    return board == solved_board()

func neighbors(index: int) -> Array[int]:
    var result: Array[int] = []
    if index < 0 or index >= COUNT:
        return result
    var row: int = int(index / WIDTH)
    var col: int = index % WIDTH
    if row > 0:
        result.append(index - WIDTH)
    if row < WIDTH - 1:
        result.append(index + WIDTH)
    if col > 0:
        result.append(index - 1)
    if col < WIDTH - 1:
        result.append(index + 1)
    return result

func move_tile(board: Array[int], index: int) -> bool:
    if not valid_board(board):
        return false
    var blank: int = board.find(0)
    if not neighbors(blank).has(index):
        return false
    board[blank] = board[index]
    board[index] = 0
    return true

func shuffled(seed_value: int, steps: int = 180) -> Array[int]:
    var result: Array[int] = solved_board()
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var previous_blank: int = -1
    for _step in range(max(steps, 1)):
        var blank: int = result.find(0)
        var options: Array[int] = neighbors(blank)
        if options.size() > 1:
            options.erase(previous_blank)
        var target: int = options[rng.randi_range(0, options.size() - 1)]
        result[blank] = result[target]
        result[target] = 0
        previous_blank = blank
    if is_solved(result):
        return shuffled(seed_value + 1, steps)
    return result
