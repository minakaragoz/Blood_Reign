extends Node

# tracks souls and unlocked skills
var kill_count := 0
var soul_count := 0

# skills reset on death
var purchased_skills = {
	"blood_frenzy": false,
	"blood_bond": false,
	"bat_form": false
}

# temporary active flag for bat form
var bat_form_active := false
