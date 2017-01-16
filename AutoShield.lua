--[[
	Auto Shield 1.82
		by eXtragoZ
		LoL 3.12 Jinx fix by Kain
	Features:
		- Supports:
			- Shields: Lulu, Janna, Karma, LeeSin, Orianna, Lux, Thresh, JarvanIV, Nautilus, Rumble, Sion, Shen, Skarner, Urgot, Diana, Riven, Morgana, Sivir and Nocturne
			- Items: Locket of the Iron Solari, Seraph's Embrace
			- Summoner Spells: Heal, Barrier
			- Heals: Alistar E, Kayle W, Nami W, Nidalee E, Sona W, Soraka W, Taric Q ,Gangplank W
			- Ultimates: Zilean R, Tryndamere R, Kayle R, Shen R, Lulu R, Soraka R
		- If the skill has immediate damage, the script does not reached to activate the shield/heal/invulnerability
		- In the case that the enemy ability hits multiple allies the script looks for the highest percentage of damage unless it is a skillshot that only hits the first target in that case looks for the closest one from the enemy
		- Press shift to configure	
]]
local typeshield
local spellslot
local typeheal
local healslot
local typeult
local ultslot
if myHero.charName == "Lulu" then
	typeshield = 1
	spellslot = _E
	typeult = 1
	ultslot = _R
elseif myHero.charName == "Janna" then
	typeshield = 1
	spellslot = _E
elseif myHero.charName == "Karma" then
	typeshield = 1
	spellslot = _E
elseif myHero.charName == "LeeSin" then
	typeshield = 1
	spellslot = _W
elseif myHero.charName == "Orianna" then
	typeshield = 1
	spellslot = _E
elseif myHero.charName == "Lux" then
	typeshield = 2
	spellslot = _W
elseif myHero.charName == "Thresh" then
	typeshield = 2
	spellslot = _W
elseif myHero.charName == "JarvanIV" then
	typeshield = 3
	spellslot = _W
elseif myHero.charName == "Nautilus" then
	typeshield = 3
	spellslot = _W
elseif myHero.charName == "Rumble" then
	typeshield = 3
	spellslot = _W
elseif myHero.charName == "Sion" then
	typeshield = 3
	spellslot = _W
elseif myHero.charName == "Shen" then
	typeshield = 3
	spellslot = _W
	typeult = 3
	ultslot = _R
elseif myHero.charName == "Skarner" then
	typeshield = 3
	spellslot = _W
elseif myHero.charName == "Urgot" then
	typeshield = 3
	spellslot = _W
elseif myHero.charName == "Diana" then
	typeshield = 3
	spellslot = _W
-- elseif myHero.charName == "Udyr" then
	-- typeshield = 3
	-- spellslot = _W
elseif myHero.charName == "Riven" then
	typeshield = 4
	spellslot = _E
elseif myHero.charName == "Morgana" then
	typeshield = 5
	spellslot = _E
elseif myHero.charName == "Sivir" then
	typeshield = 6
	spellslot = _E
elseif myHero.charName == "Nocturne" then
	typeshield = 6
	spellslot = _W
elseif myHero.charName == "Alistar" then
	typeheal = 2
	healslot = _E
elseif myHero.charName == "Kayle" then
	typeheal = 1
	healslot = _W
	typeult = 1
	ultslot = _R
elseif myHero.charName == "Nami" then
	typeheal = 1
	healslot = _W
elseif myHero.charName == "Nidalee" then
	typeheal = 1
	healslot = _E
elseif myHero.charName == "Sona" then
	typeheal = 2
	healslot = _W
elseif myHero.charName == "Soraka" then
	typeheal = 1
	healslot = _W
	typeult = 2
	ultslot = _R
elseif myHero.charName == "Taric" then
	typeheal = 1
	healslot = _Q
elseif myHero.charName == "Gangplank" then
	typeheal = 3
	healslot = _W
elseif myHero.charName == "Zilean" then
	typeult = 1
	ultslot = _R
elseif myHero.charName == "Tryndamere" then
	typeult = 4
	ultslot = _R
end

local range = 0
local healrange = 0
local ultrange = 0
local shealrange = 300
local lisrange = 700
local sbarrier = nil
local sheal = nil
local useitems = true
local spelltype = nil
local casttype = nil
local BShield,SShield,Shield,CC = false,false,false,false
local shottype,radius,maxdistance = 0,0,0
local hitchampion = false
--[[		Code		]]

