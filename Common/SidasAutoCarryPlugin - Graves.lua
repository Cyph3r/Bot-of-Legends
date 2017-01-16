--[[
 
        Auto Carry Plugin - Graves Edition
		Author: Kain
		Copyright 2013

		Dependency: Sida's Auto Carry: Revamped
 
		How to install:
			Make sure you already have AutoCarry installed.
			Name the script EXACTLY "SidasAutoCarryPlugin - Graves.lua" without the quotes.
			Place the plugin in BoL/Scripts/Common folder.

		Download: https://bitbucket.org/KainBoL/bol/raw/master/Common/SidasAutoCarryPlugin%20-%20Graves.lua

		Version History:
			Version: 1.01c:
				Combo
				Smart Quickdraw
				True Grit keep alive
				Killsteal combos
				Pro Mode spell buttons
				Multi-hit Ultimate
				Added checks for missing or old collision lib.
				Added "BoL Studio Script Updater" url and hash.
--]]

if myHero.charName ~= "Graves" then return end

-- Check to see if user failed to read the forum...
if VIP_USER then
	if FileExist(SCRIPT_PATH..'Common/Collision.lua') then
		require "Collision"

		if type(Collision) ~= "userdata" then
			PrintChat("Your version of Collision.lua is incorrect. Please install v1.1.1 or later in Common folder.")
			return
		else
			assert(type(Collision.GetHeroCollision) == "function")
		end
	else
		PrintChat("Please install Collision.lua v1.1.1 or later in Common folder.")
		return
	end

	if FileExist(SCRIPT_PATH..'Common/2DGeometry.lua') then
		PrintChat("Please delete 2DGeometry.lua from your Common folder.")
	end
end

function PluginOnLoad()
	Vars()
	Menu()
end

