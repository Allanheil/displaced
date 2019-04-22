extends Node


var date := 1
var daytime = 0

var newgame = false

var votelinksseen = false

#resources
var itemidcounter := 0
var heroidcounter := 0
var workeridcounter := 0
var money = 0
var food = 50
var townupgrades := {}
var workers := {}
var heroes := {}
var items := {}
var tasks := []
var materials := {} setget materials_set
var lognode 
var oldmaterials := {}
var unlocks := []

var combatparty := {1 : null, 2 : null, 3 : null, 4 : null, 5 : null, 6 : null} setget pos_set


var CurrentTextScene
var CurrentScreen
var CurrentLine := 0

var heroguild := {}

var OldEvents := {}
var CurEvent := "" #event name
var CurBuild := ""
var keyframes := []

#Progress
var mainprogress = 0
var decisions := []
var activequests := []
var completedquests := []
var areaprogress := {}
var currentarea
var currenttutorial = 'tutorial1'
var viewed_tips := []

func revert():
	date = 1
	daytime = 0
	newgame = false
	votelinksseen = false
	itemidcounter = 0
	heroidcounter = 0
	workeridcounter = 0
	money = 0
	food = 50
	townupgrades.clear()
	workers.clear()
	heroes.clear()
	items.clear()
	tasks.resize(0)
	materials.clear()
	lognode = null
	oldmaterials.clear()
	unlocks.resize(0)
	combatparty = {1 : null, 2 : null, 3 : null, 4 : null, 5 : null, 6 : null} 
	CurrentTextScene = null
	CurrentScreen = null
	CurrentLine = 0
	heroguild.clear()
	OldEvents.clear()
	CurEvent = "" #event name
	CurBuild = ""
	keyframes.resize(0)
	mainprogress = 0
	decisions.resize(0)
	activequests.resize(0)
	completedquests.resize(0)
	areaprogress.clear()
	currentarea = null
	currenttutorial = 'tutorial1'
	viewed_tips.resize(0)

func pos_set(value):
	combatparty = value
	for p in combatparty:
		if combatparty[p] == null: continue
		heroes[combatparty[p]].position = p

func _ready():
	for i in Items.Materials:
		materials[i] = 0
	oldmaterials = materials.duplicate()

func materials_set(value):
	var text = ''
	for i in value:
		if oldmaterials.has(i) == false || oldmaterials[i] != value[i]:
			if oldmaterials.has(i) == false:
				oldmaterials[i] = 0
			else:
				if oldmaterials[i] - value[i] < 0:
					text += 'Gained '
					input_handler.emit_signal("MaterialObtained", i)
				else:
					text += "Lost "
				text += str(value[i] - oldmaterials[i]) + ' {color=yellow|' + Items.Materials[i].name + '}'
				logupdate(text)
	materials = value
	oldmaterials = materials.duplicate()

func logupdate(text):
	if globals.get_tree().get_root().has_node("LogPanel/RichTextLabel") == false:
		return
	lognode = globals.get_tree().get_root().get_node("LogPanel/RichTextLabel")
	text = lognode.bbcode_text + '\n' + text
	
	#lognode.bbcode_text += '\n' + 
	lognode.bbcode_text = globals.TextEncoder(text)

func assignworker(data):
	data.worker.task = data
	if data.instrument != null:
		data.instrument.task = data
	tasks.append(data)

func stoptask(data):
	data.worker.task = null
	data.instrument.task = null
	tasks.erase(data)

func stopworkertask(worker):
	var data = gettaskfromworker(worker)
	if data != false:
		stoptask(data)

func gettaskfromworker(worker):
	for i in tasks:
		if i.worker == worker:
			return i
	return false

func GetWorkerLimit():
	var value
	if townupgrades.has("houses") == false:
		value = 3
	else:
		value = globals.upgradelist.houses.levels[townupgrades.houses].limitchange
	return value

func ProgressMainStage(stage = null):
	if stage == null:
		mainprogress += 1
	else:
		mainprogress = stage

func MakeQuest(code):
	activequests.append({code = code, stage = 1})
	input_handler.emit_signal("QuestStarted", code)

func GetQuest(code):
	for i in activequests:
		if i.code == code:
			return i.stage
	return null

func AdvanceQuest(code):
	for i in activequests:
		if i.code == code:
			i.stage += 1

func FinishQuest(code):
	var tempquest
	for i in activequests:
		if i.code == code:
			tempquest = i
	
	activequests.erase(tempquest)
	completedquests.append(tempquest.code)
	input_handler.emit_signal("QuestCompleted", code)

func StoreEvent(nm):
	OldEvents[nm] = date

func FinishEvent():
	if CurEvent == "" or CurEvent == null:return
	StoreEvent(CurEvent)
	CurEvent = ""
	keyframes.clear()


func if_has_money(value):
	return (money >= value)

func if_has_property(prop, value):
	var tmp = get(prop)
	if tmp == null: 
		print ("ERROR: NO PROPERTY IN GAMESTATE %s\n", prop)
		return false
	return (tmp >= value)

func if_has_hero(name):
	for h in heroes.values():
		if h.base == name: return true
	return false

func if_has_material(mat, operant, val):
	if !materials.has(mat): return false
	return input_handler.operate(operant, materials[mat], val)

func if_has_item(name):
	for i in items.values():
		if i.name == name: return true
	return false

func checkreqs(array):
	var check = true
	for i in array:
		if valuecheck(i) == false:
			check = false
	return check

