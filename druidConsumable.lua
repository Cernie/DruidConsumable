DruidConsumable = {};
function DruidConsumable_OnLoad()
	this:RegisterEvent("PLAYER_LOGIN")
	this:RegisterEvent("PLAYER_REGEN_DISABLED")
	this:RegisterEvent("PLAYER_REGEN_ENABLED")	
	local msg = "Druid Consumable loaded. Type /druidconsumable for usage.";
	DEFAULT_CHAT_FRAME:AddMessage(msg);
	SlashCmdList["DRUIDCONSUMABLE"] = function()
		DEFAULT_CHAT_FRAME:AddMessage("To use DruidConsumable addon, create a macro that uses the following signature:");
		DEFAULT_CHAT_FRAME:AddMessage("/script DruidConsumable({options});");
		DEFAULT_CHAT_FRAME:AddMessage("This addon also requires you have either DruidBar or Luna Unit Frames addon installed.");
		DEFAULT_CHAT_FRAME:AddMessage("");
		DEFAULT_CHAT_FRAME:AddMessage("Available options to pass as parameters:");
		DEFAULT_CHAT_FRAME:AddMessage("type");
		DEFAULT_CHAT_FRAME:AddMessage("   -This is a string of the type of consumable you want to use.");
		DEFAULT_CHAT_FRAME:AddMessage("   -Valid types are mana, health, sapper, juju, misc.");
		DEFAULT_CHAT_FRAME:AddMessage("   -Note if using type='misc', the item parameter is required.");
		DEFAULT_CHAT_FRAME:AddMessage("item");
		DEFAULT_CHAT_FRAME:AddMessage("   -This is a string of the item name you wish to use if using type='misc'.");
		DEFAULT_CHAT_FRAME:AddMessage("form");
		DEFAULT_CHAT_FRAME:AddMessage("   -This is a string of the form you wish to powershift back into.");
		DEFAULT_CHAT_FRAME:AddMessage("   -Valid forms are (Dire) Bear Form, Cat Form, Travel Form, Aquatic Form, Moonkin Form.");
		DEFAULT_CHAT_FRAME:AddMessage("   -If nothing is passed to this parameter, the addon defaults to Cat Form.");
		DEFAULT_CHAT_FRAME:AddMessage("manaCutOff");
		DEFAULT_CHAT_FRAME:AddMessage("   -This is a number of the mana level at which you wish to start using mana consumables.");
		DEFAULT_CHAT_FRAME:AddMessage("   -This is used in conjunction with type='mana'.");
		DEFAULT_CHAT_FRAME:AddMessage("healthCutOff");
		DEFAULT_CHAT_FRAME:AddMessage("   -This is a number of the health level at which you wish to start using health consumables.");
		DEFAULT_CHAT_FRAME:AddMessage("   -This is used in conjunction with type='health'.");
		DEFAULT_CHAT_FRAME:AddMessage("percent");
		DEFAULT_CHAT_FRAME:AddMessage("   -This is a number between 0 and 1 of the mana or health level at which you wish to start using mana/health consumables.");
		DEFAULT_CHAT_FRAME:AddMessage("   -manaCutOff and healthCutOff will be used instead if either are passed as a parameter.");
		DEFAULT_CHAT_FRAME:AddMessage("   -This is used in conjunction with type='health' or type='mana'.");
		DEFAULT_CHAT_FRAME:AddMessage("   -If neither manaCutOff/healthCutOff nor percent is passed as a parameter, the addon defaults to percent=0.5 (50%).");
		DEFAULT_CHAT_FRAME:AddMessage("Example macro for Cat Form Mana Consumables:");
		DEFAULT_CHAT_FRAME:AddMessage("   /script DruidConsumable({type='mana', form='Cat Form', manaCutOff=3500});");
		DEFAULT_CHAT_FRAME:AddMessage("Example macro for Bear Form Health Consumables:");
		DEFAULT_CHAT_FRAME:AddMessage("   /script DruidConsumable({type='health', form='Dire Bear Form', percent=0.35});");
		DEFAULT_CHAT_FRAME:AddMessage("Example macro for Bear Form Misc tanking potion:");
		DEFAULT_CHAT_FRAME:AddMessage("   /script DruidConsumable({type='misc', form='Dire Bear Form', item='Greater Stoneshield Potion'});");
		DEFAULT_CHAT_FRAME:AddMessage("Example macro for Cat Form Juju Flurry Consumable:");
		DEFAULT_CHAT_FRAME:AddMessage("   /script DruidConsumable({type='juju', form='Cat Form'});");
		DEFAULT_CHAT_FRAME:AddMessage("Example macro for Cat Form Goblin Sapper Charge Consumable:");
		DEFAULT_CHAT_FRAME:AddMessage("   /script DruidConsumable({type='sapper', form='Cat Form'});");
	end;
	SLASH_DRUIDCONSUMABLE1 = "/druidconsumable";