function Vars()
	version = "1.01c"

	tick = nil
	Target = nil

	KeyQ = string.byte("Q")
	KeyW = string.byte("W")
	KeyE = string.byte("E")
	KeyR = string.byte("R")

	QRange, WRange, ERange, RRange = 950, 950, 425, 1000
	QSpeed, WSpeed, ESpeed, RSpeed = 1.95, 1.65, 1.45, 2.10
	QDelay, WDelay, EDelay, RDelay = 265, 300, 250, 219
	QWidth, WWidth, EWidth, RWidth = 70, 500, 200, 150
	
	SkillQ = { spellKey = _Q, range = QRange, speed = QSpeed, delay = QDelay, width = QWidth, configName = "buckShot", displayName = "Q (Buck Shot)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true }
	SkillW = { spellKey = _W, range = WRange, speed = WSpeed, delay = WDelay, width = WWidth, configName = "smokeScreen", displayName = "W (Smoke Screen)", enabled = false, skillShot = true, minions = false, reset = false, reqTarget = true }
	SkillE = { spellKey = _E, range = ERange, speed = ESpeed, delay = EDelay, width = EWidth, configName = "quickDraw", displayName = "E (Quick Draw)", enabled = true, skillShot = false, minions = false, reset = true, reqTarget = false, atMouse = true }
	SkillR = { spellKey = _R, range = RRange, speed = RSpeed, delay = RDelay, width = RWidth, configName = "collateralDamage"}

	-- Buffs
	BuffPassive = "gravespassivegrit"
	BuffQuickdraw = "gravesmovesteroid"

	-- True Grit Passive
	PassiveTimer = 0
	BuffPassivePresent = false
	BuffQuickdrawPresent = false
	PassiveTimeout = 3 -- Seconds
	isPassiveAttack = false
	lastPassiveText = 0

	debugMode = false
end

function Menu()
	AutoCarry.PluginMenu:addParam("sep", "----- Graves by Kain: v"..version.." -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("sep", "----- [ Combo ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("ComboQ", "Use Buckshot", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboW", "Use Smoke Screen", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboE", "Use Quickdraw", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ComboR", "Use Collateral Damage", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("SmartE", "Smart Quickdraw", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("MinREnemies", "Min. R Enemies",SCRIPT_PARAM_SLICE, 1, 1, 5, 0)
	AutoCarry.PluginMenu:addParam("sep", "----- [ Advanced ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("AutoHarass", "Auto Harass", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("QBetweenAA", "Q between AA", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("KeepPassiveActive", "Keep True Grit Active (Beta)", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("RegainPassive", "Regain True Grit If Lost", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("ProMode", "Use Auto QWER Keys", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("EMinMouseDiff", "Quickdraw Min. Mouse Diff.", SCRIPT_PARAM_SLICE, 600, 100, 1000, 0)
	AutoCarry.PluginMenu:addParam("sep", "----- [ Killsteal ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("Killsteal", "Killsteal", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("KillstealQ", "Use Buckshot", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("KillstealW", "Use Smoke Screen", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("KillstealR", "Use Collateral Damage", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("sep", "----- [ Draw ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("DisableDraw", "Disable Draw", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("DrawFurthest", "Draw Furthest Spell Available", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("DrawQ", "Draw Buckshot", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("DrawW", "Draw Smoke Screen", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("DrawE", "Draw Quickdraw", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("DrawR", "Draw Collateral Damage", SCRIPT_PARAM_ONOFF, true)
end

function SpellChecks()
	QReady = (myHero:CanUseSpell(SkillQ.spellKey) == READY)
	WReady = (myHero:CanUseSpell(SkillW.spellKey) == READY)
	EReady = (myHero:CanUseSpell(SkillE.spellKey) == READY)
	RReady = (myHero:CanUseSpell(SkillR.spellKey) == READY)
end

function PluginOnTick()
	tick = GetTickCount()
	Target = AutoCarry.GetAttackTarget(true)

	SpellChecks()

	if AutoCarry.MainMenu.AutoCarry then
		Combo()
	end

	if AutoCarry.PluginMenu.Killsteal then
		-- Killsteal()
	end

	if AutoCarry.PluginMenu.KeepPassiveActive then
		PassiveKeepAlive()
	end
end

function OnGainBuff(unit, buff)
    if unit.name == myHero.name and unit.team ~= myHero.team then
		if buff and buff.name ~= nil then
			-- PrintChat("gain buff: "..buff.name)
			if buff.name == BuffPassive then
				BuffPassivePresent = true
				PassiveTimer = tick
			elseif buff.name == BuffQuickdraw then
				BuffQuickdrawPresent = true
			end
		end
    end
end

function OnLoseBuff(unit, buff)
    if unit.name == myHero.name and unit.team ~= myHero.team then
		if buff and buff.name ~= nil then
			-- PrintChat("lose buff: "..buff.name)
			if buff.name == BuffPassive then
				BuffPassivePresent = false
				PassiveTimer = 0
			elseif buff.name == BuffQuickdraw then
				BuffQuickdrawPresent = false
			end
		end
    end
end

function OnAttacked()
	-- Auto AA > Q > AA

	ResetPassiveTimer()

	if isPassiveAttack then
		isPassiveAttack = false
		if lastPassiveText == 0 or (tick > lastPassiveText + 2000) then
			lastPassiveText = tick
			PrintFloatText(myHero, 20, "True Grit!")
			if debugMode then PrintChat("True Grit!: "..PassiveTimer) end
		end

		if AutoCarry.PluginMenu.KeepPassiveActive and not AutoCarry.MainMenu.AutoCarry and not AutoCarry.MainMenu.MixedMode and not AutoCarry.MainMenu.LaneClear then
			if myHero then myHero:HoldPosition() end
		end
	end

	if (AutoCarry.PluginMenu.QBetweenAA and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode)) or (AutoCarry.PluginMenu.AutoHarass and not IsMyManaLow()) then
		CastQ()
	end
end

function Combo()
	if Target then
		if AutoCarry.PluginMenu.ComboE then CastE() end
		if AutoCarry.PluginMenu.ComboW then CastW() end
		if AutoCarry.PluginMenu.ComboQ then CastQ() end
		if AutoCarry.PluginMenu.ComboR then CastR() end
	end
end

function IsTickReady(tickFrequency)
	-- Improves FPS
	-- Disabled for now.
	if 1 == 1 then return true end

	if tick ~= nil and math.fmod(tick, tickFrequency) == 0 then
		return true
	else
		return false
	end
end

function PassiveKeepAlive()
	if not AutoCarry.PluginMenu.KeepPassiveActive then return end
	if AutoCarry.MainMenu.LaneClear then return end

	local timeSincePassive = tick - PassiveTimer
	local timeLeftOnPassive = ((PassiveTimeout * 1000) - timeSincePassive)

	if AutoCarry.PluginMenu.RegainPassive and IsTickReady(25) and (not BuffPassivePresent or timeSincePassive > (PassiveTimeout * 1000)) then
		-- Already expired.
		if AutoCarry.PluginMenu.RegainPassive then
			if PassiveFire() then
				-- if debugMode then PrintChat("true grit2: "..(timeSincePassive/1000)..", left on passive: "..(timeLeftOnPassive/1000)) end
			end
		end
	elseif PassiveTimer > 0 and timeLeftOnPassive > 0 and timeLeftOnPassive < 750 then
		-- Passive about to expire. Do something!
		-- if debugMode then PrintChat("true grit1: "..(timeSincePassive/1000)..", left on passive: "..(timeLeftOnPassive/1000)) end
		PassiveFire()
	end
end

function ResetPassiveTimer()
	PassiveTimer = tick
end

function PassiveFire()
	local passiveTarget

	if Target and GetDistance(Target) < myHero.range then
		passiveTarget = Target
	else
		-- Find enemy player
		local playerTarget = nil
		for _, enemy in pairs(AutoCarry.EnemyTable) do
			if enemy and not enemy.dead and ValidTarget(enemy) and GetDistance(enemy) <= myHero.range then
				if enemy.health < getDmg("AD", enemy, myHero) then
					-- Enemy is killable
					playerTarget = enemy
					break
				elseif playerTarget == nil or enemy.health < playerTarget.health then
					-- Find lowest target health
					playerTarget = enemy
				end
			end
		end

		if playerTarget then
			passiveTarget = playerTarget
		end
	
		local minionTarget = nil
		for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
			if ValidTarget(minion) and GetDistance(minion) <= myHero.range then
				if minion.health < getDmg("AD", minion, myHero) then
					minionTarget = minion
					break
				elseif minionTarget == nil then
					minionTarget = minion
				end
			end
		end

		if minionTarget then
			passiveTarget = minionTarget
		end
	end

	if passiveTarget and not isPassiveAttack then
		-- if debugMode then PrintChat("true grit: fired") end
		myHero:HoldPosition()
		myHero:Attack(passiveTarget)
		isPassiveAttack = true
		return true
	end

	return false
end

-- Draw
function PluginOnDraw()
	-- if Target ~= nil and not Target.dead and QReady and ValidTarget(Target, QMaxRange) then
	if Target ~= nil and not Target.dead and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
		DrawArrowsToPos(myHero, Target)
	end

	if not AutoCarry.PluginMenu.DisableDraw and not myHero.dead then
		local farSpell = FindFurthestReadySpell()
		-- if debugMode and farSpell then PrintChat("far: "..farSpell.configName) end

		-- DrawCircle(myHero.x, myHero.y, myHero.z, AutoCarry.SkillsCrosshair.range, 0x808080) -- Gray

		if AutoCarry.PluginMenu.DrawQ and QReady and ((AutoCarry.PluginMenu.DrawFurthest and farSpell and farSpell == SkillQ) or not AutoCarry.PluginMenu.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0x0099CC) -- Blue
		end

		if AutoCarry.PluginMenu.DrawW and WReady and ((AutoCarry.PluginMenu.DrawFurthest and farSpell and farSpell == SkillW) or not AutoCarry.PluginMenu.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, WRange, 0xFFFF00) -- Yellow
		end
		
		if AutoCarry.PluginMenu.DrawE and EReady and ((AutoCarry.PluginMenu.DrawFurthest and farSpell and farSpell == SkillE) or not AutoCarry.PluginMenu.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0x00FF00) -- Green
		end

		if AutoCarry.PluginMenu.DrawR and RReady and ((AutoCarry.PluginMenu.DrawFurthest and farSpell and farSpell == SkillR) or not AutoCarry.PluginMenu.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0xFF0000) -- Red
		end

		Target = AutoCarry.GetAttackTarget()
		if Target ~= nil then
			for j=0, 10 do
				DrawCircle(Target.x, Target.y, Target.z, 40 + j*1.5, 0x00FF00) -- Green
			end
		end

	end
end

function FindFurthestReadySpell()
	local farSpell = nil

	if AutoCarry.PluginMenu.DrawQ and QReady then farSpell = SkillQ end
	if AutoCarry.PluginMenu.DrawW and WReady and (not farSpell or WRange > farSpell.range) then farSpell = SkillW end
	if AutoCarry.PluginMenu.DrawE and EReady and (not farSpell or ERange > farSpell.range) then farSpell = SkillE end
	if AutoCarry.PluginMenu.DrawR and RReady and (not farSpell or RRange > farSpell.range) then farSpell = SkillR end

	return farSpell
end

function DrawArrowsToPos(pos1, pos2)
	if pos1 and pos2 then
		startVector = D3DXVECTOR3(pos1.x, pos1.y, pos1.z)
		endVector = D3DXVECTOR3(pos2.x, pos2.y, pos2.z)
		-- directionVector = (endVector-startVector):normalized()
		DrawArrows(startVector, endVector, 60, 0xE97FA5, 100)
	end
end

-- Buckshot
function CastQ(enemy)
	if not enemy then enemy = Target end
	if enemy and QReady and GetDistance(enemy) < QRange then
		AutoCarry.CastSkillshot(SkillQ, enemy)
		ResetPassiveTimer()
	end
end

-- Smoke Screen
function CastW(enemy)
	if not enemy then enemy = Target end
	if enemy and WReady and GetDistance(enemy) < WRange then
		AutoCarry.CastSkillshot(SkillW, enemy)
		ResetPassiveTimer()
	end
end

-- Quickdraw
function CastE()
	if AutoCarry.PluginMenu.SmartE then
		if ((GetDistance(mousePos) > AutoCarry.PluginMenu.EMinMouseDiff) and isEnemyInRange(ERange + RRange)) then
			local dashSqr = math.sqrt((mousePos.x - myHero.x)^2+(mousePos.z - myHero.z)^2)
			local dashX = myHero.x + ERange*((mousePos.x - myHero.x)/dashSqr)
			local dashZ = myHero.z + ERange*((mousePos.z - myHero.z)/dashSqr)

			CastSpell(SkillE.spellKey, dashX, dashZ)
			ResetPassiveTimer()
		end
	else
		CastSpell(SkillE.spellKey, mousePos.x, mousePos.z)
	end
end

-- Collateral Damage
function CastR(enemy)
	local isKS = false
	if enemy then isKS = true end
	if not enemy then enemy = Target end

	if enemy and RReady and GetDistance(enemy) < RRange then
		if AutoCarry.PluginMenu.MinREnemies == 1 or not VIP_USER or isKS then	
			if debugMode then PrintChat("R KS") end
			AutoCarry.CastSkillshot(SkillR, enemy)
			ResetPassiveTimer()
		elseif AutoCarry.PluginMenu.MinREnemies > 1 and VIP_USER then
			predPos = AutoCarry.GetPrediction(SkillR, enemy)
			if predPos then
				local hitEnemyCount = 0
				local distance = myHero + (Vector(predPos) - myHero):normalized() * SkillR.range
				local col = Collision(SkillR.range, SkillR.speed * 1000, SkillR.delay / 1000, SkillR.width)
				local collision, champions = col:GetHeroCollision(myHero, distance, HERO_ENEMY)
				local totalEnemyCount = #AutoCarry.EnemyTable

				if collision and champions then
					for i, champions in pairs(champions) do
						hitEnemyCount = hitEnemyCount + 1
					end

					-- Number of enemies that we can hit is at least the setting in the menu.
					-- If user set it higher than the number of enemies present in game, i.e. Twisted Treeline, then the number of enemies becomes the limit.
					if hitEnemyCount >= AutoCarry.PluginMenu.MinREnemies or (AutoCarry.PluginMenu.MinREnemies > totalEnemyCount and hitEnemyCount >= totalEnemyCount) then
						if debugMode then PrintChat("R not KS champions: "..totalEnemyCount..", hit: "..hitEnemyCount) end
						AutoCarry.CastSkillshot(SkillR, enemy)
						ResetPassiveTimer()
					end
				end
			end
		end
	end
end

function isEnemyInRange(range)
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, range) and not enemy.dead then
			return true
		end
	end

	return false
end

function Killsteal()
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if enemy and not enemy.dead then
			local qDmg = getDmg("Q", enemy, myHero)
			local wDmg = getDmg("W", enemy, myHero)
			local rDmg = getDmg("R", enemy, myHero)

			if QReady and AutoCarry.PluginMenu.KillstealQ and ValidTarget(enemy, QRange) and enemy.health < qDmg then
				CastQ(enemy)
			elseif QReady and WReady and AutoCarry.PluginMenu.KillstealQ and AutoCarry.PluginMenu.KillstealW and ValidTarget(enemy, QRange) and ValidTarget(enemy, WRange) and enemy.health < (qDmg + wDmg) then
				CastW(enemy)
				CastQ(enemy)
			elseif RReady and AutoCarry.PluginMenu.KillstealR and ValidTarget(enemy, RRange) and enemy.health < rDmg then
				CastR(enemy)
			elseif QReady and RReady and AutoCarry.PluginMenu.KillstealQ and AutoCarry.PluginMenu.KillstealR
				and ValidTarget(enemy, QRange) and ValidTarget(enemy, RRange) and enemy.health < (qDmg + rDmg) then
				CastQ(enemy)
				CastR(enemy)
			end
		end
	end
end

function IsMyManaLow()
	local lowManaPercent = 40
	if myHero.mana < (myHero.maxMana * ( lowManaPercent / 100)) then
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

function PluginOnWndMsg(msg,key)
	Target = AutoCarry.GetAttackTarget(true)
	if Target ~= nil and AutoCarry.PluginMenu.ProMode then
		if msg == KEY_DOWN and key == KeyQ then CastQ() end
		if msg == KEY_DOWN and key == KeyW then CastW() end
		if msg == KEY_DOWN and key == KeyE then CastE() end
		if msg == KEY_DOWN and key == KeyR then CastR() end
	end
end

--UPDATEURL=https://bitbucket.org/KainBoL/bol/raw/master/Common/SidasAutoCarryPlugin%20-%20Graves.lua
--HASH=409AD3CA4B1BAD5BE38D47FE83979AE9