func valuecheck(dict):
	if !dict.has('type'): return true
	match dict['type']:
		"no_check":
			return true
		"has_money":
			return if_has_money(dict['value'])
		"has_property":
			return if_has_property(dict['prop'], dict['value'])
		"has_hero":
			return if_has_hero(dict['name'])
		"event_finished":
			var tmp = OldEvents.has(dict['name'])
			if tmp and dict.has('delay'):
				tmp = OldEvents[dict['name']] + dict['delay'] <= date
			return tmp
		"has_material":
			return if_has_material(dict['material'], dict.operant, dict['value'])
		"date":
			return date >= dict['date']
		"item":
			return if_has_item(dict['name'])
		"building":
			return CurBuild == dict['value']
		"gamestart":
			return newgame
		"has_upgrade":
			return if_has_upgrade(dict.name, dict.value)
		"main_progress":
			return if_has_progress(dict.value, dict.operant)
		"area_progress":
			return if_has_area_progress(dict.value, dict.operant, dict.area)
		"decision":
			return decisions.has(dict.name)
		"quest_stage":
			return if_quest_stage(dict.name, dict.value, dict.operant)
		"quest_completed":
			return completedquests.has(dict.name)
		"party_level":
			return if_party_level(dict.operant, dict.value)
		"hero_level":
			if if_has_hero(dict.name) == false:
				return false
			else:
				return if_hero_level(dict.name, dict.operant, dict.value)

func if_quest_stage(name, value, operant):
	var questprogress
	questprogress = GetQuest(name)
	if questprogress == null:
		questprogress = 0
	
	return input_handler.operate(operant, questprogress, value)

func if_has_area_progress(value, operant, area):
	if !areaprogress.has(area):return false
	return input_handler.operate(operant, areaprogress[area], value)

func if_has_progress(value, operant):
	return input_handler.operate(operant, mainprogress, value)

func if_has_upgrade(upgrade, level):
	if !townupgrades.has(upgrade): return false
	else: return townupgrades[upgrade] >= level

func get_character_by_pos(pos):
	if combatparty[pos] == null: return null
	return heroes[combatparty[pos]]

func if_party_level(operant,value):
	var counter = 0
	for i in combatparty.values():
		if i != null:
			counter += heroes[i].level
	return input_handler.operate(operant, counter, value)

func if_hero_level(name, operant, value):
	var hero
	for h in heroes.values():
		if h.name == name: hero = h
	return input_handler.operate(operant, hero.level, value)


func serialize():
	var tmp = {}
	var arr = ['date', 'daytime', 'newgame', 'itemidcounter', 'heroidcounter', 'workeridcounter', 'money', 'food', 'CurBuild', 'mainprogress', 'CurEvent', 'CurrentLine','currentutorial', 'newgame', 'votelinksseen']
	var arr2 = ['townupgrades', 'tasks', 'materials', 'unlocks', 'combatparty', 'OldEvents', 'keyframes', 'decisions', 'activequests', 'completedquests', 'areaprogress']
	var arr3 = ['workers', 'heroes', 'items', 'heroguild']
	for prop in arr:
		tmp[prop] = get(prop)
	for prop in arr2:
		tmp[prop] = get(prop).duplicate()
	for prop in arr3:
		var tmp1 = {}
		var ref = get(prop)
		for key in ref.keys():
			tmp1[key] = ref[key].serialize()
		tmp[prop] = tmp1
	return tmp

func deserialize(tmp):
	var arr = ['date', 'daytime', 'newgame', 'itemidcounter', 'heroidcounter', 'workeridcounter', 'money', 'food', 'CurBuild', 'mainprogress', 'CurEvent', 'CurrentLine', 'currentutorial', 'newgame', 'votelinksseen']
	var arr2 = [ 'tasks', 'unlocks', 'OldEvents', 'keyframes', 'decisions', 'activequests', 'completedquests']
	#var arr3 = ['workers', 'heroes', 'items', 'heroguild']
	for prop in arr:
		if get(prop) != null:
			set(prop, tmp[prop])
	for prop in arr2:
		set(prop, tmp[prop].duplicate())
	materials = tmp.materials.duplicate()
	workers.clear()
	for key in tmp['workers'].keys():
		var t = worker.new()
		t.deserialize(tmp['workers'][key])
		t.id = key
		workers[key] = t
	heroes.clear()
	for key in tmp['heroes'].keys():
		var t = combatant.new()
		t.deserialize(tmp['heroes'][key])
		t.id = key
		heroes[key] = t
	heroguild.clear()
	for key in tmp['heroguild'].keys():
		var t = combatant.new() #not sure if heroguild consists of combatants, but it has no use now
		t.deserialize(tmp['heroguild'][key])
		t.id = key
		heroguild[key] = t
	items.clear()
	for key in tmp['items'].keys():
		var t = Item.new()
		t.deserialize(tmp['items'][key])
		t.inventory = items
		if t.owner != null:
			for s in t.availslots:
				heroes[t.owner].gear[s] = t.id
		items[key] = t
	#date = int(date)
	#CurrentLine = int(CurrentLine)
	#itemidcounter = int(itemidcounter)
	#heroidcounter = int(heroidcounter)
	#workeridcounter = int(workeridcounter)
	#combatparty = tmp.combatparty.duplicate()
	for k in tmp['combatparty'].keys() :
		combatparty[int(k)] = tmp['combatparty'][k]
	for k in tmp['areaprogress'].keys() :
		areaprogress[k] = int(tmp['areaprogress'][k])
	for k in tmp['townupgrades'].keys() :
		townupgrades[k] = int(tmp['townupgrades'][k])
	oldmaterials = materials.duplicate()