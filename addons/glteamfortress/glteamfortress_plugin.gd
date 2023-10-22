@tool
extends EditorPlugin

const GLTeamFortressExtension := preload("./gltf_extension.gd")
var extension_instance := GLTeamFortressExtension.new()

func _enter_tree():
	GLTFDocument.register_gltf_document_extension(extension_instance, true)


func _exit_tree():
	GLTFDocument.unregister_gltf_document_extension(extension_instance)