end;

DruidConsumable_MANA_GAME_TIME_LAST_USED = 0;
DruidConsumable_HEALTH_GAME_TIME_LAST_USED = 0;
DruidConsumable_MISC_GAME_TIME_LAST_USED = 0;
function DruidConsumable(options)
	local currentMana = UnitMana("player");
	local maxMana = UnitManaMax("player");
	local manaDiff = maxMana - currentMana;
	local manaPct = currentMana / maxMana;
	local currentHealth = UnitHealth("player");
	local maxHealth = UnitHealthMax("player");
	local healthPct = currentHealth / maxHealth;
	local currentForm = getShapeshiftForm();
	local targetForm = "Cat Form";
	local gcd = isSpellOnCd(targetForm);
	local percent = 0.5;
	local manaCutOff = nil;
	local healthCutOff = nil;
	local consumeType = "misc";
	local miscItem = nil;
	local canConsume = false;
	local willConsume = false;
	local currentTime = GetTime();
	local lastManaTime = currentTime - DruidConsumable_MANA_GAME_TIME_LAST_USED;
	local lastHealthTime = currentTime - DruidConsumable_HEALTH_GAME_TIME_LAST_USED;
	local lastMiscTime = currentTime - DruidConsumable_MISC_GAME_TIME_LAST_USED;
	local timeBetweenUses = 3;
	
	--get options
	if(options.percent) then
		percent = options.percent;
	end;
	if(options.manaCutOff) then
		manaCutOff = options.manaCutOff;
	end;
	if(options.healthCutOff) then
		healthCutOff = options.healthCutOff;
	end;
	if(options.type) then
		consumeType = options.type;
	end;
	if(options.form) then
		targetForm = options.form;
		gcd = isSpellOnCd(targetForm);
	end;
	if(options.item) then
		miscItem = options.item;
	end;
	
	--get current mana levels, even in form
	if(DruidBarFrame) then
		maxMana = DruidBarKey.maxmana;
		currentMana = DruidBarKey.keepthemana;
		manaDiff = maxMana - currentMana;
		manaPct = currentMana / maxMana;
	elseif(LunaUF) then
		currentMana, maxMana = LunaUF.DruidManaLib:GetMana();
		manaDiff = maxMana - currentMana;
		manaPct = currentMana / maxMana;
	end;
	
	--determine if the addon should attempt to use a consumable
	if(consumeType == "mana" and (DruidConsumable_canUseConsumable("manaPotion") ~= nil or DruidConsumable_canUseConsumable("rune") ~= nil or DruidConsumable_canUseConsumable("lily root") ~= nil or DruidConsumable_canUseConsumable("nightdragon") ~= nil)) then
		canConsume = true;
		if(manaCutOff ~= nil and currentMana <= manaCutOff) then
			willConsume = true;
		elseif(manaCutOff == nil and manaPct <= percent) then
			willConsume = true;
		end;
	elseif(consumeType == "health" and (DruidConsumable_canUseConsumable("healthPotion") ~= nil or DruidConsumable_canUseConsumable("whipper root") ~= nil or DruidConsumable_canUseConsumable("healthStone") ~= nil)) then 
		canConsume = true;
		if(healthCutOff ~= nil and currentHealth <= healthCutOff) then
			willConsume = true;
		elseif(healthCutOff == nil and healthPct <= percent) then
			willConsume = true;
		end;
	elseif(consumeType == "sapper" and DruidConsumable_canUseConsumable("sapper") ~= nil) then
		canConsume = true;
		if(currentHealth > 940) then
			willConsume = true;
		end;
	elseif(consumeType == "juju" and DruidConsumable_canUseConsumable("juju") ~= nil) then 
		canConsume = true;
		willConsume = true;
	elseif(consumeType == "sand" and DruidConsumable_canUseConsumable("sand") ~= nil) then 
		canConsume = true;
		willConsume = true;
	elseif(consumeType == "misc" and miscItem ~= nil) then
		local found, bag, slot = isInBag(miscItem);
		local cd = isContainerItemOnCd(miscItem);

		if(found == true and cd == false) then
			canConsume = true;
			willConsume = true;
		end;
	end;
	
	--use consumable
	if(consumeType == "mana") then
		if(currentForm == 0) then
			if(willConsume == true and lastManaTime > timeBetweenUses and gcd == false) then
				DruidConsumable_consume(consumeType);
				DruidConsumable_MANA_GAME_TIME_LAST_USED = GetTime();
			else
				Shapeshift(targetForm, false, false);
				ToggleAutoAttack("on");
			end;
		elseif(currentForm ~= 0 and willConsume == true and lastManaTime > timeBetweenUses and gcd == false) then
			CastShapeshiftForm(currentForm);
			ToggleAutoAttack("off");
		end;
	elseif(consumeType == "health") then
		if(currentForm == 0) then
			if(willConsume == true and lastHealthTime > timeBetweenUses and gcd == false) then
				DruidConsumable_consume(consumeType);
				DruidConsumable_HEALTH_GAME_TIME_LAST_USED = GetTime();
			else
				Shapeshift(targetForm, false, false);
				ToggleAutoAttack("on");
			end;
		elseif(currentForm ~= 0 and willConsume == true and lastManaTime > timeBetweenUses and gcd == false) then
			CastShapeshiftForm(currentForm);
			ToggleAutoAttack("off");
		end;
	elseif(consumeType == "sapper") then
		if(currentForm == 0) then
			if(willConsume == true and gcd == false) then
				DruidConsumable_consume(consumeType);
			else
				Shapeshift(targetForm, false, false);
				ToggleAutoAttack("on");
			end;
		elseif(currentForm ~= 0 and willConsume == true and gcd == false) then
			CastShapeshiftForm(currentForm);
			ToggleAutoAttack("off");
		end;
	elseif(consumeType == "juju") then
		if(currentForm == 0) then
			if(willConsume == true and lastMiscTime > timeBetweenUses and gcd == false) then
				DruidConsumable_consume(consumeType);
				DruidConsumable_HEALTH_GAME_TIME_LAST_USED = GetTime();
			else
				Shapeshift(targetForm, false, false);
				ToggleAutoAttack("on");
			end;
		elseif(currentForm ~= 0 and willConsume == true and lastMiscTime > timeBetweenUses and gcd == false) then
			CastShapeshiftForm(currentForm);
			ToggleAutoAttack("off");
		end;
	elseif(consumeType == "sand") then
		if(currentForm == 0) then
			if(willConsume == true and lastMiscTime > timeBetweenUses and gcd == false) then
				DruidConsumable_consume(consumeType);
				DruidConsumable_HEALTH_GAME_TIME_LAST_USED = GetTime();
			else
				Shapeshift(targetForm, false, false);
				ToggleAutoAttack("on");
			end;
		elseif(currentForm ~= 0 and willConsume == true and lastMiscTime > timeBetweenUses and gcd == false) then
			CastShapeshiftForm(currentForm);
			ToggleAutoAttack("off");
		end;
	elseif(consumeType == "misc") then
		if(currentForm == 0) then
			if(willConsume == true and gcd == false and lastMiscTime > timeBetweenUses) then
				UseItemInBag(miscItem);
				DruidConsumable_MISC_GAME_TIME_LAST_USED = GetTime();
				DEFAULT_CHAT_FRAME:AddMessage("DruidConsumable: Attempting to use "..miscItem..".");
			else
				Shapeshift(targetForm, false, false);
				ToggleAutoAttack("on");
			end;
		elseif(currentForm ~= 0 and willConsume == true and gcd == false and lastMiscTime > timeBetweenUses) then
			CastShapeshiftForm(currentForm);
			ToggleAutoAttack("off");
		end;
	end;