function OnLoad()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerBarrier") then sbarrier = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerBarrier") then sbarrier = SUMMONER_2 end
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerHeal") then sheal = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerHeal") then sheal = SUMMONER_2 end
	if typeshield ~= nil then
		ASConfig = scriptConfig("(AS) Auto Shield", "AutoShield")
		for i=1, heroManager.iCount do
			local teammate = heroManager:GetHero(i)
			if teammate.team == myHero.team then ASConfig:addParam("teammateshield"..i, "Shield "..teammate.charName, SCRIPT_PARAM_ONOFF, true) end
		end
		ASConfig:addParam("maxhppercent", "Max percent of hp", SCRIPT_PARAM_SLICE, 100, 0, 100, 0)	
		ASConfig:addParam("mindmgpercent", "Min dmg percent", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)
		ASConfig:addParam("mindmg", "Min dmg approx", SCRIPT_PARAM_INFO, 0)
		ASConfig:addParam("skillshots", "Shield Skillshots", SCRIPT_PARAM_ONOFF, true)
		ASConfig:addParam("shieldcc", "Auto Shield Hard CC", SCRIPT_PARAM_ONOFF, true)
		ASConfig:addParam("shieldslow", "Auto Shield Slows", SCRIPT_PARAM_ONOFF, true)
		ASConfig:addParam("drawcircles", "Draw Range", SCRIPT_PARAM_ONOFF, true)
		ASConfig:permaShow("mindmg")
	end
	if typeheal ~= nil then
		AHConfig = scriptConfig("(AS) Auto Heal", "AutoHeal")
		for i=1, heroManager.iCount do
			local teammate = heroManager:GetHero(i)
			if teammate.team == myHero.team then AHConfig:addParam("teammateheal"..i, "Heal "..teammate.charName, SCRIPT_PARAM_ONOFF, true) end
		end
		AHConfig:addParam("maxhppercent", "Max percent of hp", SCRIPT_PARAM_SLICE, 100, 0, 100, 0)	
		AHConfig:addParam("mindmgpercent", "Min dmg percent", SCRIPT_PARAM_SLICE, 35, 0, 100, 0)
		AHConfig:addParam("mindmg", "Min dmg approx", SCRIPT_PARAM_INFO, 0)
		AHConfig:addParam("skillshots", "Heal Skillshots", SCRIPT_PARAM_ONOFF, true)
		AHConfig:addParam("drawcircles", "Draw Range", SCRIPT_PARAM_ONOFF, true)
		AHConfig:permaShow("mindmg")
	end
	if typeult ~= nil then
		AUConfig = scriptConfig("(AS) Auto Ultimate", "AutoUlt")
		for i=1, heroManager.iCount do
			local teammate = heroManager:GetHero(i)
			if teammate.team == myHero.team then AUConfig:addParam("teammateult"..i, "Ult "..teammate.charName, SCRIPT_PARAM_ONOFF, false) end
		end
		AUConfig:addParam("maxhppercent", "Max percent of hp", SCRIPT_PARAM_SLICE, 100, 0, 100, 0)	
		AUConfig:addParam("mindmgpercent", "Min dmg percent", SCRIPT_PARAM_SLICE, 100, 0, 100, 0)
		AUConfig:addParam("mindmg", "Min dmg approx", SCRIPT_PARAM_INFO, 0)
		AUConfig:addParam("skillshots", "Skillshots", SCRIPT_PARAM_ONOFF, true)
		AUConfig:addParam("drawcircles", "Draw Range", SCRIPT_PARAM_ONOFF, true)
		AUConfig:permaShow("mindmg")
	end
	if sbarrier ~= nil then
		ASBConfig = scriptConfig("(AS) Auto Summoner Barrier", "AutoSummonerBarrier")
		ASBConfig:addParam("barrieron", "Barrier", SCRIPT_PARAM_ONOFF, false)
		ASBConfig:addParam("maxhppercent", "Max percent of hp", SCRIPT_PARAM_SLICE, 100, 0, 100, 0)
		ASBConfig:addParam("mindmgpercent", "Min dmg percent", SCRIPT_PARAM_SLICE, 95, 0, 100, 0)
		ASBConfig:addParam("mindmg", "Min dmg approx", SCRIPT_PARAM_INFO, 0)
		ASBConfig:addParam("skillshots", "Shield Skillshots", SCRIPT_PARAM_ONOFF, true)
	end
	if sheal ~= nil then
		ASHConfig = scriptConfig("(AS) Auto Summoner Heal", "AutoSummonerHeal")
		for i=1, heroManager.iCount do
			local teammate = heroManager:GetHero(i)
			if teammate.team == myHero.team then ASHConfig:addParam("teammatesheal"..i, "Heal "..teammate.charName, SCRIPT_PARAM_ONOFF, false) end
		end
		ASHConfig:addParam("maxhppercent", "Max percent of hp", SCRIPT_PARAM_SLICE, 100, 0, 100, 0)
		ASHConfig:addParam("mindmgpercent", "Min dmg percent", SCRIPT_PARAM_SLICE, 95, 0, 100, 0)
		ASHConfig:addParam("mindmg", "Min dmg approx", SCRIPT_PARAM_INFO, 0)
		ASHConfig:addParam("skillshots", "Heal Skillshots", SCRIPT_PARAM_ONOFF, true)
	end
	if useitems then
		ASIConfig = scriptConfig("(AS) Auto Shield Items", "AutoShieldItems")
		for i=1, heroManager.iCount do
			local teammate = heroManager:GetHero(i)
			if teammate.team == myHero.team then ASIConfig:addParam("teammateshieldi"..i, "Shield "..teammate.charName, SCRIPT_PARAM_ONOFF, false) end
		end
		ASIConfig:addParam("maxhppercent", "Max percent of hp", SCRIPT_PARAM_SLICE, 100, 0, 100, 0)
		ASIConfig:addParam("mindmgpercent", "Min dmg percent", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
		ASIConfig:addParam("mindmg", "Min dmg approx", SCRIPT_PARAM_INFO, 0)
		ASIConfig:addParam("skillshots", "Shield Skillshots", SCRIPT_PARAM_ONOFF, true)
	end
	PrintChat(" >> Auto Shield 1.8 loaded!")
end

function OnProcessSpell(object,spell)
	if object.team ~= myHero.team and not myHero.dead and not (object.name:find("Minion_") or object.name:find("Odin")) then
		if object.charName and object.charName == "Jinx" then return end

		if typeshield ~= nil then
			if myHero.charName == "Lux" then range = 1075
			else range = myHero:GetSpellData(spellslot).range end
		end
		if typeheal ~= nil then healrange = myHero:GetSpellData(healslot).range end
		if typeult ~= nil then ultrange = myHero:GetSpellData(ultslot).range end
		local leesinW = myHero.charName ~= "LeeSin" or myHero:GetSpellData(_W).name == "BlindMonkWOne"
		local nidaleeE = myHero.charName ~= "Nidalee" or myHero:GetSpellData(_E).name == "PrimalSurge"
		local shieldREADY = typeshield ~= nil and myHero:CanUseSpell(spellslot) == READY and leesinW
		local healREADY = typeheal ~= nil and myHero:CanUseSpell(healslot) == READY and nidaleeE
		local ultREADY = typeult ~= nil and myHero:CanUseSpell(ultslot) == READY
		local sbarrierREADY = sbarrier ~= nil and myHero:CanUseSpell(sbarrier) == READY
		local shealREADY = sheal ~= nil and myHero:CanUseSpell(sheal) == READY
		local lisslot = GetInventorySlotItem(3190)
		local seslot = GetInventorySlotItem(3040)
		local lisREADY = lisslot ~= nil and myHero:CanUseSpell(lisslot) == READY
		local seREADY = seslot ~= nil and myHero:CanUseSpell(seslot) == READY
		local HitFirst = false
		local shieldtarget,SLastDistance,SLastDmgPercent = nil,nil,nil
		local healtarget,HLastDistance,HLastDmgPercent = nil,nil,nil
		local ulttarget,ULastDistance,ULastDmgPercent = nil,nil,nil
		BShield,SShield,Shield,CC = false,false,false,false
		shottype,radius,maxdistance = 0,0,0
		if object.type == "obj_AI_Hero" then
			spelltype, casttype = getSpellType(object, spell.name)
			if casttype == 4 or casttype == 5 then return end
			if spelltype == "BAttack" or spelltype == "CAttack" or spell.name:find("SummonerDot") then
				Shield = true
			elseif spelltype == "Q" or spelltype == "W" or spelltype == "E" or spelltype == "R" or spelltype == "P" or spelltype == "QM" or spelltype == "WM" or spelltype == "EM" then
				if skillShield and spelltype and object and object.charName and not object.dead then
					HitFirst = skillShield[object.charName][spelltype]["HitFirst"]
					BShield = skillShield[object.charName][spelltype]["BShield"]
					SShield = skillShield[object.charName][spelltype]["SShield"]
					Shield = skillShield[object.charName][spelltype]["Shield"]
					CC = skillShield[object.charName][spelltype]["CC"]
					shottype = skillData[object.charName][spelltype]["type"]
					radius = skillData[object.charName][spelltype]["radius"]
					maxdistance = skillData[object.charName][spelltype]["maxdistance"]
				end
			end
		else
			Shield = true
		end
		for i=1, heroManager.iCount do
			local allytarget = heroManager:GetHero(i)
			if allytarget.team == myHero.team and not allytarget.dead and allytarget.health > 0 then
				hitchampion = false
				local allyHitBox = getHitBox(allytarget)
				if shottype == 0 then hitchampion = spell.target and spell.target.networkID == allytarget.networkID
				elseif shottype == 1 then hitchampion = checkhitlinepass(object, spell.endPos, radius, maxdistance, allytarget, allyHitBox)
				elseif shottype == 2 then hitchampion = checkhitlinepoint(object, spell.endPos, radius, maxdistance, allytarget, allyHitBox)
				elseif shottype == 3 then hitchampion = checkhitaoe(object, spell.endPos, radius, maxdistance, allytarget, allyHitBox)
				elseif shottype == 4 then hitchampion = checkhitcone(object, spell.endPos, radius, maxdistance, allytarget, allyHitBox)
				elseif shottype == 5 then hitchampion = checkhitwall(object, spell.endPos, radius, maxdistance, allytarget, allyHitBox)
				elseif shottype == 6 then hitchampion = checkhitlinepass(object, spell.endPos, radius, maxdistance, allytarget, allyHitBox) or checkhitlinepass(object, Vector(object)*2-spell.endPos, radius, maxdistance, allytarget, allyHitBox)
				elseif shottype == 7 then hitchampion = checkhitcone(spell.endPos, object, radius, maxdistance, allytarget, allyHitBox)
				end
				if hitchampion then
					if shieldREADY and ASConfig["teammateshield"..i] and ((typeshield<=4 and Shield) or (typeshield==5 and BShield) or (typeshield==6 and SShield)) then
						if (((typeshield==1 or typeshield==2 or typeshield==5) and GetDistance(allytarget)<=range) or allytarget.isMe) then
							local shieldflag, dmgpercent = shieldCheck(object,spell,allytarget,"shields")
							if shieldflag then
								if HitFirst and (SLastDistance == nil or GetDistance(allytarget,object) <= SLastDistance) then
									shieldtarget,SLastDistance = allytarget,GetDistance(allytarget,object)
								elseif not HitFirst and (SLastDmgPercent == nil or dmgpercent >= SLastDmgPercent) then
									shieldtarget,SLastDmgPercent = allytarget,dmgpercent
								end
							end
						end
					end
					if healREADY and AHConfig["teammateheal"..i] and Shield then
						if ((typeheal==1 or typeheal==2) and GetDistance(allytarget)<=healrange) or allytarget.isMe then
							local healflag, dmgpercent = shieldCheck(object,spell,allytarget,"heals")
							if healflag then
								if HitFirst and (HLastDistance == nil or GetDistance(allytarget,object) <= HLastDistance) then
									healtarget,HLastDistance = allytarget,GetDistance(allytarget,object)
								elseif not HitFirst and (HLastDmgPercent == nil or dmgpercent >= HLastDmgPercent) then
									healtarget,HLastDmgPercent = allytarget,dmgpercent
								end
							end		
						end
					end
					if ultREADY and AUConfig["teammateult"..i] and Shield then
						if typeult==2 or (typeult==1 and GetDistance(allytarget)<=ultrange) or (typeult==4 and allytarget.isMe) or (typeult==3 and not allytarget.isMe) then
							local ultflag, dmgpercent = shieldCheck(object,spell,allytarget,"ult")
							if ultflag then
								if HitFirst and (ULastDistance == nil or GetDistance(allytarget,object) <= ULastDistance) then
									ulttarget,ULastDistance = allytarget,GetDistance(allytarget,object)
								elseif not HitFirst and (ULastDmgPercent == nil or dmgpercent >= ULastDmgPercent) then
									ulttarget,ULastDmgPercent = allytarget,dmgpercent
								end
							end
						end
					end
					if sbarrierREADY and ASBConfig.barrieron and allytarget.isMe and Shield then
						local barrierflag, dmgpercent = shieldCheck(object,spell,allytarget,"barrier")
						if barrierflag then
							CastSpell(sbarrier)
						end
					end
					if shealREADY and ASHConfig["teammatesheal"..i] and Shield then
						if GetDistance(allytarget)<=shealrange then
							local shealflag, dmgpercent = shieldCheck(object,spell,allytarget,"sheals")
							if shealflag then
								CastSpell(sheal)
							end
						end
					end
					if lisREADY and ASIConfig["teammateshieldi"..i] and Shield then
						if GetDistance(allytarget)<=lisrange then
							local lisflag, dmgpercent = shieldCheck(object,spell,allytarget,"items")
							if lisflag then
								CastSpell(lisslot)
							end
						end
					end
					if seREADY and ASIConfig["teammateshieldi"..i] and allytarget.isMe and Shield then
						local seflag, dmgpercent = shieldCheck(object,spell,allytarget,"items")
						if seflag then
							CastSpell(seslot)
						end
					end
				end
			end
		end
		if shieldtarget ~= nil then
			if typeshield==1 or typeshield==5 then CastSpell(spellslot,shieldtarget)
			elseif typeshield==2 or typeshield==4 then CastSpell(spellslot,shieldtarget.x,shieldtarget.z)
			elseif typeshield==3 or typeshield==6 then CastSpell(spellslot) end
		end
		if healtarget ~= nil then
			if typeheal==1 then CastSpell(healslot,healtarget)
			elseif typeheal==2 or typeheal==3 then CastSpell(healslot) end
		end
		if ulttarget ~= nil then
			if typeult==1 or typeult==3 then CastSpell(ultslot,ulttarget)
			elseif typeult==2 or typeult==4 then CastSpell(ultslot) end		
		end
	end	
end

function shieldCheck(object,spell,target,typeused)
	local configused
	if typeused == "shields" then configused = ASConfig
	elseif typeused == "heals" then configused = AHConfig
	elseif typeused == "ult" then configused = AUConfig
	elseif typeused == "barrier" then configused = ASBConfig 
	elseif typeused == "sheals" then configused = ASHConfig
	elseif typeused == "items" then configused = ASIConfig end
	local shieldflag = false
	if (not configused.skillshots and shottype ~= 0) then return false, 0 end
	local adamage = object:CalcDamage(target,object.totalDamage)
	local InfinityEdge,onhitdmg,onhittdmg,onhitspelldmg,onhitspelltdmg,muramanadmg,skilldamage,skillTypeDmg = 0,0,0,0,0,0,0,0

	if object.type ~= "obj_AI_Hero" then
		if spell.name:find("BasicAttack") then skilldamage = adamage
		elseif spell.name:find("CritAttack") then skilldamage = adamage*2 end
	else
		if GetInventoryHaveItem(3186,object) then onhitdmg = getDmg("KITAES",target,object) end
		if GetInventoryHaveItem(3114,object) then onhitdmg = onhitdmg+getDmg("MALADY",target,object) end
		if GetInventoryHaveItem(3091,object) then onhitdmg = onhitdmg+getDmg("WITSEND",target,object) end
		if GetInventoryHaveItem(3057,object) then onhitdmg = onhitdmg+getDmg("SHEEN",target,object) end
		if GetInventoryHaveItem(3078,object) then onhitdmg = onhitdmg+getDmg("TRINITY",target,object) end
		if GetInventoryHaveItem(3100,object) then onhitdmg = onhitdmg+getDmg("LICHBANE",target,object) end
		if GetInventoryHaveItem(3025,object) then onhitdmg = onhitdmg+getDmg("ICEBORN",target,object) end
		if GetInventoryHaveItem(3087,object) then onhitdmg = onhitdmg+getDmg("STATIKK",target,object) end
		if GetInventoryHaveItem(3153,object) then onhitdmg = onhitdmg+getDmg("RUINEDKING",target,object) end
		if GetInventoryHaveItem(3209,object) then onhittdmg = getDmg("SPIRITLIZARD",target,object) end
		if GetInventoryHaveItem(3184,object) then onhittdmg = onhittdmg+80 end
		if GetInventoryHaveItem(3042,object) then muramanadmg = getDmg("MURAMANA",target,object) end
		if spelltype == "BAttack" then
			skilldamage = (adamage+onhitdmg+muramanadmg)*1.07+onhittdmg
		elseif spelltype == "CAttack" then
			if GetInventoryHaveItem(3031,object) then InfinityEdge = .5 end
			skilldamage = (adamage*(2.1+InfinityEdge)+onhitdmg+muramanadmg)*1.07+onhittdmg --fix Lethality
		elseif spelltype == "Q" or spelltype == "W" or spelltype == "E" or spelltype == "R" or spelltype == "P" or spelltype == "QM" or spelltype == "WM" or spelltype == "EM" then
			if GetInventoryHaveItem(3151,object) then onhitspelldmg = getDmg("LIANDRYS",target,object) end
			if GetInventoryHaveItem(3188,object) then onhitspelldmg = getDmg("BLACKFIRE",target,object) end
			if GetInventoryHaveItem(3209,object) then onhitspelltdmg = getDmg("SPIRITLIZARD",target,object) end
			muramanadmg = skillShield[object.charName][spelltype]["Muramana"] and muramanadmg or 0
			if casttype == 1 then
				skilldamage, skillTypeDmg = getDmg(spelltype,target,object,1,spell.level)
			elseif casttype == 2 then
				skilldamage, skillTypeDmg = getDmg(spelltype,target,object,2,spell.level)
			elseif casttype == 3 then
				skilldamage, skillTypeDmg = getDmg(spelltype,target,object,3,spell.level)
			end
			if skillTypeDmg == 2 then
				skilldamage = (skilldamage+adamage+onhitspelldmg+onhitdmg+muramanadmg)*1.07+onhittdmg+onhitspelltdmg
			else
				if skilldamage > 0 then skilldamage = (skilldamage+onhitspelldmg+muramanadmg)*1.07+onhitspelltdmg end
			end
		elseif spell.name:find("SummonerDot") then
			skilldamage = getDmg("IGNITE",target,object)
		end
	end
	local dmgpercent = skilldamage*100/target.health
	local dmgneeded = dmgpercent >= configused.mindmgpercent
	local hpneeded = configused.maxhppercent >= (target.health-skilldamage)*100/target.maxHealth
	
	if dmgneeded and hpneeded then
		shieldflag = true
	elseif typeused == "shields" and ((CC == 2 and configused.shieldcc) or (CC == 1 and configused.shieldslow)) then
		shieldflag = true
	end
	return shieldflag, dmgpercent
end
function getHitBox(hero)
    local hitboxTable = { ['HeimerTGreen'] = 50.0, ['Darius'] = 80.0, ['ZyraGraspingPlant'] = 20.0, ['HeimerTRed'] = 50.0, ['ZyraThornPlant'] = 20.0, ['Nasus'] = 80.0, ['HeimerTBlue'] = 50.0, ['SightWard'] = 1, ['HeimerTYellow'] = 50.0, ['Kennen'] = 55.0, ['VisionWard'] = 1, ['ShacoBox'] = 10, ['HA_AP_Poro'] = 0, ['TempMovableChar'] = 48.0, ['TeemoMushroom'] = 50.0, ['OlafAxe'] = 50.0, ['OdinCenterRelic'] = 48.0, ['Blue_Minion_Healer'] = 48.0, ['AncientGolem'] = 100.0, ['AnnieTibbers'] = 80.0, ['OdinMinionGraveyardPortal'] = 1.0, ['OriannaBall'] = 48.0, ['LizardElder'] = 65.0, ['YoungLizard'] = 50.0, ['OdinMinionSpawnPortal'] = 1.0, ['MaokaiSproutling'] = 48.0, ['FizzShark'] = 0, ['Sejuani'] = 80.0, ['Sion'] = 80.0, ['OdinQuestIndicator'] = 1.0, ['Zac'] = 80.0, ['Red_Minion_Wizard'] = 48.0, ['DrMundo'] = 80.0, ['Blue_Minion_Wizard'] = 48.0, ['ShyvanaDragon'] = 80.0, ['HA_AP_OrderShrineTurret'] = 88.4, ['Heimerdinger'] = 55.0, ['Rumble'] = 80.0, ['Ziggs'] = 55.0, ['HA_AP_OrderTurret3'] = 88.4, ['HA_AP_OrderTurret2'] = 88.4, ['TT_Relic'] = 0, ['Veigar'] = 55.0, ['HA_AP_HealthRelic'] = 0, ['Teemo'] = 55.0, ['Amumu'] = 55.0, ['HA_AP_ChaosTurretShrine'] = 88.4, ['HA_AP_ChaosTurret'] = 88.4, ['HA_AP_ChaosTurretRubble'] = 88.4, ['Poppy'] = 55.0, ['Tristana'] = 55.0, ['HA_AP_PoroSpawner'] = 50.0, ['TT_NGolem'] = 80.0, ['HA_AP_ChaosTurretTutorial'] = 88.4, ['Volibear'] = 80.0, ['HA_AP_OrderTurretTutorial'] = 88.4, ['TT_NGolem2'] = 80.0, ['HA_AP_ChaosTurret3'] = 88.4, ['HA_AP_ChaosTurret2'] = 88.4, ['Shyvana'] = 50.0, ['HA_AP_OrderTurret'] = 88.4, ['Nautilus'] = 80.0, ['ARAMOrderTurretNexus'] = 88.4, ['TT_ChaosTurret2'] = 88.4, ['TT_ChaosTurret3'] = 88.4, ['TT_ChaosTurret1'] = 88.4, ['ChaosTurretGiant'] = 88.4, ['ARAMOrderTurretFront'] = 88.4, ['ChaosTurretWorm'] = 88.4, ['OdinChaosTurretShrine'] = 88.4, ['ChaosTurretNormal'] = 88.4, ['OrderTurretNormal2'] = 88.4, ['OdinOrderTurretShrine'] = 88.4, ['OrderTurretDragon'] = 88.4, ['OrderTurretNormal'] = 88.4, ['ARAMChaosTurretFront'] = 88.4, ['ARAMOrderTurretInhib'] = 88.4, ['ChaosTurretWorm2'] = 88.4, ['TT_OrderTurret1'] = 88.4, ['TT_OrderTurret2'] = 88.4, ['ARAMChaosTurretInhib'] = 88.4, ['TT_OrderTurret3'] = 88.4, ['ARAMChaosTurretNexus'] = 88.4, ['OrderTurretAngel'] = 88.4, ['Mordekaiser'] = 80.0, ['TT_Buffplat_R'] = 0, ['Lizard'] = 50.0, ['GolemOdin'] = 80.0, ['Renekton'] = 80.0, ['Maokai'] = 80.0, ['LuluLadybug'] = 50.0, ['Alistar'] = 80.0, ['Urgot'] = 80.0, ['LuluCupcake'] = 50.0, ['Gragas'] = 80.0, ['Skarner'] = 80.0, ['Yorick'] = 80.0, ['MalzaharVoidling'] = 10.0, ['LuluPig'] = 50.0, ['Blitzcrank'] = 80.0, ['Chogath'] = 80.0, ['Vi'] = 50, ['FizzBait'] = 0, ['Malphite'] = 80.0, ['EliseSpiderling'] = 1.0, ['Dragon'] = 100.0, ['LuluSquill'] = 50.0, ['Worm'] = 100.0, ['redDragon'] = 100.0, ['LuluKitty'] = 50.0, ['Galio'] = 80.0, ['Annie'] = 55.0, ['EliseSpider'] = 50.0, ['SyndraSphere'] = 48.0, ['LuluDragon'] = 50.0, ['Hecarim'] = 80.0, ['TT_Spiderboss'] = 200.0, ['Thresh'] = 55.0, ['ARAMChaosTurretShrine'] = 88.4, ['ARAMOrderTurretShrine'] = 88.4, ['Blue_Minion_MechMelee'] = 65.0, ['TT_NWolf'] = 65.0, ['Tutorial_Red_Minion_Wizard'] = 48.0, ['YorickRavenousGhoul'] = 1.0, ['SmallGolem'] = 80.0, ['OdinRedSuperminion'] = 55.0, ['Wraith'] = 50.0, ['Red_Minion_MechCannon'] = 65.0, ['Red_Minion_Melee'] = 48.0, ['OdinBlueSuperminion'] = 55.0, ['TT_NWolf2'] = 50.0, ['Tutorial_Red_Minion_Basic'] = 48.0, ['YorickSpectralGhoul'] = 1.0, ['Wolf'] = 50.0, ['Blue_Minion_MechCannon'] = 65.0, ['Golem'] = 80.0, ['Blue_Minion_Basic'] = 48.0, ['Blue_Minion_Melee'] = 48.0, ['Odin_Blue_Minion_caster'] = 48.0, ['TT_NWraith2'] = 50.0, ['Tutorial_Blue_Minion_Wizard'] = 48.0, ['GiantWolf'] = 65.0, ['Odin_Red_Minion_Caster'] = 48.0, ['Red_Minion_MechMelee'] = 65.0, ['LesserWraith'] = 50.0, ['Red_Minion_Basic'] = 48.0, ['Tutorial_Blue_Minion_Basic'] = 48.0, ['GhostWard'] = 1, ['TT_NWraith'] = 50.0, ['Red_Minion_MechRange'] = 65.0, ['YorickDecayedGhoul'] = 1.0, ['TT_Buffplat_L'] = 0, ['TT_ChaosTurret4'] = 88.4, ['TT_Buffplat_Chain'] = 0, ['TT_OrderTurret4'] = 88.4, ['OrderTurretShrine'] = 88.4, ['ChaosTurretShrine'] = 88.4, ['WriggleLantern'] = 1, ['ChaosTurretTutorial'] = 88.4, ['TwistedLizardElder'] = 65.0, ['RabidWolf'] = 65.0, ['OrderTurretTutorial'] = 88.4, ['OdinShieldRelic'] = 0, ['TwistedGolem'] = 80.0, ['TwistedSmallWolf'] = 50.0, ['TwistedGiantWolf'] = 65.0, ['TwistedTinyWraith'] = 50.0, ['TwistedBlueWraith'] = 50.0, ['TwistedYoungLizard'] = 50.0, ['Summoner_Rider_Order'] = 65.0, ['Summoner_Rider_Chaos'] = 65.0, ['Ghast'] = 60.0, ['blueDragon'] = 100.0, }
    return (hitboxTable[hero.charName] ~= nil and hitboxTable[hero.charName] ~= 0) and hitboxTable[hero.charName] or 65
end
function OnDraw()
	if typeshield ~= nil then
		if ASConfig.drawcircles and not myHero.dead and (typeshield == 1 or typeshield == 2 or typeshield == 5) then
			DrawCircle(myHero.x, myHero.y, myHero.z, range, 0x19A712)
		end
		ASConfig.mindmg = math.floor(myHero.health*ASConfig.mindmgpercent/100)
	end
	if typeheal ~= nil then
		if AHConfig.drawcircles and not myHero.dead and (typeheal == 1 or typeheal == 2) then
			DrawCircle(myHero.x, myHero.y, myHero.z, healrange, 0x19A712)
		end
		AHConfig.mindmg = math.floor(myHero.health*AHConfig.mindmgpercent/100)
	end
	if typeult ~= nil then
		if AUConfig.drawcircles and not myHero.dead and typeult == 1 then
			DrawCircle(myHero.x, myHero.y, myHero.z, ultrange, 0x19A712)
		end
		AUConfig.mindmg = math.floor(myHero.health*AUConfig.mindmgpercent/100)
	end
	if sbarrier ~= nil then ASBConfig.mindmg = math.floor(myHero.health*ASBConfig.mindmgpercent/100) end
	if sheal ~= nil then ASHConfig.mindmg = math.floor(myHero.health*ASHConfig.mindmgpercent/100) end
	if useitems then ASIConfig.mindmg = math.floor(myHero.health*ASIConfig.mindmgpercent/100) end
end