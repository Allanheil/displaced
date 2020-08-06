extends Reference
class_name Item

var name = ""
var id
var itembase
var code
var icon
var descirption
var stackable = false
var inventory

#Useable data
var amount = 1 setget amount_set
var useeffects
var useskill
var foodvalue = 0

#Gear Data
var type
var itemtype
var geartype
var subtype
var durability
var maxdurability
var price
var bonusstats = {} #bonus stats apply to chars
var parts = {}
var effects = []
var task
var owner = null
var partcolororder
var broken = false
var tags = []
var materials = []
var weaponrange
var multislots = []
var availslots = []
var hitsound

func CreateUsable(ItemName = '', number = 1):
	itembase = ItemName
	code = ItemName
	stackable = true
	amount = number
	var itemtemplate = Items.Items[ItemName]
	if itemtemplate.icon != null:
		icon = itemtemplate.icon.get_path()
	name = itemtemplate.name
	foodvalue = itemtemplate.foodvalue
	itemtype = itemtemplate.itemtype
	useeffects = itemtemplate.useeffects
	useskill = itemtemplate.useskill
	descirption = itemtemplate.description

func amount_set(value):
	amount = value
	if amount <= 0:
		inventory.erase(id)

func UseItem(user = null, target = null):
	var finaltarget
	for i in effects:
		var effect = Effectdata.effects[i]
		if i.taker == 'caster':
			if user == null:
				return
			finaltarget = user
		elif i.taker == 'target':
			if target == null:
				return
			finaltarget = target
		Effectdata.call(effect.effect, finaltarget, effect.value)


func CreateGear(ItemName = '', dictparts = {}):
	itembase = ItemName
	bonusstats = {damage = 0, damagemod = 1, armor = 0, armorpenetration = 0, evasion = 0, hitrate = 0, hpmax = 0, hpmod = 0, manamod = 0, speed = 0, resistfire = 0, resistearth = 0, resistair = 0, resistwater = 0, mdef = 0}
	stackable = false
	var itemtemplate = Items.Items[ItemName]
	var tempname = itemtemplate.name
	
	
	partcolororder = itemtemplate.partcolororder
	geartype = itemtemplate.geartype
	if itemtemplate.has('weaponrange'):
		weaponrange = itemtemplate.weaponrange
	itemtype = itemtemplate.itemtype
	
	for i in itemtemplate.basestats:
		if bonusstats.has(i):
			bonusstats[i] += itemtemplate.basestats[i]
	
	
	if itemtemplate.has('effects'):
		for e in itemtemplate.effects:
			effects.push_back(e)
	
	parts = dictparts.duplicate()
	durability = itemtemplate.basedurability
	tags = itemtemplate.tags
	if itemtemplate.has('multislots'):
		multislots = itemtemplate.multislots
	if itemtemplate.has('hitsound'):
		hitsound = itemtemplate.hitsound
	availslots = itemtemplate.availslots
	var parteffectdict = {}
	for i in parts:
		var material = Items.Materials[parts[i]]
		var materialeffects = material['parts'][i]
		materials.append(material.code)
		globals.AddOrIncrementDict(parteffectdict, materialeffects)
	if parteffectdict.has('durabilitymod'):
		durability *= parteffectdict.durabilitymod
	for i in parteffectdict:
		if self.get(i) != null && i != 'effects':
			#self[i] += parteffectdict[i]
			set(i, get(i)+parteffectdict[i])
		elif bonusstats.has(i):
			bonusstats[i] += parteffectdict[i]
		elif i == 'effects':
			for k in parteffectdict[i]:
				effects.append(k)
	for i in itemtemplate.basemods:
		if bonusstats.has(i):
			bonusstats[i] *= itemtemplate.basemods[i]
	
	
	if itemtemplate.icon != null:
		if itemtemplate.has("alticons"):
			var alticon = false
			for i in itemtemplate.alticons.values():
				if i.materials.has(parts[i.part]):
					icon = i.icon.get_path()
					if i.has('altname'):
						tempname = i.altname
					alticon = true
			if alticon == false:
				icon = itemtemplate.icon.get_path()
		else:
			icon = itemtemplate.icon.get_path()
	
	
	
	if dictparts.size() == itemtemplate.parts.size():
		name = Items.Materials[dictparts[itemtemplate.partmaterialname]].adjective.capitalize() + ' ' + tempname
	else:
		name = tempname
	
	bonusstats.damage = ceil(bonusstats.damage * bonusstats.damagemod)
	bonusstats.erase('damagemod')
	durability = round(durability)
	maxdurability = round(durability)

func substractitemcost():
	var itemtemplate = Items.Items[itembase]
	for i in parts:
		state.materials[parts[i]] -= itemtemplate.parts[i]

func itemshadeimage(node):
	var shader = load("res://files/scenes/ItemShader.tres").duplicate()
	if node.get_class() == "TextureButton":
		node.texture_normal = load(icon)
	else:
		node.texture = load(icon)
	if node.material != shader:
		node.material = shader
	else:
		shader = node.material
	for i in parts:
		var part = 'part' +  str(partcolororder[i]) + 'color'
		var color = Items.Materials[parts[i]].color
		node.material.set_shader_param(part, color)

