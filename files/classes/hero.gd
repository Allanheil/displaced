extends combatant
class_name hero

var unlocked = false setget set_unlocked
var friend_points = 0

var recentlevelups = 0
var baseexp = 0 setget exp_set
var exp_cap = 100 setget ,get_exp_cap

var alt_mana = 0 setget a_mana_set


var gear_level = {weapon1 = 1, weapon2 = 0, armor = 1}
var curweapon = 'weapon1'
var base_dmg_type = 'bludgeon' setget , get_weapon_damagetype

#out of combat regen stats
var regen_collected = 0

var bonusres = []

func _init():
	combatgroup = 'ally'

func set_unlocked(value):
	unlocked = value
	if !value:
		position = null
		input_handler.emit_signal("PositionChanged")


func createfromname(name):
	var template = combatantdata.charlist[name]
	base = template.code
	self.name = tr(template.name)
	for key in ['hpmax', 'hp_growth', 'evasion', 'hitrate', 'race', 'bonusres', 'unlocked', 'icon','combaticon', 'bodyhitsound', 'flavor', 'damage']:
		if template.has(key): set(key, template[key])
	for i in variables.resistlist:
		resists[i] = 0
		if !template.has('resists'): continue
		if template.resists.has(i):
			resists[i] = template.resists[i]
	for i in variables.status_list:
		status_resists[i] = 0
		if !template.has('status_resists'): continue
		if template.status_resists.has(i):
			status_resists[i] = template.status_resists[i]
	if template.keys().has('traits'):
		for t in template.traits:
#			traits[t] = false;
			add_trait(t);
	animations = template.animations.duplicate()
	hp = get_stat('hpmax')


func regen_tick(delta):
	var regen_thresholds = regen_calculate_threshold()
	regen_collected += delta
	if regen_collected >= regen_thresholds:
		regen_collected -= regen_thresholds
		self.hp += 1


func regen_calculate_threshold():
	return variables.TimePerDay/max(get_stat('hpmax'),1)


func exp_set(value):
	if level >= variables.MaxLevel:
		baseexp = get_exp_cap()
	else:
		baseexp = value
		while baseexp > get_exp_cap():
			baseexp -= get_exp_cap()
			levelup()


func get_exp_cap():
	return int(100 * variables.curve[level - 1])

func a_mana_set(value):
	pass

func levelup():
	level += 1
	recentlevelups += 1
#	var template = combatantdata.charlist[id]
#	for id in template.skills:
#		if template.skills[id] == level:
#			skills.push_back(id)

func get_skills():
	var res = []
	var template = combatantdata.charlist[id]
	for id in template.skilllist:
		if template.skilllist[id] <= level:
			res.push_back(id)
	return res


func see_enemy_killed():
	#stub
	friend_points += 1 #can adjust it here, arron still get fp


##cheat
#func unlock_all_skills():
#	var template = combatantdata.charlist[id]
#	for s in template.skilllist:
#		if !skills.has(s):
#			skills.push_back(s)



func switch_weapon():
	if curweapon == 'weapon1': curweapon = 'weapon2'
	else: curweapon = 'weapon1'


func set_weapon(slot):
	if !(slot in ["weapon1", "weapon2"]):
		return
	curweapon = slot


func gear_check(slot, level, op):
	var lv = gear_level[slot]
	if slot != 'armor':
		if slot != curweapon: lv = 0 #possibly not
	match op:
		'eq': return lv == level
		'neq': return lv != level
		'gt': return lv > level
		'gte': return lv >= level
		'lt': return lv < level
		'lte': return lv <= level

func upgrade_gear(slot):
	if gear_level[slot] >= 4: return false
	gear_level[slot] += 1
	return true

func get_item_data_level(slot, level):
	var res = {icon = null, name = null, description = null, colors = [], type = slot, cost = {}, level = level}
	var template = Items.hero_items_data["%s_%s" % [id, slot]]
	res.icon = template.leveldata[level].icon
	if typeof(res.icon) == TYPE_STRING:
		res.icon = load(res.icon)
	res.name = tr(template.name)
	res.description = tr(template.description) + tr(template.leveldata[level].lvldesc)
	res.cost = template.leveldata[level].cost.duplicate()
	return res