end;

--Function to use a consuable based on type
function DruidConsumable_consume(consumeType)
	local msg = "Nothing";
	if(consumeType == "mana") then
		if(DruidConsumable_canUseConsumable("manaPotion")) then UseManaPotion();
		elseif(DruidConsumable_canUseConsumable("lily root")) then DruidConsumable_UseNightDragonOrRune("lily root");
		elseif(DruidConsumable_canUseConsumable("rune")) then DruidConsumable_UseNightDragonOrRune("rune");
		elseif(DruidConsumable_canUseConsumable("nightdragon")) then DruidConsumable_UseNightDragonOrRune("nightdragon");
		end;
	elseif(consumeType == "sapper") then
		if(DruidConsumable_canUseConsumable("sapper")) then 
			UseItemInBag("Goblin Sapper Charge", 1);
			msg = "Goblin Sapper Charge";
			DEFAULT_CHAT_FRAME:AddMessage("DruidConsumable: Attempting to use "..msg.."!");
		end;
	elseif(consumeType == "health") then
		if(DruidConsumable_canUseConsumable("healthStone")) then UseHealthstone();
		elseif(DruidConsumable_canUseConsumable("healthPotion")) then UseHealthPotion();
		elseif(DruidConsumable_canUseConsumable("whipper root")) then DruidConsumable_UseNightDragonOrRune("whipper root");
		end;
	elseif(consumeType == "juju") then
		if(DruidConsumable_canUseConsumable("juju")) then 
			UseItemInBag("Juju Flurry", 1);
			DEFAULT_CHAT_FRAME:AddMessage("DruidConsumable: Attempting to use Juju Flurry.");
		end;
	elseif(consumeType == "sand") then
		if(DruidConsumable_canUseConsumable("sand")) then 
			UseItemInBag("Hourglass Sand", 1);
			DEFAULT_CHAT_FRAME:AddMessage("DruidConsumable: Attempting to use Hourglass Sand.");
		end;
	end;
