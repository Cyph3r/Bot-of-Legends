--[[
 
        Auto Carry Plugin - Ziggs Edition
		Author: Kain
		Version: See version variable below.
		Copyright 2013

		Dependency: Sida's Auto Carry: Revamped
 
		How to install:
			Make sure you already have AutoCarry installed.
			Name the script EXACTLY "SidasAutoCarryPlugin - Ziggs.lua" without the quotes.
			Place the plugin in BoL/Scripts/Common folder.

		Download: https://bitbucket.org/KainBoL/bol/raw/master/Common/SidasAutoCarryPlugin%20-%20Ziggs.lua

		Version History:
			Version: 1.3c:
				Fixed Ultimate Killsteal on Reborn.
			Version: 1.3b: http://pastebin.com/r7be1V6j
				Improved FPS.
				Added dynamic ranges.
				Fixed AFK Killsteal disabling.
				Split menu into two menus.
				Fixed harass firing combo.
				Fixed draw prediction bug.
				Added "BoL Studio Script Updater" url and hash.
			Version: 1.2d: http://pastebin.com/2J8F8XFt
				Added Wall check for Q.
				Added E toggle for Satchel Jump and Harass.
				Added line draw to currently selected target.
				Added auto disable for Killsteal when AFK.
				Cleaned up plugin menu.
			Version: 1.1d: http://pastebin.com/T3rUd14Y
			Version: 1.1c: http://pastebin.com/exXzdFD8
				Improved Satchel Jump to fire more accurately and also in the direction of the mouse position.
				Added low mana handling with the Mana Manager.
				Added Smart Q farming. Uses Q when it can kill multiple minions and mana is higher than the Mana Manager low limit.
				Improved prediction range logic for Q and R.
				Fixed Q to not hit minions as much.
				Added enemy low health logic.
			Version: 1.08: http://pastebin.com/ebB89AnC
			Version: 1.07: http://pastebin.com/Mj7i5k9X
				Added text on screen when Killsteal occurs to make it more noticeable.
				Added slider variable to set Killsteal hitchance/sensitivity.
			Version: 1.06: http://pastebin.com/5j9W654G (7/23/2013)
				Fixed Karthus / Kog'maw, etc. bug where script would try to kill their 'ghost' after they were dead, but still present nearby.
				Added toggle for auto harass.
				Change range color indicators.
			Version: 1.05: http://pastebin.com/CcgW9n27
				Added Satchel Jump.
				Improved "Ultimate Mega Killsteal" calculation. Now operates on a hitchance curve. The further away the target is, the higher the hitchance required to throw the Bomb. Should reduce the number of cross-map misses. Will experiment with the settings after more feedback.
				Removed Satchel from normal combo.
				Added a secondary Full Combo option.
			Version: 1.04: http://pastebin.com/z4nTWmkr
				Fixed Bouncing Bomb for full range prediction. Requires SAC 4.9 or later.
			Version: 1.03 Beta: http://pastebin.com/kZED9bqV
			Version: 1.02 Beta: http://pastebin.com/5CzSRtdL
			Version: 1.01 Beta: http://pastebin.com/hx2RYDaQ
			Version: 1.0 Beta: http://pastebin.com/bGa23bFR
--]]

if myHero.charName ~= "Ziggs" then return end

version = "1.3c"

-- Reborn
if AutoCarry.Skills then IsSACReborn = true else IsSACReborn = false end

-- Disable SAC Reborn's skills. Ours are better.
if IsSACReborn then
	AutoCarry.Skills:DisableAll()
end

local Target

-- Prediction
local QRange = 850
local QMaxRange = 1400
local WRange = 1000
local ERange = 900
local RRange = 5300

local QSpeed = 1.722 -- Old: 1.2
local WSpeed = 1.727 -- Old: 1.5
local ESpeed = 2.694 -- Old: 1.45
local RSpeed = 1.856 -- Old: 1.5

local QDelay = 218
local WDelay = 249
local EDelay = 125
local RDelay = 1014

local QWidth = 150
local WWidth = 225
local EWidth = 250
local RWidth = 550


