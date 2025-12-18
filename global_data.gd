extends Node

# tracks souls and unlocked skills
var kill_count := 0
var soul_count := 0

# skills reset on death
var purchased_skills = {
	"blood_frenzy": false, # base skill blood frenzy
	"blood_bond": true,   # base skill blood bond
	"bat_form": false,     # base skill bat form
	
	"blood_frenzy_better_claw": false, #faster claw attack by 10%, more blood lose by 4%
	"blood_frenzy_best_claw": false,   #faster claw attack by 20%, blood packets restore 15% more health, more blood loss by 6%
	"blood_frenzy_better_dash": false, #dashign does 25% more damage, costs 10% more blood
	"blood_frenzy_best_dash": false,  #dash kills any enemy under 35 health, dash costs 5% more blood
	"blood_frenzy_max" : false, #20% faster speed, 15% more damage, 10% less max health, 10% more damage taken
	
	"blood_bond_second_dps" : false, #have two allies instead of one, ally_attack does 30% more
	"blood_bond_third_dps" : false,  #have three allies, gain bite_damage like 5% for every minion alive
	"blood_bond_second_tank" : false, #have two allies, ally health is 30% higher
	"blood_bond_third_tank" : false, # have three allies and reduce damage taken by 2% for every minion you have alive
	"blood_bond_max" : false, #one of your three minions will be a dark green, this minion will have more health, damage, speed, and is the first minion made if there is not already this "super ally"
	
	"bat_iframes" : false, #become invulnerable for first 2 secs in bat form and the sprite blinks
	"bat_bite" : false, #able to bite as bat, 80% of normal bite damage
	"bat_claw" : false, #able to claw at enemies at 80% of normal claw at a faster cooldown than base
	"bat_melee" : false, #bat form can only be hit by projectiles, dodging melee attacks
	"bat_max" : false, #any enemy you come into contact with turns 20 enemy health into 20 player blood 
	
}

# temporary active flag for bat form
var bat_form_active := false
