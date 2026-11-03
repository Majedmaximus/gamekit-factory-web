extends SceneTree

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game: Control = scene.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image: Image = root.get_viewport().get_texture().get_image()
    var err: Error = image.save_png("/tmp/godot-visual-en.png")
    assert(err == OK)
    game._toggle_language()
    await process_frame
    await RenderingServer.frame_post_draw
    err = root.get_viewport().get_texture().get_image().save_png("/tmp/godot-visual-ar.png")
    assert(err == OK)
    print("VISUAL_SCREENSHOTS_CREATED")
    quit(0)