local SkillQ = {spellKey = _Q, range = QMaxRange, speed = QSpeed, delay = QDelay, width = QWidth, configName = "bouncingbomb", displayName = "Q (Bouncing Bomb)", enabled = true, skillShot = true, minions = true, reset = false, reqTarget = true }
local SkillW = {spellKey = _W, range = WRange, speed = WSpeed, delay = WDelay, width = WWidth, configName = "satchelcharge", displayName = "W (Satchel Charge)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
local SkillE = {spellKey = _E, range = ERange, speed = ESpeed, delay = EDelay, width = EWidth, configName = "hexplosiveminefield", displayName = "E (Hexplosive Minefield)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = false }
local SkillR = {spellKey = _R, range = RRange, speed = RSpeed, delay = RDelay, width = RWidth, configName = "megainfernobomb", displayName = "R (Mega Inferno Bomb)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true }

local KeyQ = string.byte("Q")
local KeyW = string.byte("W")
local KeyE = string.byte("E")
local KeyR = string.byte("R")

local tick = nil
local doUlt = false

-- Draw
local waittxt = {}
local calculationenemy = 1
local floattext = {"Skills not available", "Able to fight", "Killable", "Murder him!"}
local killable = {}

-- Items
local ignite = nil
local DFGSlot, HXGSlot, BWCSlot, SheenSlot, TrinitySlot, LichBaneSlot = nil, nil, nil, nil, nil, nil
local QReady, WReady, EReady, RReady, DFGReady, HXGReady, BWCReady, IReady = false, false, false, false, false, false, false, false

-- Satchel Jump
local satchelChargeExists = false
local pendingSatchelChargeActivation = nil

-- AFK Vars
local afkTick = nil
local lastAFKStatus = false
local myHeroLastPos = nil

-- Debug
local debugMode = false

-- Main

function Menu()
	AutoCarry.PluginMenu:addParam("sep", "----- Ziggs by Kain: v"..version.." -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("Combo", "Combo - Default Spacebar", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("FullCombo", "Full Combo", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Z"))
	AutoCarry.PluginMenu:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	AutoCarry.PluginMenu:addParam("SatchelJump", "Satchel Jump", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
	AutoCarry.PluginMenu:addParam("AutoHarass", "Auto Harass (Mana Intensive)", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("ManaManager", "Mana Manager %", SCRIPT_PARAM_SLICE, 40, 0, 100, 2)
	AutoCarry.PluginMenu:addParam("Ultimate", "Use Ultimate with Combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("Killsteal", "Ultimate Mega Killsteal", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("SmartFarmWithQ", "Smart Farm With Q", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("sep", "----- [ Draw ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("DrawKillablEenemy", "Draw Killable Enemy", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("DrawText", "Draw Text", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("DrawPrediction", "Draw Prediction", SCRIPT_PARAM_ONOFF, true)

	ZiggsExtraConfig = scriptConfig("Sida's Auto Carry: Ziggs Extra", "Ziggs")

	ZiggsExtraConfig:addParam("DisableDraw", "Disable Draw Ranges", SCRIPT_PARAM_ONOFF, false)
	ZiggsExtraConfig:addParam("DrawFurthest", "Draw Furthest Spell Available", SCRIPT_PARAM_ONOFF, true)
	ZiggsExtraConfig:addParam("DrawQ", "Draw Bouncing Bomb", SCRIPT_PARAM_ONOFF, true)
	ZiggsExtraConfig:addParam("DrawW", "Draw Satchel Charge", SCRIPT_PARAM_ONOFF, true)
	ZiggsExtraConfig:addParam("DrawE", "Draw Hexplosive Minefield", SCRIPT_PARAM_ONOFF, true)
	ZiggsExtraConfig:addParam("DrawR", "Draw Mega Inferno Bomb", SCRIPT_PARAM_ONOFF, true)

	ZiggsExtraConfig:addParam("sep", "----- [ Advanced ] -----", SCRIPT_PARAM_INFO, "")
	ZiggsExtraConfig:addParam("AvoidWallsWithQ", "Avoid Hitting Walls with Q (Beta)", SCRIPT_PARAM_ONOFF, false)
	ZiggsExtraConfig:addParam("SatchelJumpWithE", "Satchel Jump with E", SCRIPT_PARAM_ONOFF, true)
	ZiggsExtraConfig:addParam("HarassWithE", "Harass with E", SCRIPT_PARAM_ONOFF, false)
	ZiggsExtraConfig:addParam("KillstealMinHitchance", "Killsteal Min. Req. Hitchance", SCRIPT_PARAM_SLICE, 60, 0, 90, 0)
	ZiggsExtraConfig:addParam("AFKKillstealDisable", "AFK Killsteal Disable", SCRIPT_PARAM_ONOFF, true)
	ZiggsExtraConfig:addParam("AFKKillstealDisableSeconds", "AFK Killsteal Disable Seconds", SCRIPT_PARAM_SLICE, 120, 10, 600, 0)
end

function PluginOnLoad()
	Menu()

	AutoCarry.SkillsCrosshair.range = QMaxRange

	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then ignite = SUMMONER_2 end
	for i=1, heroManager.iCount do waittxt[i] = i*3 end
end

function IsSummonerAFK()
	-- Mark as AFK
	if not myHeroLastPos or not tick or not afkTick or myHero.x ~= myHeroLastPos.x or myHero.z ~= myHeroLastPos.z then
		myHeroLastPos = {x=myHero.x, y=myHero.y, z=myHero.z}
		afkTick = tick
		SummonerAFKNotify(false)
		return false
	elseif ZiggsExtraConfig.AFKKillstealDisable and tick > (afkTick + (ZiggsExtraConfig.AFKKillstealDisableSeconds * 1000)) and myHero.x == myHeroLastPos.x and myHero.z == myHeroLastPos.z then
		SummonerAFKNotify(true)
		return true
	end

	SummonerAFKNotify(false)
	return false
end

function SummonerAFKNotify(afk)
	if lastAFKStatus and not afk then
		PrintChat("Welcome back! Killsteal Enabled.")
		lastAFKStatus = false
	elseif afk and not lastAFKStatus then
		PrintChat("You are AFK. Killsteal temporarily Disabled.")
		lastAFKStatus = true
	end
end

function PluginOnTick()
	tick = GetTickCount()
	Target = AutoCarry.GetAttackTarget(true)

	if IsTickReady(500) then IsSummonerAFK() end

	SpellCheck()

	if IsTickReady(200) then
		CalculateDamage()
	end

	if AutoCarry.PluginMenu.SatchelJump then
		SatchelJump()
	end

	if AutoCarry.MainMenu.AutoCarry then
		Combo()
	end
	
	if AutoCarry.PluginMenu.FullCombo then
		FullCombo()
	end

	if AutoCarry.PluginMenu.Harass then
		Harass()
	end

	if AutoCarry.PluginMenu.Killsteal and IsTickReady(60) and not lastAFKStatus then
		KillSteal()
	end
	
	if (AutoCarry.MainMenu.LaneClear or AutoCarry.MainMenu.MixedMode) and IsTickReady(40) and AutoCarry.PluginMenu.SmartFarmWithQ and not IsMyManaLow() then
		SmartFarmWithQ()
	end
end

function IsTickReady(tickFrequency)
	-- Improves FPS
	if tick ~= nil and math.fmod(tick, tickFrequency) == 0 then
		return true
	else
		return false
	end
end

function PluginOnCreateObj(obj)
	if obj.name == "ZiggsW_mis_ground.troy" then
		satchelChargeExists = true
		CastWActivate()
	end
end

function PluginOnDeleteObj(obj)
	if obj.name == "ZiggsW_mis_ground.troy" then
		satchelChargeExists = false
		pendingSatchelChargeActivation = nil
	end
end

function OnAttacked()
	-- Auto AA > Q > AA
	if AutoCarry.PluginMenu.AutoHarass and not IsMyManaLow() then
		CastQ()
	end
end

function SpellCheck()
	DFGSlot, HXGSlot, BWCSlot, SheenSlot, TrinitySlot, LichBaneSlot = GetInventorySlotItem(3128),
	GetInventorySlotItem(3146), GetInventorySlotItem(3144), GetInventorySlotItem(3057),
	GetInventorySlotItem(3078), GetInventorySlotItem(3100)

	QReady = (myHero:CanUseSpell(SkillQ.spellKey) == READY)
	WReady = (myHero:CanUseSpell(SkillW.spellKey) == READY)
	EReady = (myHero:CanUseSpell(SkillE.spellKey) == READY)
	RReady = (myHero:CanUseSpell(SkillR.spellKey) == READY)

	DFGReady = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
	HXGReady = (HXGSlot ~= nil and myHero:CanUseSpell(HXGSlot) == READY)
	BWCReady = (BWCSlot ~= nil and myHero:CanUseSpell(BWCSlot) == READY)
	IReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
end

-- Handle SBTW Skill Shots

function Combo()
	CastSlots()

	if not IsMyManaLow() or IsTargetHealthLow() then
		CastE()
	end

	CastQ()
	Ultimate()
end

function Ultimate()
	if Target ~= nil and AutoCarry.PluginMenu.Ultimate and (doUlt or ((Target.health + 30) < getDmg("R", Target, myHero) and IsValidHitChanceCustom(SkillR, Target))) then
		CastR()
	end
end

function FullCombo()
	CastSlots()
	CastE()
	CastQ()
	CastW()
	CastWActivate()
	Ultimate()
end

function CastSlots()
	if Target ~= nil and not Target.dead then
		if GetDistance(Target) <= QMaxRange then
			if DFGReady then CastSpell(DFGSlot, Target) end
			if HXGReady then CastSpell(HXGSlot, Target) end
			if BWCReady then CastSpell(BWCSlot, Target) end
		end
	end
end

function Harass()
	CastQ()
	if ZiggsExtraConfig.HarassWithE then CastE() end
end

function CastQ()
	if Target ~= nil and not Target.dead then
		if QReady and ValidTarget(Target, QRange) and IsQWallCheckOK(Target) then
			AutoCarry.CastSkillshot(SkillQ, Target)
		elseif QReady and ValidTarget(Target, QMaxRange) then
			-- Full Bouncing Bomb three bounce range
			local PredictedPos = AutoCarry.GetPrediction(SkillQ, Target)

			if PredictedPos and AutoCarry.IsValidHitChance(SkillQ, Target) then
				local MyPos = Vector(myHero.x, myHero.y, myHero.z)
				local EnemyPos = Vector(PredictedPos.x, PredictedPos.y, PredictedPos.z)
				local CastPos = MyPos - (MyPos - EnemyPos):normalized() * QRange
				if CastPos and GetDistance(CastPos) < QMaxRange and IsQWallCheckOK(CastPos) and IsQWallCheckOK(EnemyPos) then
					-- CastSpell(SkillQ.spellKey, CastPos.x, CastPos.z)
					CastSkillshotBounce(SkillQ, CastPos)
				end
			end
		end
	end
end

function IsQWallCheckOK(position)
	if position and not ZiggsExtraConfig.AvoidWallsWithQ or (ZiggsExtraConfig.AvoidWallsWithQ and not IsWall(D3DXVECTOR3(position.x, myHero.y, position.z))) then
		return true
	else
		return false
	end
end

function CastSkillshotBounce(skill, castPos)
	if castPos and GetDistance(castPos) <= skill.range then
		if not skill.minions or not AutoCarry.GetCollision(skill, myHero, castPos) then
			CastSpell(skill.spellKey, castPos.x, castPos.z)
		end
	end
end

function CastW(noTarget)
	if noTarget and WReady then
		-- Find vector from mousePos -> myHero
		local vectorX,y,vectorZ = (Vector(myHero) - Vector(mousePos)):normalized():unpack()

		-- Cast Satchel behind myHero by specified distance, where behind is determined relative to mousePos -> myHero vector.
		-- if hasBuff("Speed Shrine") then satchelDistance should be less, like 50.
		local satchelDistance = 125
		local posX = myHero.x + (vectorX * satchelDistance)
		local posZ = myHero.z + (vectorZ * satchelDistance)
		CastSpell(SkillW.spellKey, posX, posZ)
	elseif Target ~= nil and ValidTarget(Target, WRange) and not Target.dead then
		if WReady and GetDistance(Target) <= WRange then
			AutoCarry.CastSkillshot(SkillW, Target)
		end
	end
end

function CastWActivate()
	if satchelChargeExists and pendingSatchelChargeActivation ~= nil then
		if pendingSatchelChargeActivation == "satcheljump" then
			-- Old delay method
			-- local delayTime = 100
			-- local endClockTime = GetTickCount() + delayTime
			-- while (GetTickCount() < endClockTime) do
			--	-- Sleep
			-- end

			CastSpell(SkillW.spellKey)
			if ZiggsExtraConfig.SatchelJumpWithE then CastE() end
			pendingSatchelChargeActivation = nil
		end
	end
end

function CastE()
	if Target ~= nil and ValidTarget(Target, ERange) and not Target.dead then
		if EReady and GetDistance(Target) <= ERange then
			AutoCarry.CastSkillshot(SkillE, Target)
		end
	end
end

function CastR()
	if Target ~= nil and ValidTarget(Target, RRange) and not Target.dead then
		-- if RReady and GetDistance(Target) <= RRange then
		enemyPos = AutoCarry.GetPrediction(SkillR, Target)
		if RReady and enemyPos and ValidTarget(enemyPos, RRange) then
			AutoCarry.CastSkillshot(SkillR, Target)
		end
	end
end

function KillSteal()
	if ZiggsExtraConfig.AFKKillstealDisable and lastAFKStatus then return false end

	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, RRange) and not enemy.dead then
			if (enemy.health + 30) < getDmg("R", enemy, myHero) and IsValidHitChanceCustom(SkillR, enemy) then
				enemyPos = AutoCarry.GetPrediction(SkillR, enemy)
				if RReady and GetDistance(enemy) < RRange then
					-- Message.AddMessage("Killsteal!", ColorARGB.Green, myHero)
					PrintFloatText(myHero, 10, "Ultimate Mega Killsteal!")
					if debugMode then PrintChat("Ultimate Mega Killsteal!") end
					if IsSACReborn then
						AutoCarry.CastSkillshot(SkillR, enemy)
					else
						local enemyPos = AutoCarry.GetPrediction(SkillR, enemy)
						if enemyPos and GetDistance(enemyPos) < RRange then
							AutoCarry.CastSkillshot(SkillR, enemy)
						end
					end
				end
			end
		end
	end
end

function SatchelJump()
	-- E is cast before and after jump to insure that a target near either location can be hit.
	pendingSatchelChargeActivation = "satcheljump"
	CastW(true)
	if ZiggsExtraConfig.SatchelJumpWithE then CastE() end
end

function SmartFarmWithQOld()
	local minions = {}
	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion) and QReady and GetDistance(minion) <= QMaxRange then
			if minion.health < getDmg("Q", minion, myHero) then 
				table.insert(minions, minion)
			end
		end
	end

	local pos1 = {x=0,z=0}
	local pos1Count = 0
	local pos2 = {x=0,z=0}
	local pos2Count = 0

	local closeMinion = QWidth * 1.5

	for _, minion in pairs(minions) do
		if pos1Count == 0 then
			pos1.x = minion.x
			pos1.z = minion.z
			pos1Count = 1
		elseif GetDistance(pos1, minion) < closeMinion then
			pos1.x = ((pos1.x * pos1Count) + minion.x) / (pos1Count + 1)
			pos1.z = ((pos1.z * pos1Count) + minion.z) / (pos1Count + 1)
			pos1Count = pos1Count + 1
		elseif pos2Count == 0 then
			pos2.x = minion.x
			pos2.z = minion.z
			pos2Count = 1
		elseif GetDistance(pos1, minion) < closeMinion then
			pos2.x = ((pos2.x * pos2Count) + minion.x) / (pos2Count + 1)
			pos2.z = ((pos2.z * pos2Count) + minion.z) / (pos2Count + 1)
			pos2Count = pos2Count + 1
		end
	end

	if debugMode and (pos1Count > 1 or pos2Count > 1) then
		PrintChat("pos1Count: "..pos1Count..", pos2Count: "..pos2Count)
	end

	if pos1Count > pos2Count and pos1Count >= 2 then
		CastSpell(SkillQ.spellKey, pos1.x, pos1.z)
	elseif pos2Count >= 2 then
		CastSpell(SkillQ.spellKey, pos2.x, pos2.z)
	end
end

function SmartFarmWithQ()
	local minions = {}
	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion) and QReady and GetDistance(minion) <= QMaxRange then
			if minion.health < getDmg("Q", minion, myHero) then 
				table.insert(minions, minion)
			end
		end
	end

	local minionClusters = {}

	local closeMinion = QWidth * 1.5

	for _, minion in pairs(minions) do
		local foundCluster = false
		for i, mc in ipairs(minionClusters) do
			if GetDistance(mc, minion) < closeMinion then
				mc.x = ((mc.x * mc.count) + minion.x) / (mc.count + 1)
				mc.z = ((mc.z * mc.count) + minion.z) / (mc.count + 1)
				mc.count = mc.count + 1
				foundCluster = true
				break
			end
		end

		if not foundCluster then
			local mc = {x=0, z=0, count=0}
			mc.x = minion.x
			mc.z = minion.z
			mc.count = 1
			table.insert(minionClusters, mc)
		end
	end

	if #minionClusters < 1 then return end

	local largestCluster = 0
	local largestClusterSize = 0
	for i, mc in ipairs(minionClusters) do
		if mc.count > largestClusterSize then
			largestCluster = i
			largestClusterSize = mc.count
		end
	end

	if debugMode and largestClusterSize >= 2 then
		PrintChat("totalClusters: "..#minionClusters..", largestCluster: "..largestCluster..", largestClusterSize: "..largestClusterSize)
	end

	if largestClusterSize >= 2 then
		minionCluster = minionClusters[largestCluster]
		
		-- Needs to be in OnDraw to function.
		-- local minionClusterPoint = {x=minionCluster.x, y=myHero.y, z=minionCluster.z}
		-- DrawArrowsToPos(myHero, minionClusterPoint)

		CastSpell(SkillQ.spellKey, minionCluster.x, minionCluster.z)
	end

	minions = nil
	minionClusters = nil
end

function IsMyManaLow()
	if myHero.mana < (myHero.maxMana * ( AutoCarry.PluginMenu.ManaManager / 100)) then
		return true
	else
		return false
	end
end

function IsTargetHealthLow()
	local targetLowHealth = .40

	if Target ~= nil and Target.health < (Target.maxHealth * targetLowHealth) then
		return true
	else
		return false
	end
end

function IsTargetManaLow()
	local targetLowMana = .15

	if Target ~= nil and Target.mana < (Target.maxMana * targetLowMana) then
		return true
	else
		return false
	end
end

-- Sliding scale hitchance based on target distance.
function getScalingHitChanceFromDistance(SkillRange, Target)
	local minHitChance = ZiggsExtraConfig.KillstealMinHitchance
	local maxHitChance = 95

	hitChance = minHitChance + ((1 - (SkillRange - GetDistance(Target)) / (SkillRange - 0))) * (maxHitChance - minHitChance)
	if debugMode then PrintChat("HitChance Info: skillrange="..SkillRange..", targetdistance="..GetDistance(Target)..", hitchance:"..hitChance) end
	return hitChance
end

function IsValidHitChanceCustom(skill, target)
	if VIP_USER then
		pred = TargetPredictionVIP(skill.range, skill.speed*1000, skill.delay/1000, skill.width)
		return pred:GetHitChance(target) > getScalingHitChanceFromDistance(skill.range, target)/100 and true or false
	elseif not VIP_USER then
		local nonVIPMaxHitChance = 70
		return getScalingHitChanceFromDistance(skill.range, target) < nonVIPMaxHitChance and true or false
	end
end

--[[
function satchelChargeExistsDelete()
	for i=1, objManager.maxObjects do
		local obj = objManager:getObject(i)

		if obj ~= nil and obj.name:find("Satchel Charge") then
			return true
		end
	end	
	return false
end
--]]

-- Handle Manual Skill Shots

function PluginOnWndMsg(msg,key)
	Target = AutoCarry.GetAttackTarget()
	if Target ~= nil then
		if msg == KEY_DOWN and key == KeyQ then CastQ() end
		if msg == KEY_DOWN and key == KeyW then CastW() end
		if msg == KEY_DOWN and key == KeyE then CastE() end
		if msg == KEY_DOWN and key == KeyR then CastR() end
	end
end

-- Draw
function PluginOnDraw()
	if Target ~= nil and not Target.dead and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
		DrawArrowsToPos(myHero, Target)
	end

	if not ZiggsExtraConfig.DisableDraw and not myHero.dead then
		local farSpell = FindFurthestReadySpell()
		-- if debugMode and farSpell then PrintChat("far: "..farSpell.configName) end

		-- Not needed as SAC has the same range draw.
		-- DrawCircle(myHero.x, myHero.y, myHero.z, getTrueRange(), 0x808080) -- Gray

		if ZiggsExtraConfig.DrawQ and QReady and ((ZiggsExtraConfig.DrawFurthest and farSpell and farSpell == SkillQ) or not ZiggsExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, QMaxRange, 0x0099CC) -- Blue
		end

		if ZiggsExtraConfig.DrawW and WReady and ((ZiggsExtraConfig.DrawFurthest and farSpell and farSpell == SkillW) or not ZiggsExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, WRange, 0xFFFF00) -- Yellow
		end
		
		if ZiggsExtraConfig.DrawE and EReady and ((ZiggsExtraConfig.DrawFurthest and farSpell and farSpell == SkillE) or not ZiggsExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0x00FF00) -- Green
		end

		if ZiggsExtraConfig.DrawR and RReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0xFF0000) -- Red
		end

		Target = AutoCarry.GetAttackTarget()
		if Target ~= nil then
			for j=0, 10 do
				DrawCircle(Target.x, Target.y, Target.z, 40 + j*1.5, 0x00FF00) -- Green
			end
		end
	end

	DrawKillable()
end

function FindFurthestReadySpell()
	local farSpell = nil

	if ZiggsExtraConfig.DrawW and WReady then farSpell = SkillW end
	if ZiggsExtraConfig.DrawE and EReady and (not farSpell or ERange > farSpell.range) then farSpell = SkillE end
	if ZiggsExtraConfig.DrawQ and QReady and (not farSpell or QMaxRange > farSpell.range) then farSpell = SkillQ end

	return farSpell
end

function getTrueRange()
    return myHero.range + GetDistance(myHero.minBBox)
end

function DrawArrowsToPos(pos1, pos2)
	if pos1 and pos2 then
		startVector = D3DXVECTOR3(pos1.x, pos1.y, pos1.z)
		endVector = D3DXVECTOR3(pos2.x, pos2.y, pos2.z)
		-- directionVector = (endVector-startVector):normalized()
		DrawArrows(startVector, endVector, 60, 0xE97FA5, 100)
	end
end

function CalculateDamage()
        if ValidTarget(Target) then
                local dfgdamage, hxgdamage, bwcdamage, ignitedamage, Sheendamage, Trinitydamage, LichBanedamage  = 0, 0, 0, 0, 0, 0, 0
                local pdamage = getDmg("P",Target,myHero)
                local qdamage = getDmg("Q",Target,myHero)
                local wdamage = getDmg("W",Target,myHero)
                local edamage = getDmg("E",Target,myHero)
                local rdamage = getDmg("R",Target,myHero)
                local hitdamage = getDmg("AD",Target,myHero)
                local dfgdamage = (DFGSlot and getDmg("DFG",Target,myHero) or 0)
                local hxgdamage = (HXGSlot and getDmg("HXG",Target,myHero) or 0)
                local bwcdamage = (BWCSlot and getDmg("BWC",Target,myHero) or 0)
                local ignitedamage = (ignite and getDmg("IGNITE",Target,myHero) or 0)
                local Sheendamage = (SheenSlot and getDmg("SHEEN",Target,myHero) or 0)
                local Trinitydamage = (TrinitySlot and getDmg("TRINITY",Target,myHero) or 0)
                local LichBanedamage = (LichBaneSlot and getDmg("LICHBANE",Target,myHero) or 0)
                local combo1 = hitdamage + qdamage + wdamage + edamage + rdamage + Sheendamage + Trinitydamage + LichBanedamage --0 cd
                local combo2 = hitdamage + Sheendamage + Trinitydamage + LichBanedamage
                local combo3 = hitdamage + Sheendamage + Trinitydamage + LichBanedamage
                local combo4 = 0
               
                if QREADY then
                        combo2 = combo2 + qdamage
                        combo3 = combo3 + qdamage
                        --combo4 = combo4 + qdamage
                end
                if WREADY then
                        combo2 = combo2 + wdamage
                        combo3 = combo3 + wdamage
                end
                if EREADY then
                        combo2 = combo2 + edamage
                        combo3 = combo3 + edamage
                        --combo4 = combo4 + edamage
                end
                if RREADY then
                        combo2 = combo2 + rdamage
                        combo3 = combo3 + rdamage
                        combo4 = combo4 + rdamage
                end
                if DFGREADY then        
                        combo1 = combo1 + dfgdamage            
                        combo2 = combo2 + dfgdamage
                        combo3 = combo3 + dfgdamage
                        --combo4 = combo4 + dfgdamage
                end
                if HXGREADY then              
                        combo1 = combo1 + hxgdamage    
                        combo2 = combo2 + hxgdamage
                        combo3 = combo3 + hxgdamage
                        --combo4 = combo4 + hxgdamage
                end
                if BWCREADY then
                        combo1 = combo1 + bwcdamage
                        combo2 = combo2 + bwcdamage
                        combo3 = combo3 + bwcdamage
                        combo4 = combo4 + bwcdamage
                end
                if IREADY then
                        combo1 = combo1 + ignitedamage
                        combo2 = combo2 + ignitedamage
                        combo3 = combo3 + ignitedamage
                end
                if combo4 >= Target.health then killable[calculationenemy] = 4 doUlt = true
                elseif combo3 >= Target.health then killable[calculationenemy] = 3 doUlt = false
                elseif combo2 >= Target.health then killable[calculationenemy] = 2 doUlt = false
                elseif combo1 >= Target.health then killable[calculationenemy] = 1  doCombo = true doUlt = false
                else killable[calculationenemy] = 0 doCombo = false doUlt = false end
        end
        if calculationenemy == 1 then calculationenemy = heroManager.iCount
        else calculationenemy = calculationenemy-1 end
end

function DrawKillable()
	-- if 1 == 2 and Target ~= nil and AutoCarry.PluginMenu.DrawPrediction then -- QQQ
	if Target ~= nil and AutoCarry.PluginMenu.DrawPrediction then
		if VIP_USER then
			pred = TargetPredictionVIP(SkillQ.range, SkillQ.speed*1000, SkillQ.delay/1000, SkillQ.width)
		elseif not VIP_USER then
			pred = TargetPrediction(SkillQ.range, SkillQ.speed, SkillQ.delay, SkillQ.width)
		end
		
		if pred then
			predPos = pred:GetPrediction(Target)
			if predPos then
				DrawCircle(predPos.x, Target.y, predPos.z, 200, 0x0000FF)
			end
		end
	end
	for i=1, heroManager.iCount do
		local enemydraw = heroManager:GetHero(i)
		if ValidTarget(enemydraw) then
			if AutoCarry.PluginMenu.DrawKillablEenemy then
				if killable[i] == 1 then
					for j=0, 20 do
						DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80 + j*1.5, 0x0000FF)
					end
				elseif killable[i] == 2 then
					for j=0, 10 do
						DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80 + j*1.5, 0xFF0000)
					end
				elseif killable[i] == 3 then
					for j=0, 10 do
						DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80 + j*1.5, 0xFF0000)
						DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 110 + j*1.5, 0xFF0000)
					end
				elseif killable[i] == 4 then
					for j=0, 10 do
						DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80 + j*1.5, 0xFF0000)
						DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 110 + j*1.5, 0xFF0000)
						DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 140 + j*1.5, 0xFF0000)
					end
				end
			end
			if AutoCarry.PluginMenu.DrawText and waittxt ~= nil and waittxt[i] == 1 and killable ~= nil and killable[i] ~= 0 then
					PrintFloatText(enemydraw,0,floattext[killable[i]])
			end
		end
		if waittxt ~= nil then
			if waittxt[i] == 1 then waittxt[i] = 30
			else waittxt[i] = waittxt[i]-1 end
		end
	end