func tooltiptext():
	var text = ''
	text += '[center]' + name + '[/center]\n' 
	if itemtype in ['armor','weapon']:
		text += 'Durability: ' + str(durability) + '/' + str(maxdurability)
		text += "\n\n"
		for i in bonusstats:
			if bonusstats[i] != 0:
				var value = bonusstats[i]
				var change = ''
				if i in ['hpmod', 'manamod']:
					value = value*100
				text += Items.stats[i] + ': {color='
				if value > 0:
					change = '+'
					text += 'green|'
				else:
					text += 'red|'
				value = str(value)
				if i in ['hpmod', 'manamod']:
					value = change + value + '%'
				text += value + '}\n'
		text += tooltipeffects()
	elif itemtype == 'usable':
		text += descirption + '\n\n' + tr("INPOSESSION") + ': ' + str(amount)
	
	text = globals.TextEncoder(text)
	return text

func tooltipeffects():
	var text = ''
	for i in effects:
		text += "{color=" + Effectdata.effects[i].textcolor + '|' + Effectdata.effects[i].descript
		text += '}\n'
	return text

func tooltip(targetnode):
	var node = input_handler.get_spec_node(input_handler.NODE_ITEMTOOLTIP)#GetItemTooltip()
	node.showup(targetnode, self)


func repairwithmaterials():
	var materialsdict = counterepairmaterials()
	
	durability = maxdurability
	
	for i in materialsdict:
		state.materials[i] -= materialsdict[i]

func canrepairwithmaterials(): #checks if item can be repaired at present state and returns the problem
	var canrepair = true
	var text = ''
	var materialsdict = counterepairmaterials()
	
	for i in materialsdict:
		if state.materials[i] < materialsdict[i]:
			canrepair = false
			text += tr("NOTENOUGH") + ' [color=yellow]' + Items.Materials[i].name + '[/color]'
	
	if effects.has('brittle'):
		canrepair = false
		text = tr("CANTREPAIREFFECT")
	
	var returndict = {canrepair = canrepair, text = text}
	
	return returndict

func calculatematerials():
	var itemtemplate = Items.Items[itembase] #item base for item parts amount
	var materialsdict = {} #total materials used in creation
	#collecting parts info
	for i in parts:
		if materialsdict.has(parts[i]):
			materialsdict[parts[i]] += itemtemplate.parts[i]
		else:
			materialsdict[parts[i]] = itemtemplate.parts[i]
	return materialsdict

func counterepairmaterials():
	var requiredmaterialsdict = calculatematerials()
	var itemtemplate = Items.Items[itembase] 
	
	#calculating total resource needs
	var multiplier = 0
	match itemtemplate.repairdifficulty: #0.5, 0.65, 0.8
		'easy':
			multiplier = variables.RepairCostMultiplierEasy
		'medium':
			multiplier = variables.RepairCostMultiplierMedium
		'hard':
			multiplier = variables.RepairCostMultiplierHard
	if effects.has('natural'): #0.15
		multiplier -= variables.ItemEffectNaturalMultiplier
	
	var durabilitymultiplier = 1 - durability/maxdurability
	
	for i in requiredmaterialsdict:
		requiredmaterialsdict[i] *= multiplier * durabilitymultiplier
		requiredmaterialsdict[i] = ceil(requiredmaterialsdict[i])
	
	
	return requiredmaterialsdict

func calculateprice():
	var price = 0
	if itemtype == 'usable':
		price = Items.Items[itembase].price
	else:
		var materialsdict = calculatematerials()
		for i in materialsdict:
			price += Items.Materials[i].price*materialsdict[i]
	return price

func serialize():
	var tmp = {};
	var atr = ['name', 'id', 'itembase', 'code', 'icon', 'descirption', 'stackable', 'amount', 'useeffects', 'useskill', 'foodvalue', 'type', 'itemtype', 'geartype', 'subtype', 'durability', 'maxdurability', 'price', 'task', 'owner', 'partcolororder', 'broken', 'weaponrange'];
	var atr2 = ['bonusstats', 'parts', 'effects', 'tags', 'materials', 'multislots', 'availslots'];
	for a in atr:
		tmp[a] = get(a)
	for a in atr2:
		tmp[a] = get(a).duplicate()
	return tmp;

func deserialize(tmp):
	var atr = ['name', 'id', 'itembase', 'code', 'icon', 'descirption', 'stackable', 'useeffects', 'useskill', 'foodvalue', 'type', 'itemtype', 'geartype', 'subtype', 'durability', 'maxdurability', 'price', 'task', 'owner', 'partcolororder', 'broken', 'weaponrange'];
	var atr2 = ['bonusstats', 'parts', 'effects', 'tags', 'materials', 'multislots', 'availslots'];
	for a in atr:
		set(a, tmp[a])
	for a in atr2:
		set(a, tmp[a].duplicate())
	amount = tmp.amount;
	inventory = state.items;
	#id = int(id);
	#if owner != null: owner = int(owner);

