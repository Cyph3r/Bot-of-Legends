--[[
 
        Auto Carry Plugin - Morgana Edition
		Author: Kain
		Version: See version variable below.
		Copyright 2013

		Dependency: Sida's Auto Carry
 
		How to install:
			Make sure you already have AutoCarry installed.
			Name the script EXACTLY "SidasAutoCarryPlugin - Morgana.lua" without the quotes.
			Place the plugin in BoL/Scripts/Common folder.

		Features:

		Download: https://bitbucket.org/KainBoL/bol/raw/master/Common/SidasAutoCarryPlugin%20-%20Morgana.lua

		Version History:
			Version: 1.0e:
				Added "BoL Studio Script Updater" url and hash.

			Version 1.0d: Release

		To Do:
			Auto Exhaust after Q's Dark Binding CC ends.

		Recommended: Use Auto Shield for Ally Shielding.
--]]

if myHero.charName ~= "Morgana" then return end

function Vars()
	version = "1.0e"

	QRange, WRange, ERange, RRange, RMaxRange = 1300, 900, 750, 600, 1050
	WRadius = 175

	AutoCarry.SkillsCrosshair.range = 1800

	SkillQ = {spellKey = _Q, range = QRange, speed = 1.2, delay = 250, width = 70, minions = true}
	SkillW = {spellKey = _W, range = WRange, speed = 1.2, delay = 250, width = 105}

	debugMode = false
end