end;
			
function DruidConsumable_canUseConsumable(consumableType)
	local currentHealth = UnitHealth("player");
	local manaPotion = {'Major Mana Draught', 'Major Mana Potion', 'Combat Mana Potion', 'Superior Mana Potion', 'Greater Mana Potion', 'Mana Potion', 'Lesser Mana Potion', 'Minor Mana Potion'};
	local healthPotion = {'Major Healing Draught', 'Major Healing Potion', 'Combat Healing Potion', 'Superior Healing Potion', 'Greater Healing Potion', 'Healing Potion', 'Lesser Healing Potion', 'Minor Healing Potion'};
	local healthstone = {"Major Healthstone", "Greater Healthstone", "Healthstone", "Lesser Healthstone", "Minor Healthstone"};
	local nightDragon = "Night Dragon's Breath";
	local whipperRoot = "Whipper Root Tuber";
	local demonRune = {"Demonic Rune", "Dark Rune"};
	local lilyRoot = "Lily Root";
	local sapper = "Goblin Sapper Charge";
	local jujuFlurry = "Juju Flurry";
	local found, bag, slot = nil;
	local buffActive, buffIndex, numBuffs = nil;
	
	if(consumableType == "manaPotion") then 
		for i = 1, table.getn(manaPotion), 1
			do
			found, bag, slot = isInBag(manaPotion[i]);
			if(bag ~= nil and slot ~= nil) then 
				_, duration, _ = GetContainerItemCooldown(bag, slot);
				if(duration == 0) then return tostring(manaPotion[i]); end;
			end;
		end;
	elseif(consumableType == "healthPotion") then
		for i = 1, table.getn(healthPotion), 1
			do
			found, bag, slot = isInBag(healthPotion[i]);
			if(bag ~= nil and slot ~= nil) then 
				_, duration, _ = GetContainerItemCooldown(bag, slot);
				if(duration == 0) then return tostring(healthPotion[i]); end;
			end;
		end;
	elseif(consumableType == "healthStone") then
		for i = 1, table.getn(healthstone), 1
			do
			found, bag, slot = isInBag(healthstone[i]);
			if(bag ~= nil and slot ~= nil) then 
				_, duration, _ = GetContainerItemCooldown(bag, slot);
				if(duration == 0) then return tostring(healthstone[i]); end;
			end;
		end;
	elseif(consumableType == "nightdragon") then
		found, bag, slot = isInBag(nightDragon);
		if(bag ~= nil and slot ~= nil) then
			_, duration, _ = GetContainerItemCooldown(bag, slot);
			if(duration == 0) then return tostring(nightDragon); end;
		end;
	elseif(consumableType == "whipper root") then
		found, bag, slot = isInBag(whipperRoot);
		if(bag ~= nil and slot ~= nil) then
			_, duration, _ = GetContainerItemCooldown(bag, slot);
			if(duration == 0) then return tostring(whipperRoot); end;
		end;
	elseif(consumableType == "lily root") then
		found, bag, slot = isInBag(lilyRoot);
		if(bag ~= nil and slot ~= nil) then
			_, duration, _ = GetContainerItemCooldown(bag, slot);
			if(duration == 0) then return tostring(lilyRoot); end;
		end;
	elseif(consumableType == "rune") then
		for i = 1, table.getn(demonRune), 1
			do
			found, bag, slot = isInBag(demonRune[i]);
			if(bag ~= nil and slot ~= nil) then
				_, duration, _ = GetContainerItemCooldown(bag, slot);
				if(duration == 0 and currentHealth > 1502) then return tostring(demonRune[i]); end;
			end;
		end;
	elseif(consumableType == "sapper") then
		found, bag, slot = isInBag(sapper);
		if(bag ~= nil and slot ~= nil) then
			_, duration, _ = GetContainerItemCooldown(bag, slot);
			if(duration == 0) then return tostring(sapper); end;
		end;
	elseif(consumableType == "juju") then
		buffActive, buffIndex, numBuffs = isBuffNameActive(jujuFlurry, "player");
		found, bag, slot = isInBag(jujuFlurry);
		if(buffActive == false and numBuffs >= 32) then
			DEFAULT_CHAT_FRAME:AddMessage("DruidConsumable: Cannot use Juju Flurry due to buff limit.");
		elseif(buffActive == false and numBuffs < 32 and found == true) then
			_, duration, _ = GetContainerItemCooldown(bag, slot);
			if(duration == 0) then return tostring(jujuFlurry); end;
		elseif(buffActive == true and found == true) then
			DEFAULT_CHAT_FRAME:AddMessage("DruidConsumable: Juju Flurry already in use.");
		end;
	elseif(consumableType == "sand") then
		buffActive, buffIndex, numBuffs = isDebuffNameActive("Brood Affliction: Bronze", "player");
		found, bag, slot = isInBag("Hourglass Sand");
		if(buffActive == true and found == true) then
			return tostring("Hourglass Sand");
		end;
	end;
	return nil;
end;

function DruidConsumable_UseNightDragonOrRune(consumableType)
	local nightDragon = "Night Dragon's Breath";
	local whipperRoot = "Whipper Root Tuber";
	local lilyRoot = "Lily Root";
	local demonRune = {"Demonic Rune", "Dark Rune"};
	local msg = nil;
	
	if(consumableType == "lily root") then UseItemInBag(lilyRoot, 1); msg = tostring(lilyRoot);
	elseif(consumableType == "whipper root") then UseItemInBag(whipperRoot, 1); msg = tostring(whipperRoot);
	elseif(consumableType == "nightdragon") then UseItemInBag(nightDragon, 1); msg = tostring(nightDragon);
	elseif(consumableType == "rune") then
		if(isInBag(demonRune[1])) then UseItemInBag(demonRune[1], 1); msg = tostring(demonRune[1]);
		elseif(isInBag(demonRune[2])) then UseItemInBag(demonRune[2], 1); msg = tostring(demonRune[2]);
		end;
	else msg = "No Night Dragon's Breath nor Rune";
	end;	
	DEFAULT_CHAT_FRAME:AddMessage("DruidConsumable: Attempting to use "..msg..".");
end;