end

--[[
class 'ColorARGB' -- {

    function ColorARGB:__init(red, green, blue, alpha)
        self.R = red or 255
        self.G = green or 255
        self.B = blue or 255
        self.A = alpha or 255
    end

    function ColorARGB.FromArgb(red, green, blue, alpha)
        return Color(red,green,blue, alpha)
    end

    function ColorARGB:ToARGB()
        return ARGB(self.A, self.R, self.G, self.B)
    end

    ColorARGB.Red = ColorARGB(255, 0, 0, 255)
    ColorARGB.Yellow = ColorARGB(255, 255, 0, 255)
    ColorARGB.Green = ColorARGB(0, 255, 0, 255)
    ColorARGB.Aqua = ColorARGB(0, 255, 255, 255)
    ColorARGB.Blue = ColorARGB(0, 0, 255, 255)
    ColorARGB.Fuchsia = ColorARGB(255, 0, 255, 255)
    ColorARGB.Black = ColorARGB(0, 0, 0, 255)
    ColorARGB.White = ColorARGB(255, 255, 255, 255)
-- }

--Notification class
class 'Message' -- {

    Message.instance = ""

    function Message:__init()
        self.notifys = {} 

        AddDrawCallback(function(obj) self:OnDraw() end)
    end

    function Message.Instance()
        if Message.instance == "" then Message.instance = Message() end return Message.instance 
    end

    function Message.AddMessage(text, color, target)
        return Message.Instance():PAddMessage(text, color, target)
    end

    function Message:PAddMessage(text, color, target)
        local x = 0
        local y = 200 
        local tempName = "Screen" 
        local tempcolor = color or ColorARGB.Red

        if target then  
            tempName = target.networkID
        end

        self.notifys[tempName] = { text = text, color = tempcolor, duration = GetGameTimer() + 2, object = target}
    end

    function Message:OnDraw()
        for i, notify in pairs(self.notifys) do
            if notify.duration < GetGameTimer() then notify = nil 
            else
                notify.color.A = math.floor((255/2)*(notify.duration - GetGameTimer()))

                if i == "Screen" then  
                    local x = 0
                    local y = 200
                    local gameSettings = GetGameSettings()
                    if gameSettings and gameSettings.General then 
                        if gameSettings.General.Width then x = gameSettings.General.Width/2 end 
                        if gameSettings.General.Height then y = gameSettings.General.Height/4 - 100 end
                    end  
                    --PrintChat(tostring(notify.color))
                    local p = GetTextArea(notify.text, 40).x 
                    self:DrawTextWithBorder(notify.text, 40, x - p/2, y, notify.color:ToARGB(), ARGB(notify.color.A, 0, 0, 0))
                else    
                    local pos = WorldToScreen(D3DXVECTOR3(notify.object.x, notify.object.y, notify.object.z))
                    local x = pos.x
                    local y = pos.y - 25
					local p = GetTextArea(notify.text, 40).x 

					self:DrawTextWithBorder(notify.text, 30, x- p/2, y, notify.color:ToARGB(), ARGB(notify.color.A, 0, 0, 0))
                end
            end
        end
    end 

    function Message:DrawTextWithBorder(textToDraw, textSize, x, y, textColor, backgroundColor)
        DrawText(textToDraw, textSize, x + 1, y, backgroundColor)
        DrawText(textToDraw, textSize, x - 1, y, backgroundColor)
        DrawText(textToDraw, textSize, x, y - 1, backgroundColor)
        DrawText(textToDraw, textSize, x, y + 1, backgroundColor)
        DrawText(textToDraw, textSize, x , y, textColor)
    end
-- }
--]]

--UPDATEURL=https://bitbucket.org/KainBoL/bol/raw/master/Common/SidasAutoCarryPlugin%20-%20Ziggs.lua
--HASH=EE889CCF9CC2B320A06050F270A8B0E9
