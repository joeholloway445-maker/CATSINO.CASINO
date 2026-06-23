extends Node
## Mirrors TEXTURE_MATERIAL in CharacterPreview3DCanvas.tsx (THE-HDV-CORE).
## Maps each race's texture_type to PBR material parameters for the
## procedural Godot rig. Keep in sync by hand with the three.js map.

const TEXTURE_MATERIAL: Dictionary = {
	"radiant": {"roughness": 0.25, "metalness": 0.5, "transparent": false, "emissive_strength": 1.4},
	"mutated": {"roughness": 0.85, "metalness": 0.05, "transparent": false, "emissive_strength": 0.0},
	"abyssal": {"roughness": 0.3, "metalness": 0.6, "transparent": false, "emissive_strength": 0.3},
	"spectral": {"roughness": 0.4, "metalness": 0.1, "transparent": true, "opacity": 0.78, "emissive_strength": 0.6},
	"phasic": {"roughness": 0.35, "metalness": 0.2, "transparent": true, "opacity": 0.7, "emissive_strength": 0.8},
	"temporal": {"roughness": 0.3, "metalness": 0.7, "transparent": false, "emissive_strength": 0.5},
	"voidlike": {"roughness": 0.6, "metalness": 0.3, "transparent": false, "emissive_strength": 0.2},
	"symbiotic": {"roughness": 0.8, "metalness": 0.0, "transparent": false, "emissive_strength": 0.0},
	"digital": {"roughness": 0.2, "metalness": 0.4, "transparent": false, "emissive_strength": 1.6},
	"biotech": {"roughness": 0.45, "metalness": 0.55, "transparent": false, "emissive_strength": 0.3},
	"dimensional": {"roughness": 0.3, "metalness": 0.5, "transparent": false, "emissive_strength": 0.7},
	"amphibious": {"roughness": 0.75, "metalness": 0.05, "transparent": false, "emissive_strength": 0.0},
	"solar": {"roughness": 0.2, "metalness": 0.4, "transparent": false, "emissive_strength": 1.8},
	"crystalline": {"roughness": 0.1, "metalness": 0.7, "transparent": false, "emissive_strength": 0.4},
	"electric": {"roughness": 0.25, "metalness": 0.3, "transparent": false, "emissive_strength": 1.5},
	"morphic": {"roughness": 0.4, "metalness": 0.1, "transparent": false, "emissive_strength": 0.2},
	"regal": {"roughness": 0.4, "metalness": 0.6, "transparent": false, "emissive_strength": 0.3},
	"decayed": {"roughness": 0.9, "metalness": 0.0, "transparent": false, "emissive_strength": 0.0},
	"crystal": {"roughness": 0.05, "metalness": 0.8, "transparent": true, "opacity": 0.9, "emissive_strength": 0.5},
	"celestial": {"roughness": 0.2, "metalness": 0.6, "transparent": false, "emissive_strength": 1.2},
}

static func get_for(texture_type: String) -> Dictionary:
	return TEXTURE_MATERIAL.get(texture_type, {"roughness": 0.5, "metalness": 0.3, "transparent": false, "emissive_strength": 0.0})

static func build_material(texture_type: String, primary_color: Color) -> StandardMaterial3D:
	var params := get_for(texture_type)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = primary_color
	mat.roughness = params.get("roughness", 0.5)
	mat.metallic = params.get("metalness", 0.3)
	if params.get("transparent", false):
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = params.get("opacity", 0.8)
	var emissive_strength: float = params.get("emissive_strength", 0.0)
	if emissive_strength > 0.0:
		mat.emission_enabled = true
		mat.emission = primary_color
		mat.emission_energy_multiplier = emissive_strength
	return mat