func get_item_data(slot):
	return get_item_data_level(slot, gear_level[slot])

func get_item_upgrade_data(slot):
	if gear_level[slot] >= 4: return null
	return get_item_data_level(slot, gear_level[slot] + 1)


func get_weapon_damagetype():
	var res = base_dmg_type
	var template = Items.hero_items_data["%s_%s" % [id, curweapon]]
	if template != null:
		res = template.damagetype
	return res

func get_weapon_range():
	var res = base_dmg_range
	var template = Items.hero_items_data["%s_%s" % [id, curweapon]]
	if template != null:
		res = template.weaponrange
	return res

func get_weapon_sound():
	var res = weaponsound
	var template = Items.hero_items_data["%s_%s" % [id, curweapon]]
	if template != null:
		res = template.weaponsound
	return "sound/%s" % res


#this function is broken and needs revision (but for now skill tooltips are broken as well due to translation issues so i didn't fix this)
#still need fixing
func skill_tooltip_text(skillcode):
	var skill = Skillsdata.skilllist[skillcode]
	var text = ''
	if skill.description.find("%d") >= 0:
		text += skill.description % calculate_number_from_string_array(skill.value)
	else:
		text += skill.description
	return text


func requirementcombatantcheck(req):#Gear, Race, Types, Resists, stats
	if req.size() == 0:
		return true
	var result
	match req.type:
		'gear_level':
			result = gear_check(req.slot, req.level, req.op)
		_:
			result = .requirementcombatantcheck(req)

	return result

func serialize():
	var tmp = {}
	tmp.unlocked = unlocked
	tmp.baseexp = baseexp
	tmp.recentlevelups = recentlevelups
	tmp.level = level
	tmp.curweapon = curweapon
	tmp.gear_level = gear_level.duplicate()
	tmp.skills = skills.duplicate()
	tmp.hp = hp
#	tmp.mana = mana
#	tmp.defeated = defeated
	tmp.position = position
	tmp.static_effects = static_effects.duplicate()
	tmp.temp_effects = temp_effects.duplicate()
	tmp.triggered_effects = triggered_effects.duplicate()
	tmp.bonuses = bonuses.duplicate()
	tmp.fr_p = friend_points
	return tmp

func deserialize(savedir):
#	id = savedir.id
	createfromname(id)
	unlocked = savedir.unlocked
	baseexp = savedir.baseexp
	recentlevelups = savedir.recentlevelups
	level = savedir.level
	curweapon = savedir.curweapon
	gear_level = savedir.gear_level.duplicate()
	skills = savedir.skills.duplicate()
	hp = savedir.hp
#	mana = savedir.mana
#	defeated = savedir.defeated
	if savedir.position != null:
		position = int(savedir.position)
	else:
		position = null
	if position != null: state.combatparty[position] = id
	static_effects = savedir.static_effects.duplicate()
	temp_effects = savedir.temp_effects.duplicate()
	triggered_effects = savedir.triggered_effects.duplicate()
	for eff in static_effects.duplicate():
		var tmp = effects_pool.get_effect_by_id(eff)
		if tmp == null: 
			static_effects.erase(eff)
			continue
		tmp.applied_char = id
		tmp.calculate_args() 
	for eff in temp_effects.duplicate():
		var tmp = effects_pool.get_effect_by_id(eff)
		if tmp == null: 
			temp_effects.erase(eff)
			continue
		tmp.applied_char = id
		tmp.calculate_args() 
	for eff in triggered_effects.duplicate():
		var tmp = effects_pool.get_effect_by_id(eff)
		if tmp == null: 
			triggered_effects.erase(eff)
			continue
		tmp.applied_char = id
		tmp.calculate_args() 
	bonuses = savedir.bonuses.duplicate()
	for slot in gear_level:
		gear_level[slot] = int(gear_level[slot])
	friend_points = int(savedir.fr_p)


var skills_autoselect = ["attack"]
func get_autoselected_skill():
	var skilldata = Skillsdata.patch_skill( skills_autoselect.back(), self)
	while !can_use_skill(skilldata) or skilldata.skilltype == 'item':
		skills_autoselect.pop_back()
		skilldata = Skillsdata.patch_skill( skills_autoselect.back(), self)
	return skills_autoselect.back()