function Menu()
	AutoCarry.PluginMenu:addParam("sep", "----- Morgana by Kain: v"..version.." -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("sep", "----- [ Combo ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("ComboQ", "Use Dark Binding", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboW", "Use Tormented Soil on Snared Target", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboWGroup", "Use Tormented Soil on Group", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("WEnemyCount", "Min Enemies for Group W", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
	AutoCarry.PluginMenu:addParam("ComboESelf", "Self Black Shield Before Ult", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboR", "Use Soul Shackles", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("RCastRange", "Max Range to Cast R: ", SCRIPT_PARAM_SLICE, 600, 100, 600, 0)
	AutoCarry.PluginMenu:addParam("REnemyCount", "Min Enemies to Cast R: ", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
	AutoCarry.PluginMenu:addParam("sep", "----- [ Killsteal ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("KillstealQ", "Use Dark Binding", SCRIPT_PARAM_ONOFF, true) -- KS with all skills
	AutoCarry.PluginMenu:addParam("KillstealW", "Use Tormented Soil", SCRIPT_PARAM_ONOFF, true) -- KS with all skills
	AutoCarry.PluginMenu:addParam("sep", "----- [ Draw ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("DisableDraw", "Disable Draw", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("DrawFurthest", "Draw Furthest Spell Available", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("DrawTargetArrow", "Draw Arrow to Target", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("DrawQ", "Draw Dark Binding", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("DrawW", "Draw Tormented Soil", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("DrawE", "Draw Black Shield", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("DrawR", "Draw Soul Shackles", SCRIPT_PARAM_ONOFF, true)
end

function PluginOnLoad()
	Vars()
	Menu()
end
-- OnTick funtion
function PluginOnTick()
	SpellCheck()

	Target = AutoCarry.GetAttackTarget(true)

	if AutoCarry.MainMenu.AutoCarry and Target ~= nil then
		if AutoCarry.PluginMenu.ComboQ and Target.canMove then
			CastQ()
		end
		if AutoCarry.PluginMenu.ComboW then CastW() end
		if AutoCarry.PluginMenu.ComboR then
			CastR()
		end

		Killsteal()
	end
end

function SpellCheck()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = ((myHero:CanUseSpell(_R) ~= NOTLEARNED) and (myHero:CanUseSpell(_R) ~= COOLDOWN))
end

function CastQ()
	if QReady and AutoCarry.PluginMenu.ComboQ and not AutoCarry.GetCollision(SkillQ, myHero, Target) then
		AutoCarry.CastSkillshot(SkillQ, Target)
	end
end

function CastW()
	if not Target or not WReady then return false end

	if Target.canMove and EnemyCount(myHero, (SkillW.range + WRadius)) < AutoCarry.PluginMenu.WEnemyCount then return false end

	local spellPos = GetAoESpellPosition(WRadius, Target, SkillW.delay)

	if spellPos and (not Target.canMove or AutoCarry.PluginMenu.ComboWGroup) and GetDistance(spellPos) <= SkillW.range then
		if not Target.canMove or EnemyCount(spellPos, WRadius) >= AutoCarry.PluginMenu.WEnemyCount then
			if debugMode then PrintChat("W AoE") end
			CastSpell(SkillW.spellKey, spellPos.x, spellPos.z)
			return true
		end
	elseif not spellPos and not Target.canMove then
		CastSpell(SkillW.spellKey, Target)
		return true
	end

	return false
end

function Killsteal()
	if not Target then return false end

	if not myHero.dead then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			local QDmg = getDmg("Q", enemy, myHero)
			local WDmg = getDmg("W", enemy, myHero)

			if enemy and not enemy.dead then
				local enemyDistance = GetDistance(enemy)

				if enemyDistance < QRange and enemy.health <= (QDmg) then
					AutoCarry.CastSkillshot(SkillQ, enemy)
				elseif enemyDistance < WRange and enemy.health <= (WDmg) then
					CastSpell(SkillW.spellKey, enemy)
				end
			end
		end
	end
end

function CastR()
	if not Target or not RReady then return false end

	local enemyCount = EnemyCount(myHero, AutoCarry.PluginMenu.RCastRange)
	if RReady and enemyCount >= AutoCarry.PluginMenu.REnemyCount then
		if EReady and AutoCarry.PluginMenu.ComboESelf then
			CastSpell(_E, myHero)
		end
		CastSpell(_R)
	end
end

function EnemyCount(point, range)
	local count = 0

	for _, enemy in pairs(GetEnemyHeroes()) do
		if enemy and not enemy.dead and GetDistance(point, enemy) <= range then
			count = count + 1
		end
	end            

	return count
end

function PluginOnDraw()
	if AutoCarry.PluginMenu.DrawTargetArrow and Target ~= nil and not Target.dead and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
		DrawArrowsToPos(myHero, Target)
	end

	if not AutoCarry.PluginMenu.DisableDraw and not myHero.dead then
		local farSpell = FindFurthestReadySpell()

		-- DrawCircle(myHero.x, myHero.y, myHero.z, getTrueRange(), 0x808080) -- Gray

		if AutoCarry.PluginMenu.DrawQ and QReady and ((AutoCarry.PluginMenu.DrawFurthest and farSpell and farSpell == QRange) or not AutoCarry.PluginMenu.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0x0099CC) -- Blue
		end

		if AutoCarry.PluginMenu.DrawW and WReady and ((AutoCarry.PluginMenu.DrawFurthest and farSpell and farSpell == WRange) or not AutoCarry.PluginMenu.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, WRange, 0xFFFF00) -- Yellow
		end

		if AutoCarry.PluginMenu.DrawE and EReady and ((AutoCarry.PluginMenu.DrawFurthest and farSpell and farSpell == ERange) or not AutoCarry.PluginMenu.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0x00FF00) -- Green
		end

		if AutoCarry.PluginMenu.DrawR and RReady and ((AutoCarry.PluginMenu.DrawFurthest and farSpell and farSpell == RRange) or not AutoCarry.PluginMenu.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0xFF0000) -- Red
		end

		if Target ~= nil then
			for j=0, 10 do
				DrawCircle(Target.x, Target.y, Target.z, 40 + j*1.5, 0x00FF00) -- Green
			end
		end
	end
end

function FindFurthestReadySpell()
	local farSpell = nil

	if AutoCarry.PluginMenu.DrawQ and QReady then farSpell = QRange end
	if AutoCarry.PluginMenu.DrawW and WReady and (not farSpell or WRange > farSpell) then farSpell = WRange end
	if AutoCarry.PluginMenu.DrawE and EReady and (not farSpell or ERange > farSpell) then farSpell = ERange end
	if AutoCarry.PluginMenu.DrawR and RReady and (not farSpell or RRange > farSpell) then farSpell = RRange end

	return farSpell
end

function getTrueRange()
    return myHero.range + GetDistance(myHero.minBBox)
end

function DrawArrowsToPos(pos1, pos2)
	if pos1 and pos2 then
		startVector = D3DXVECTOR3(pos1.x, pos1.y, pos1.z)
		endVector = D3DXVECTOR3(pos2.x, pos2.y, pos2.z)
		DrawArrows(startVector, endVector, 60, 0xE97FA5, 100)
	end
end
 
-- End of Morgana script

--[[ 
	AoE_Skillshot_Position 2.0 by monogato
	
	GetAoESpellPosition(radius, main_target, [delay]) returns best position in order to catch as many enemies as possible with your AoE skillshot, making sure you get the main target.
	Note: You can optionally add delay in ms for prediction (VIP if avaliable, normal else).
]]

function GetCenter(points)
	local sum_x = 0
	local sum_z = 0
	
	for i = 1, #points do
		sum_x = sum_x + points[i].x
		sum_z = sum_z + points[i].z
	end
	
	local center = {x = sum_x / #points, y = 0, z = sum_z / #points}
	
	return center
end

function ContainsThemAll(circle, points)
	local radius_sqr = circle.radius*circle.radius
	local contains_them_all = true
	local i = 1
	
	while contains_them_all and i <= #points do
		contains_them_all = GetDistanceSqr(points[i], circle.center) <= radius_sqr
		i = i + 1
	end
	
	return contains_them_all
end

-- The first element (which is gonna be main_target) is untouchable.
function FarthestFromPositionIndex(points, position)
	local index = 2
	local actual_dist_sqr
	local max_dist_sqr = GetDistanceSqr(points[index], position)
	
	for i = 3, #points do
		actual_dist_sqr = GetDistanceSqr(points[i], position)
		if actual_dist_sqr > max_dist_sqr then
			index = i
			max_dist_sqr = actual_dist_sqr
		end
	end
	
	return index
end

function RemoveWorst(targets, position)
	local worst_target = FarthestFromPositionIndex(targets, position)
	
	table.remove(targets, worst_target)
	
	return targets
end

function GetInitialTargets(radius, main_target)
	local targets = {main_target}
	local diameter_sqr = 4 * radius * radius
	
	for i=1, heroManager.iCount do
		target = heroManager:GetHero(i)
		if target.networkID ~= main_target.networkID and ValidTarget(target) and GetDistanceSqr(main_target, target) < diameter_sqr then table.insert(targets, target) end
	end
	
	return targets
end

function GetPredictedInitialTargets(radius, main_target, delay)
	if VIP_USER and not vip_target_predictor then vip_target_predictor = TargetPredictionVIP(nil, nil, delay/1000) end
	local predicted_main_target = VIP_USER and vip_target_predictor:GetPrediction(main_target) or GetPredictionPos(main_target, delay)
	local predicted_targets = {predicted_main_target}
	local diameter_sqr = 4 * radius * radius
	
	for i=1, heroManager.iCount do
		target = heroManager:GetHero(i)
		if ValidTarget(target) then
			predicted_target = VIP_USER and vip_target_predictor:GetPrediction(target) or GetPredictionPos(target, delay)
			if target.networkID ~= main_target.networkID and GetDistanceSqr(predicted_main_target, predicted_target) < diameter_sqr then table.insert(predicted_targets, predicted_target) end
		end
	end
	
	return predicted_targets
end

-- I don't need range since main_target is gonna be close enough. You can add it if you do.
function GetAoESpellPosition(radius, main_target, delay)
	local targets = delay and GetPredictedInitialTargets(radius, main_target, delay) or GetInitialTargets(radius, main_target)
	local position = GetCenter(targets)
	local best_pos_found = true
	local circle = Circle(position, radius)
	circle.center = position
	
	if #targets > 2 then best_pos_found = ContainsThemAll(circle, targets) end
	
	while not best_pos_found do
		targets = RemoveWorst(targets, position)
		position = GetCenter(targets)
		circle.center = position
		best_pos_found = ContainsThemAll(circle, targets)
	end
	
	return position
end

--UPDATEURL=https://bitbucket.org/KainBoL/bol/raw/master/Common/SidasAutoCarryPlugin%20-%20Morgana.lua
--HASH=ED7EBA638164257DB6AF39927DA939A6
