--[[
 
        Auto Carry Plugin - Varus Edition
		Author: Kain and pqmailer
		Version: See version variable below.
		Copyright 2013
		Credits to vadash for work on his Varus Helper script.

		Dependency: Sida's Auto Carry
 
		How to install:
			Make sure you already have AutoCarry installed.
			Name the script EXACTLY "SidasAutoCarryPlugin - Varus.lua" without the quotes.
			Place the plugin in BoL/Scripts/Common folder.

		Features:
			Combo: SBTW Intelligent Q, W, E, R 
			Piercing Arrow Auto Shot: Not only does this aim with VIP prediction, but it automatically draws the arrow back the minimum correct amount to reach the target's current distance.
			AoE MEC Hail of Arrows Multi-shot: Hits as many targets as possible with Hail of Arrows. It finds the best position in the center of all enemies to aim.
			Auto Blight Detonation: Once max Blight stacks (three) or the configured "Minimum W Stacks" in the menu have been reached, fires Q or E to detonate for max damage.
			Blighted Quiver Counter: Enemies with Blight on them have a red circle around them. As the Blight stacks increase, so does this circle.
			Auto Chain of Corruption: Ultimate fires automatically under several conditions: 1) you can hit three targets with it, 2) you're close to death and need an escape, and 3) when at least two enemies are kill-able by the cast (one if killsteal is also enabled).
			Slow Closest Enemy: The best escape mechanism. Slows the closest enemy causing you danger with Hail of Arrows, unless it is on cooldown, then slows with Chain of Corruption (there are a few other checks like enemy counts and such, just in case you're wondering why it sometimes doesn't fire). This is cast-able with the key bind, or with the E button in Pro Mode.
			Smart Minion Farming: If at least two minions are kill-able with E in last hit or mixed mode, auto fires in the center to kill them all. If at least three are low in lane clear mode, fires in the center.
			Killsteal: Killsteal with Q, E, or R.
			Range Circles: Smart range circles turn on and off as their respective spells are available.
			Damage Combo Calulator: Shows messages on targets when kill-able by a combo.
			Auto Summoner's Spells: Barrier, Ignite, and Cleanse.
			Customization: Fully customizable Combo (Q, W, E, R), Harass (Q, W, E), and Draw
			Menus: Extensive configuration options in two menus.
			Computer Guided Manual Mode: Manually using your spell keys will still use VIP prediction to make you not suck. Pressing Q will fire at the nearby target which is either kill-able, has the most Blight stacks, or has the lowest health, in that order. Pressing W will allow you to cast Q in the direction of your mouse position, for those times you want to free cast into a bush or manually farm. E slows nearest enemy (see above). And R work as expected. Disable Pro Mode in the menu if you want the spell keys Q, W, E, and R to just act as normal.
			Reborn: Fully compatible.
			Misc: Mana Manger, Jungle Farming, Prioritize Q over E, and more.
		
		Download: https://bitbucket.org/KainBoL/bol/raw/master/Common/SidasAutoCarryPlugin%20-%20Varus.lua

		Version History:
			Version: 2.2:
				Added Q shot smart buffer, to hit enemies that are running away better and avoid a stuck Q.
				Fixed logic on auto Q cast to avoid stuck situations.
				Added toggle for Draw Arrow to Target. Set to off by default, due to BoL disabling of it.
				Possibly fixed rare CastSpell error?
			Version: 2.1g:
				Q doesn't miss fire due to orbwalking anymore.
				Added smart farming and last-hitting.
				Fixed aim on minion farming.
				Fixed jungle farming.
				Added stacks counter via circles that expand on target.
				Improved aim on E multi-hitting.
				Fixed damage calculator.
				Added manual keys for Q, W, E, R.
				Added "BoL Studio Script Updater" url and hash.

			Version: 2.0: https://bitbucket.org/KainBoL/bol/src/b498e572a876/Common/SidasAutoCarryPlugin%20-%20Varus.lua
		To Do:
			X Auto Ignite
			X Farm Skills
			Q, W manual mode weirdness.
--]]

if not VIP_USER then
	print("Varus is a VIP only script, due to packets use.")
	return
end

--[[ Core]]--
function Vars()
	version = "2.2"

	KeySlowE = string.byte("E") -- slow nearest target
	KeyJungle = string.byte("J") -- jungle clearing

	KeyQ = string.byte("Q")
	KeyW = string.byte("W")
	KeyE = string.byte("E")
	KeyR = string.byte("R")

	levelSequence = { nil,0,2,1,1,4,1,3,1,3,4,3,3,2,2,4,2,2 } -- we level the spells that way, first point free choice; W or E
	
	--->>> Do not touch anything below here <<<---

	SkillQ = {spellKey = _Q, range = 1475, speed = 1.85, delay = 0, width = 60}
	SkillE = {spellKey = _E, range = 925, speed = 1.5, delay = 242, width = 275}
	SkillR = {spellKey = _R, range = 1075, speed = 1.95, delay = 250 , width = 80}

	QMinRange = 850
	RJumpRange = 550

	floattext = {"Harass him","Fight him","Kill him","Murder him"} -- text assigned to enemys

	killable = {} -- our enemy array where stored if people are killable
	waittxt = {} -- prevents UI lags, all credits to Dekaron

	QReady, WReady, EReady, RReady, BWCReady, RUINEDKINGReady, QUICKSILVERReady, RANDUINSReady, IGNITEReady, BARRIERReady, CLEANSEReady = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil

	tick = nil

	Cast = false
	QTick = 0

	ProcStacks = {}

	for _, enemy in pairs(AutoCarry.EnemyTable) do
		ProcStacks[enemy.networkID] = 0
	end

	IGNITESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	BARRIERSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerBarrier") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerBarrier") and SUMMONER_2) or nil)
	CLEANSESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerCleanse") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerCleanse") and SUMMONER_2) or nil)

	for i=1, heroManager.iCount do waittxt[i] = i*3 end -- All credits to Dekaron

	AutoCarry.SkillsCrosshair.range = SkillQ.range

	qp = TargetPredictionVIP(SkillQ.range, SkillQ.speed*1000, SkillQ.delay/1000, SkillQ.width)

	debugMode = false
	debugErrorsMode = false

	Target = nil
end

function Menu()
	AutoCarry.PluginMenu:addParam("SlowE", "Slow nearest enemy with E", SCRIPT_PARAM_ONKEYDOWN, false, KeySlowE) -- auto slow

	-- Settings
	AutoCarry.PluginMenu:addParam("sep", "----- Varus by Kain: v"..version.." -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("sep", "----- [ Combo ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("ComboR", "Use Chain of Corruption", SCRIPT_PARAM_ONOFF, true) -- decide if ulti should be used in full combo
	AutoCarry.PluginMenu:addParam("UseItems", "Use Items", SCRIPT_PARAM_ONOFF, true) -- decide if items should be used in full combo
	AutoCarry.PluginMenu:addParam("SlowR", "Slow with R (if E on CD)", SCRIPT_PARAM_ONOFF, true) -- use ulti to escape
	AutoCarry.PluginMenu:addParam("sep", "----- [ Harass ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("HarassQ", "Harass with Q", SCRIPT_PARAM_ONOFF, true) -- Harass with Q
	AutoCarry.PluginMenu:addParam("HarassE", "Harass with E", SCRIPT_PARAM_ONOFF, true) -- Harass with E
	AutoCarry.PluginMenu:addParam("AutoQE", "Auto Q/E if W is stacked", SCRIPT_PARAM_ONOFF, true) -- Auto Q/E if W is stacked
	AutoCarry.PluginMenu:addParam("MaxQHarassDistance", "Max. Q Harass Range", SCRIPT_PARAM_SLICE, SkillQ.range, 0, SkillQ.range, 0) -- W stacks to Q
	AutoCarry.PluginMenu:addParam("sep", "----- [ Blight Stacks ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("PrioritizeQ", "Prioritize Q", SCRIPT_PARAM_ONOFF, true) -- q > e on prock
	AutoCarry.PluginMenu:addParam("CarryMinWForQ", "Carry Mode: Min. to Q", SCRIPT_PARAM_SLICE, 3, 0, 3, 0) -- W stacks to Q
	AutoCarry.PluginMenu:addParam("CarryMinWForE", "Carry Mode: Min. to E", SCRIPT_PARAM_SLICE, 2, 0, 3, 0) -- W stacks to E
	AutoCarry.PluginMenu:addParam("MixedMinWForQE", "Mixed Mode: Min. to Q/E", SCRIPT_PARAM_SLICE, 1, 0, 3, 0) -- W stacks to Q/E
	AutoCarry.PluginMenu:addParam("sep", "----- [ Killsteal ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("KillstealQ", "Use Piercing Arrow", SCRIPT_PARAM_ONOFF, true) -- KS with all skills
	AutoCarry.PluginMenu:addParam("KillstealE", "Use Hail of Arrows", SCRIPT_PARAM_ONOFF, true) -- KS with all skills
	AutoCarry.PluginMenu:addParam("KillstealR", "Use Chain of Corruption", SCRIPT_PARAM_ONOFF, true) -- KS with all skills
	AutoCarry.PluginMenu:addParam("sep", "----- [ Farming ] -----", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("Jungle", "Jungle clearing", SCRIPT_PARAM_ONKEYTOGGLE, true, KeyJungle) -- jungle clearing
	-- AutoCarry.PluginMenu:addParam("FarmSkills", "Use Skills with Lane Clear mode", SCRIPT_PARAM_ONOFF, true) -- spamming e on the minions while lane clearing
	AutoCarry.PluginMenu:addParam("LastHitE", "Smart Last hit with E", SCRIPT_PARAM_ONOFF, true) -- Last hit with E
	AutoCarry.PluginMenu:addParam("LastHitMinimumMinions", "Min minions for E last hit", SCRIPT_PARAM_SLICE, 2, 1, 10, 0) -- minion slider
	AutoCarry.PluginMenu:addParam("LaneClearE", "Lane Clear with E", SCRIPT_PARAM_ONOFF, true) -- Lane clearing with E.

	ExtraConfig = scriptConfig("Sida's Auto Carry Plugin: Varus: Extras", "Varus")
	ExtraConfig:addParam("sep", "----- [ Misc ] -----", SCRIPT_PARAM_INFO, "")
	ExtraConfig:addParam("AutoLevelSkills", "Auto Level Skills (Requires Reload)", SCRIPT_PARAM_ONOFF, true) -- auto level skills
	ExtraConfig:addParam("ManaManager", "Mana Manager %", SCRIPT_PARAM_SLICE, 40, 0, 100, 2)
	ExtraConfig:addParam("ProMode", "Use Auto QWER Keys", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("WWaitDelay", "Delay before Q via W (ms)",SCRIPT_PARAM_SLICE, 250, 0, 2000, 2) -- the q delay
	ExtraConfig:addParam("sep", "----- [ Summoner Spells ] -----", SCRIPT_PARAM_INFO, "")
	ExtraConfig:addParam("AutoBarrier", "Use Barrier", SCRIPT_PARAM_ONOFF, true) -- barrier
	ExtraConfig:addParam("BarrierHealthRatio", "Barrier Health Ratio", SCRIPT_PARAM_SLICE, 0.15, 0, 1, 2) -- health ratio
	ExtraConfig:addParam("AutoCleanse", "Auto Cleanse", SCRIPT_PARAM_ONOFF, true) -- cleanse
	ExtraConfig:addParam("sep", "----- [ Draw ] -----", SCRIPT_PARAM_INFO, "")
	ExtraConfig:addParam("DrawStacks", "Draw Blighted Quiver Stacks", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("DrawKillable", "Draw Killable Enemies", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("DrawTargetArrow", "Draw Arrow to Target", SCRIPT_PARAM_ONOFF, false)
	ExtraConfig:addParam("DisableDrawCircles", "Disable Draw", SCRIPT_PARAM_ONOFF, false)
	ExtraConfig:addParam("DrawFurthest", "Draw Furthest Spell Available", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("DrawQ", "Draw Piercing Arrow", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("DrawE", "Draw Hail of Arrows", SCRIPT_PARAM_ONOFF, true)
	ExtraConfig:addParam("DrawR", "Draw Chain of Corruption", SCRIPT_PARAM_ONOFF, true)

	AutoCarry.PluginMenu:permaShow("SlowE")
	AutoCarry.PluginMenu:permaShow("Jungle")
end

function PluginOnLoad()
	Vars()
	Menu()

	if ExtraConfig.AutoLevelSkills then -- setup the skill autolevel
		autoLevelSetSequence(levelSequence)
		autoLevelSetFunction(onChoiceFunction) -- add the callback to choose the first skill
	end

	PrintChat(" >> Varus: The Arrow of Retribution by Kain and pqmailer loaded!")
end

function PluginOnTick()
	-- Disable SAC Reborn's auto E. Ours is better.
	if AutoCarry.Skills then
		AutoCarry.Skills:GetSkill(SkillE.spellKey).Enabled = false
	end

	tick = GetTickCount()
	Target = AutoCarry.GetAttackTarget()

	SpellCheck()

	if (TargetHaveBuff("SummonerDot", myHero) and TargetHaveBuff("SummonerExhaust", myHero))
		or (TargetHaveBuff("SummonerDot", myHero) and myHero.health/myHero.maxHealth <= 0.5)
		or (TargetHaveBuff("SummonerExhaust", myHero) and myHero.health/myHero.maxHealth <= 0.5)
		and CLEANSEReady and ExtraConfig.AutoCleanse then
		CastSpell(CLEANSESlot)
	end

	if myHero.health/myHero.maxHealth <= ExtraConfig.BarrierHealthRatio and BARRIERReady and ExtraConfig.AutoBarrier then
		CastSpell(BARRIERSlot)
	end

	Killsteal()

	if AutoCarry.PluginMenu.SlowE then
		SlowClosestEnemy()
	end

	if AutoCarry.MainMenu.AutoCarry then
		Combo()
	end

	if AutoCarry.MainMenu.MixedMode then
		Harass()
		if AutoCarry.PluginMenu.AutoQE then
			CastEQAuto()
		end
	end

	if AutoCarry.MainMenu.LastHit and AutoCarry.PluginMenu.Jungle then
		JungleSteal()
	end

	if AutoCarry.MainMenu.LaneClear and AutoCarry.PluginMenu.Jungle then
		JungleClear()
	end

	if (AutoCarry.PluginMenu.LastHitE or AutoCarry.PluginMenu.LaneClearE) and IsTickReady(40) and not IsMyManaLow() then
		if AutoCarry.PluginMenu.LastHitE and (AutoCarry.MainMenu.LastHit or AutoCarry.MainMenu.MixedMode) then
			SmartFarmWithE(false)
		elseif AutoCarry.PluginMenu.LaneClearE and AutoCarry.MainMenu.LaneClear then
			SmartFarmWithE()
		end
	end
end

function PluginOnDraw()
	if Target ~= nil and not Target.dead and ExtraConfig.DrawTargetArrow and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
		DrawArrowsToPos(myHero, Target)
	end

	if ExtraConfig.DrawStacks then
		for i, enemy in pairs(AutoCarry.EnemyTable) do
			if ValidTarget(enemy, SkillE.range) then
				if ProcStacks[enemy.networkID] > 0 then
					-- DrawCircle(enemy.x, enemy.y, enemy.z, (60+(20 * ProcStacks[enemy.networkID])), 0xFF0000)
					for j=0, 10 * ProcStacks[enemy.networkID] do
						DrawCircle(enemy.x, enemy.y, enemy.z, 80 + j*1.5, 0xFF0000) -- Red
					end
				end
			end
		end
	end

	if IsTickReady(75) then DMGCalculation() end
	DrawKillable()
	DrawRanges()
end

function DrawKillable()
	if ExtraConfig.DrawKillable and not myHero.dead then
		for i=1, heroManager.iCount do
			local Unit = heroManager:GetHero(i)
			if ValidTarget(Unit) then -- we draw our circles
				 if killable[i] == 1 then
				 	DrawCircle(Unit.x, Unit.y, Unit.z, 100, 0xFFFFFF00)
				 end

				 if killable[i] == 2 then
				 	DrawCircle(Unit.x, Unit.y, Unit.z, 100, 0xFFFFFF00)
				 end

				 if killable[i] == 3 then
				 	for j=0, 10 do
				 		DrawCircle(Unit.x, Unit.y, Unit.z, 100+j*0.8, 0x099B2299)
				 	end
				 end

				 if killable[i] == 4 then
				 	for j=0, 10 do
				 		DrawCircle(Unit.x, Unit.y, Unit.z, 100+j*0.8, 0x099B2299)
				 	end
				 end

				 if waittxt[i] == 1 and killable[i] ~= nil and killable[i] ~= 0 and killable[i] ~= 1 then
				 	PrintFloatText(Unit,0,floattext[killable[i]])
				 end
			end

			if waittxt[i] == 1 then
				waittxt[i] = 30
			else
				waittxt[i] = waittxt[i]-1
			end
		end
	end
end

function DrawRanges()
	if not ExtraConfig.DisableDrawCircles and not myHero.dead then
		local farSpell = FindFurthestReadySpell()

		-- DrawCircle(myHero.x, myHero.y, myHero.z, getTrueRange(), 0x808080) -- Gray

		if ExtraConfig.DrawQ and QReady and ((ExtraConfig.DrawFurthest and farSpell and farSpell == SkillQ.range) or not ExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillQ.range, 0x0099CC) -- Blue
		end

		if ExtraConfig.DrawE and EReady and ((ExtraConfig.DrawFurthest and farSpell and farSpell == SkillE.range) or not ExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillE.range, 0xFFFF00) -- Yellow
		end

		if ExtraConfig.DrawR and RReady and ((ExtraConfig.DrawFurthest and farSpell and farSpell == SkillR.range) or not ExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillR.range, 0xFF0000) -- Red
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

	if ExtraConfig.DrawQ and QReady then farSpell = SkillQ.range end
	if ExtraConfig.DrawE and EReady and (not farSpell or SkillE.range > farSpell) then farSpell = SkillE.range end
	if ExtraConfig.DrawR and RReady and (not farSpell or SkillR.range > farSpell) then farSpell = SkillR.range end

	return farSpell
end

function DrawArrowsToPos(pos1, pos2)
	if pos1 and pos2 then
		startVector = D3DXVECTOR3(pos1.x, pos1.y, pos1.z)
		endVector = D3DXVECTOR3(pos2.x, pos2.y, pos2.z)
		DrawArrows(startVector, endVector, 60, 0xE97FA5, 100)
	end
end

function PluginOnCreateObj(object)
	if object and object.valid and Target then
		if object.name == "VarusW_counter_02.troy" and GetDistance(object) <= SkillQ.range then
			for i, enemy in pairs(AutoCarry.EnemyTable) do
				if ValidTarget(enemy) and TargetHaveBuff("varuswdebuff", enemy) then
					ProcStacks[enemy.networkID] = 2
				end
			end
		end

		if object.name == "VarusW_counter_03.troy" and GetDistance(object) <= SkillQ.range then
			for i, enemy in pairs(AutoCarry.EnemyTable) do
				if ValidTarget(enemy) and TargetHaveBuff("varuswdebuff", enemy) then
					ProcStacks[enemy.networkID] = 3
				end
			end
		end
	end
end	

function PluginOnDeleteObj(object)
	if object and object.valid then
		if object.name == "VarusW_counter_02.troy" then
			for i, enemy in pairs(AutoCarry.EnemyTable) do
				if not TargetHaveBuff("varuswdebuff", enemy) then
					ProcStacks[enemy.networkID] = 0
				end
			end
		end

		if object.name == "VarusW_counter_03.troy" then
			for i, enemy in pairs(AutoCarry.EnemyTable) do
				if not TargetHaveBuff("varuswdebuff", enemy) then
					ProcStacks[enemy.networkID] = 0
				end
			end
		end
	end
end

--[[
function OldOnSendPacket(packet)
	local p = Packet(packet)
    if p:get("spellId") == SkillE.spellKey and not (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.LaneClear or AutoCarry.MainMenu.MixedMode or AutoCarry.PluginMenu.SlowE) then
    	p:block()
    end
end
--]]

function OnSendPacket(packet)
	-- Old handler for SAC: Revamped
	PluginOnSendPacket(packet)
end

function PluginOnSendPacket(packet)
	-- New handler for SAC: Reborn
	local p = Packet(packet)

	-- if p:get("spellId") == SkillE.spellKey and not (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.LaneClear or AutoCarry.MainMenu.MixedMode or AutoCarry.PluginMenu.SlowE) then
	--	p:block()
	-- end
    if packet.header == 0xE6 then --and Cast then -- 2nd cast of channel spells packet2
		packet.pos = 5
        spelltype = packet:Decode1()
        if spelltype == 0x80 then -- 0x80 == Q
            packet.pos = 1
            packet:Block()
        end
    end
end

function Combo()
	local target = AutoCarry.GetAttackTarget()
	local calcenemy = 1
	local EnemysInRange = CountEnemyHeroInRange()
	local TrueRange = GetTrueRange()

	if not target or not ValidTarget(target) then return true end

	for i=1, heroManager.iCount do
    	local Unit = heroManager:GetHero(i)
    	if Unit.charName == target.charName then
    		calcenemy = i
    	end
   	end
   	
   	if IGNITEReady and killable[calcenemy] == 3 then CastSpell(IGNITESlot, target) end

   	if AutoCarry.PluginMenu.UseItems then
   		if BWCReady and (killable[calcenemy] == 2 or killable[calcenemy] == 3) then CastSpell(BWCSlot, target) end
   		if RUINEDKINGReady and (killable[calcenemy] == 2 or killable[calcenemy] == 3) then CastSpell(RUINEDKINGSlot, target) end
   		if RANDUINSReady then CastSpell(RANDUINSSlot) end
   	end

	if RReady and AutoCarry.PluginMenu.ComboR and (EnemyCount(target, RJumpRange) >= 3 or (myHero.health / myHero.maxHealth <= 0.4) or killable[calcenemy] == 2 or killable[calcenemy] == 3) then
		CastR()
	end

	CastEQAuto()
end

function Harass()
	local target = AutoCarry.GetAttackTarget()
	local TrueRange = GetTrueRange()

	if ValidTarget(target) then
		local targetDistance = GetDistance(target)

		if not IsMyManaLow() then
			if AutoCarry.PluginMenu.HarassE and EReady and targetDistance <= SkillE.range then CastE(target) end
			if AutoCarry.PluginMenu.HarassQ and QReady and targetDistance <= SkillQ.range and targetDistance > TrueRange
				and targetDistance <= AutoCarry.PluginMenu.MaxQHarassDistance and GetTickCount() > QTick + (GetQDelay(target)) then
				CastQ(target, false)
			end
		end
	end
end

--[[
function LaneClear()
	if not EReady then return true end

	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion, SkillE.range) and getDmg("E", minion, myHero) >= minion.health then AutoCarry.CastSkillshot(SkillE, minion) end
	end

	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion, SkillQ.range) and getDmg("Q", minion, myHero) >= minion.health then CastQ(minion, false) end
	end

	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion, SkillE.range) then AutoCarry.CastSkillshot(SkillE, minion) end
	end

	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion, SkillQ.range) then CastQ(minion, false) end
	end
end
--]]

--[[
function LastHitE()
	if not EReady then return true end

	local killableMinions = 0
	local Minions = {}

	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion, SkillE.range) and getDmg("E", minion, myHero) >= minion.health then
			killableMinions = killableMinions + 1
			table.insert(Minions, minion)
		end
	end

	if killableMinions >= AutoCarry.PluginMenu.LastHitMinimumMinions then
		for _, minion in pairs(Minions) do
			if ValidTarget(minion, SkillE.range) and EReady then AutoCarry.CastSkillshot(SkillE, minion) end
			return
		end
	end
	return
end
--]]

function GetDamage(enemy, spell)
	if spell == _E then
		return myHero:CalcDamage(enemy, ((35*(myHero:GetSpellData(_E).level-1) + 65) + (.60 * myHero.addDamage)))
	end
end

function SmartFarmWithE(laneClear)
	if not EReady then return true end

	local minions = {}
	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion, SkillE.range) and EReady then
			local spellDmg = GetDamage(minion, SkillE.spellKey)
			if (not laneClear and minion.health < spellDmg) or (laneClear and minion.health < spellDmg * 3) then 
				table.insert(minions, minion)
			end
		end
	end

	local minionClusters = {}

	local closeMinion = SkillE.width
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

	if debugMode and largestClusterSize >= AutoCarry.PluginMenu.LastHitMinimumMinions then
		PrintChat("totalClusters: "..#minionClusters..", largestCluster: "..largestCluster..", largestClusterSize: "..largestClusterSize)
	end

	if largestClusterSize >= AutoCarry.PluginMenu.LastHitMinimumMinions then
		minionCluster = minionClusters[largestCluster]
		
		-- Needs to be in OnDraw to function.
		-- local minionClusterPoint = {x=minionCluster.x, y=myHero.y, z=minionCluster.z}
		-- DrawArrowsToPos(myHero, minionClusterPoint)

		if minionCluster then
			CastSpell(SkillE.spellKey, minionCluster.x, minionCluster.z)
		end
	end

	minions = nil
	minionClusters = nil
end

function CastEQAuto()
	TrueRange = GetTrueRange()
	if QReady and (AutoCarry.PluginMenu.PrioritizeQ or not EReady) then
		local mostStacksEnemy = FindEnemyWithMostStacks(SkillQ.range)

		if mostStacksEnemy and not mostStacksEnemy.dead
		and (((AutoCarry.MainMenu.MixedMode or AutoCarry.MainMenu.LaneClear) and ProcStacks[mostStacksEnemy.networkID] >= AutoCarry.PluginMenu.MixedMinWForQE)
			or (AutoCarry.MainMenu.AutoCarry and ProcStacks[mostStacksEnemy.networkID] >= AutoCarry.PluginMenu.CarryMinWForQ))
		and ValidTarget(mostStacksEnemy, SkillQ.range) then
			CastQ(mostStacksEnemy, false)
		end
	elseif EReady and ((not AutoCarry.PluginMenu.PrioritizeQ) or (AutoCarry.PluginMenu.PrioritizeQ and not QReady)) then
		local mostStacksEnemy = FindEnemyWithMostStacks(SkillE.range)

		if mostStacksEnemy and not mostStacksEnemy.dead and (ProcStacks[mostStacksEnemy.networkID] == 3
			or ((((AutoCarry.MainMenu.MixedMode or AutoCarry.MainMenu.LaneClear) and ProcStacks[mostStacksEnemy.networkID] >= AutoCarry.PluginMenu.MixedMinWForQE)
				or (AutoCarry.MainMenu.AutoCarry and ProcStacks[mostStacksEnemy.networkID] >= AutoCarry.PluginMenu.CarryMinWForE))
			and GetDistance(mostStacksEnemy) > TrueRange))
			and ValidTarget(mostStacksEnemy, SkillE.range) and GetTickCount() > QTick + (GetQDelay(mostStacksEnemy)) then
			CastE(mostStacksEnemy)
		end
	end
end

function CastE(enemy)
	if not myHero.dead and not enemy and Target then enemy = Target end

	if EReady and enemy and not enemy.dead and ValidTarget(enemy, SkillE.range) then
		if EnemyCount(enemy, SkillE.width) > 1 then
			local spellPos = GetAoESpellPosition((SkillE.width / 2), enemy, SkillE.delay)

			if spellPos and GetDistance(spellPos) <= SkillE.range then
				CastSpell(SkillE.spellKey, spellPos.x, spellPos.z)
				return true
			end
		else
			AutoCarry.CastSkillshot(SkillE, enemy)
			return true
		end
	end

	return false
end

function GetQDelay(enemy)
	local distanceOverMin = GetDistance(enemy) - QMinRange
	local delay = 125

	if distanceOverMin > 0 then
		delay = (GetDistance(enemy) - QMinRange) * (2000 / (SkillQ.range - QMinRange))
	end

	-- Add in a bit of buffer to hit enemies running away.
	delay = delay + 50
	if enemy.charName then -- Only predict for an enemy, not a position.
		QPred = qp:GetPrediction(enemy)
		if QPred then
			local predDistance = GetDistance(QPred)
			local diffDistance = predDistance - GetDistance(enemy)
			if diffDistance > 0 then
				delay = delay + diffDistance
			end
		end
	end

	if delay > 2000 then delay = 2000 end

	return delay
end

function CastManualQ(mouse) -- cast Q to lowhp enemy or mousepos
	if mouse then
		CastQ(nil, mouse)
		return true
	else
		local lowHealthEnemy = FindLowestHealthEnemy(SkillQ.range)

		-- Is there a killsteal?
		if lowHealthEnemy and ValidTarget(lowHealthEnemy, SkillQ.range) and getDmg("Q", lowHealthEnemy, myHero) >= lowHealthEnemy.health then
			CastQ(lowHealthEnemy, false)
			return true
		else
			local mostStacksEnemy = FindEnemyWithMostStacks(SkillQ.range)
			-- How about proc stacks minimum requirement met?
			if mostStacksEnemy and ProcStacks[mostStacksEnemy.networkID] >= AutoCarry.PluginMenu.CarryMinWForQ and ValidTarget(mostStacksEnemy, SkillQ.range) then
				CastQ(mostStacksEnemy, false)
				return true
			else
				-- Everything else failed, so just hit the enemy with the lowest health.
				CastQ(lowHealthEnemy, false)
				return true
			end
		end
	end

	return false
end

function QMovePos(target)
	local moveDistance = 100
	local targetDistance = GetDistance(target)
	return { x = myHero.x + ((target.x - myHero.x) * (moveDistance) / targetDistance), z = myHero.z + ((target.z - myHero.z) * (moveDistance) / targetDistance)}
end

function CastQ(Unit, mouse)
	if myHero.dead then return false end

	-- Lost target due to range or death. Try to get another.
	if (not Unit or Unit.dead) and not mouse then
		Unit = AutoCarry.GetAttackTarget()
	end

	-- We couldn't get a suitable target.
	if (not Unit or Unit.dead) and not mouse then return false end

	if Unit then
		QPred = qp:GetPrediction(Unit)
	end

	if (QPred or mouse) and not Cast and ((mouse == 1 and GetTickCount() - QTick > ExtraConfig.WWaitDelay) or (QPred and GetTickCount() - QTick >= GetQDelay(QPred))) then
		if mouse then
			CastSpell(SkillQ.spellKey, mousePos.x, mousePos.z)
		else
			CastSpell(SkillQ.spellKey, QPred.x, QPred.z)
		end
		QTick = GetTickCount()
		Cast = true
	end

	if (QPred or mouse) and Cast and ((mouse == 2 and GetTickCount() - QTick > ExtraConfig.WWaitDelay) or (QPred and GetTickCount() - QTick >= GetQDelay(QPred))) then
		PQ2 = CLoLPacket(0xE6)
		PQ2:EncodeF(myHero.networkID)
		PQ2:Encode1(128)

		local movePos = nil

		if mouse then
			PQ2:EncodeF(mousePos.x)
			PQ2:EncodeF(myHero.y)
			PQ2:EncodeF(mousePos.z)

			movePos = QMovePos(mousePos)
		else
			PQ2:EncodeF(QPred.x)
			PQ2:EncodeF(QPred.y)
			PQ2:EncodeF(QPred.z)

			movePos = QMovePos(QPred)
		end

		PQ2.dwArg1 = 1
		PQ2.dwArg2 = 0

		-- AutoCarry.CanMove = false
		if movePos then myHero:MoveTo(movePos.x, movePos.z) end
		SendPacket(PQ2)
		-- AutoCarry.CanMove = true

		QTick = GetTickCount()
		Cast = false
		return true
	end

	return false
end

--[[
function Old2CastQ(Unit, mouse)
	if not Unit and not mouse then return end

	if Unit then
		QPred = qp:GetPrediction(Unit)
	end

	if (QPred or mouse) and not Cast and ((mouse == 1 and GetTickCount() - QTick > ExtraConfig.WWaitDelay) or (QPred and GetTickCount() - QTick >= GetQDelay(QPred))) then
		if mouse then
			CastSpell(SkillQ.spellKey, mousePos.x, mousePos.z)
		else
			CastSpell(SkillQ.spellKey, QPred.x, QPred.z)
		end
		QTick = GetTickCount()
		Cast = true
	end

	if (QPred or mouse) and Cast and ((mouse == 2 and GetTickCount() - QTick > ExtraConfig.WWaitDelay) or (QPred and GetTickCount() - QTick >= GetQDelay(QPred))) then
		PQ2 = CLoLPacket(0xE6)
		PQ2:EncodeF(myHero.networkID)
		PQ2:Encode1(128)
		
		if mouse then
			PQ2:EncodeF(mousePos.x)
			PQ2:EncodeF(myHero.y)
			PQ2:EncodeF(mousePos.z)
		else
			PQ2:EncodeF(QPred.x)
			PQ2:EncodeF(QPred.y)
			PQ2:EncodeF(QPred.z)
		end

		PQ2.dwArg1 = 1
		PQ2.dwArg2 = 0
		SendPacket(PQ2)
		QTick = GetTickCount()
		Cast = false
		return true
	end

	return false
end
--]]

--[[
function OldCastQ(Unit)
	if not Unit then return end

	QPred = qp:GetPrediction(Unit)

	if QPred and not Cast and GetTickCount() - QTick >= GetQDelay(QPred) then
		CastSpell(SkillQ.spellKey, QPred.x, QPred.z)
		QTick = GetTickCount()
		Cast = true
	end

	if QPred and Cast and GetTickCount() - QTick >= GetQDelay(QPred) then
		PQ2 = CLoLPacket(0xE6)
		PQ2:EncodeF(myHero.networkID)
		PQ2:Encode1(128)
		PQ2:EncodeF(QPred.x)
		PQ2:EncodeF(QPred.y)
		PQ2:EncodeF(QPred.z)
		PQ2.dwArg1 = 1
		PQ2.dwArg2 = 0
		SendPacket(PQ2)
		QTick = GetTickCount()
		Cast = false	
	end
end
--]]

function CastR(enemy)
	if not enemy and Target then enemy = Target end

	if RReady and enemy and not enemy.dead and ValidTarget(enemy, SkillR.range) and not AutoCarry.GetCollision(SkillR, myHero, enemy) then
		AutoCarry.CastSkillshot(SkillR, enemy)
		return true
	end

	return false
end

function JungleClear()
	local Priority = nil
	local Target = nil
	local TrueRange = GetTrueRange()
	for _, mob in pairs(AutoCarry.GetJungleMobs()) do
		if ValidTarget(mob) then
 			if mob.name == "TT_Spiderboss7.1.1"
			or mob.name == "Worm12.1.1"
			or mob.name == "Dragon6.1.1"
			or mob.name == "AncientGolem1.1.1"
			or mob.name == "AncientGolem7.1.1"
			or mob.name == "LizardElder4.1.1"
			or mob.name == "LizardElder10.1.1"
			or mob.name == "GiantWolf2.1.3"
			or mob.name == "GiantWolf8.1.3"
			or mob.name == "Wraith3.1.3"
			or mob.name == "Wraith9.1.3"
			or mob.name == "Golem5.1.2"
			or mob.name == "Golem11.1.2"
			then
				Priority = mob
			else
				Target = mob
			end
		end
	end

	if Priority then
		Target = Priority
	end

	if Target and ValidTarget(Target) then
		if myHero:GetDistance(Target) <= TrueRange then CustomAttackEnemy(Target) end
		if myHero:GetDistance(Target) <= SkillE.range and EReady then AutoCarry.CastSkillshot(SkillE, Target) end
	end
end

function JungleSteal()
	for _, mob in pairs(AutoCarry.GetJungleMobs()) do
		if ValidTarget(mob, TrueRange) and getDmg("AD",enemy,myHero) >= mob.health then
			CustomAttackEnemy(mob)
		end

		if ValidTarget(mob, SpellRangeE) and EReady and getDmg("E", mob, myHero) >= mob.health then
			AutoCarry.CastSkillshot(SkillE, mob)
		end
	end
end

function Killsteal()
	local TrueRange = GetTrueRange()
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, 500) and BWCReady and getDmg("BWC", enemy, myHero) >= enemy.health then
			CastSpell(BWCSlot, enemy)
			return true
		elseif ValidTarget(enemy, 500) and RUINEDKINGReady and getDmg("RUINEDKING", enemy, myHero) >= enemy.health then
			CastSpell(RUINEDKINGSlot, enemy)
			return true
		elseif ValidTarget(enemy, TrueRange) and getDmg("AD", enemy, myHero) >= enemy.health then
			CustomAttackEnemy(enemy)
			return true
		elseif AutoCarry.PluginMenu.KillstealE and ValidTarget(enemy, SkillE.range) and getDmg("E", enemy, myHero) >= enemy.health then
			CastE(enemy)
			return true
		elseif AutoCarry.PluginMenu.KillstealQ and ValidTarget(enemy, SkillQ.range) and getDmg("Q", enemy, myHero) >= enemy.health then
			CastQ(enemy, false)
			return true
 		elseif AutoCarry.PluginMenu.KillstealR and RReady and ValidTarget(enemy, SkillR.range) and getDmg("R", enemy, myHero) >= enemy.health then
			CastR(enemy)
			return true
		end
	end

	return false
end

function SlowClosestEnemy()
	local closestEnemy = FindCLosestEnemy()
	if not closestEnemy then return false end

	if RANDUINSReady and GetDistance(closestEnemy) <= 200 then CastSpell(RANDUINSSlot) end

	if EReady and ValidTarget(closestEnemy, SkillE.range) then
		if CastE(closestEnemy) then return true end
	end

	if RReady and AutoCarry.PluginMenu.SlowR and EnemyCount(closestEnemy, SkillR.range) >= 3 and ValidTarget(closestEnemy, SkillR.range) then
		CastR(closestEnemy)
		return true
	end

	return false
end

function FindEnemyWithMostStacks(range)
	local mostStacksEnemy = nil

	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if enemy and enemy.valid and not enemy.dead then
			if (not mostStacksEnemy and ProcStacks[enemy.networkID] > 0) or (mostStacksEnemy and ProcStacks[enemy.networkID] > ProcStacks[mostStacksEnemy.networkID] and GetDistance(enemy) <= range) then
				mostStacksEnemy = enemy
			end
		end
	end

	return mostStacksEnemy
end

function FindCLosestEnemy()
	local closestEnemy = nil

	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if enemy and enemy.valid and not enemy.dead then
			if not closestEnemy or GetDistance(enemy) < GetDistance(closestEnemy) then
				closestEnemy = enemy
			end
		end
	end

	return closestEnemy
end

function FindLowestHealthEnemy(range)
	local lowHealthEnemy = nil

	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if enemy and enemy.valid and not enemy.dead then
			if not lowHealthEnemy or (GetDistance(enemy) <= range and enemy.health < lowHealthEnemy.health) then
				lowHealthEnemy = enemy
			end
		end
	end

	return closestEnemy
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

function IsMyManaLow()
	if myHero.mana < (myHero.maxMana * ( ExtraConfig.ManaManager / 100)) then
		return true
	else
		return false
	end
end

function onChoiceFunction() -- our callback function for the ability leveling
	if myHero:GetSpellData(SkillE.spellKey).level < myHero:GetSpellData(SkillQ.spellKey).level then
		return 3
	else
		return 1
	end
end

function GetTrueRange()
	return myHero.range + GetDistance(myHero.minBBox)
end

function IsTickReady(tickFrequency)
	-- Improves FPS
	if tick ~= nil and math.fmod(tick, tickFrequency) == 0 then
		return true
	else
		return false
	end
end

function CustomAttackEnemy(enemy)
	myHero:Attack(enemy)
	AutoCarry.shotFired = true
end

function SpellCheck()
	RUINEDKINGSlot, QUICKSILVERSlot, RANDUINSSlot, BWCSlot = GetInventorySlotItem(3153), GetInventorySlotItem(3140), GetInventorySlotItem(3143), GetInventorySlotItem(3144)
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	RUINEDKINGReady = (RUINEDKINGSlot ~= nil and myHero:CanUseSpell(RUINEDKINGSlot) == READY)
	QUICKSILVERReady = (QUICKSILVERSlot ~= nil and myHero:CanUseSpell(QUICKSILVERSlot) == READY)
	RANDUINSReady = (RANDUINSSlot ~= nil and myHero:CanUseSpell(RANDUINSSlot) == READY)
	IGNITEReady = (IGNITESlot ~= nil and myHero:CanUseSpell(IGNITESlot) == READY)
	BARRIERReady = (BARRIERSlot ~= nil and myHero:CanUseSpell(BARRIERSlot) == READY)
	CLEANSEReady = (CLEANSESlot ~= nil and myHero:CanUseSpell(CLEANSESlot) == READY)
end

function DMGCalculation()
	for i=1, heroManager.iCount do
        local Unit = heroManager:GetHero(i)
        if ValidTarget(Unit) then
        	local RUINEDKINGDamage, IGNITEDamage, BWCDamage = 0, 0, 0
        	local QDamage = getDmg("Q",Unit,myHero)
			local WDamage = getDmg("W",Unit,myHero)
			local EDamage = getDmg("E",Unit,myHero)
			local RDamage = getDmg("R", Unit, myHero)
			local HITDamage = getDmg("AD",Unit,myHero)
			local IGNITEDamage = (IGNITESlot and getDmg("IGNITE",Unit,myHero) or 0)
			local BWCDamage = (BWCSlot and getDmg("BWC",Unit,myHero) or 0)
			local RUINEDKINGDamage = (RUINEDKINGSlot and getDmg("RUINEDKING",Unit,myHero) or 0)
			local combo1 = HITDamage
			local combo2 = HITDamage
			local combo3 = HITDamage
			local mana = 0

			if QReady then
				combo1 = combo1 + QDamage
				combo2 = combo2 + QDamage
				combo3 = combo3 + QDamage
				mana = mana + myHero:GetSpellData(SkillQ.spellKey).mana
			end

			if WReady then
				combo1 = combo1 + WDamage
				combo2 = combo2 + WDamage
				combo3 = combo3 + WDamage
				mana = mana + myHero:GetSpellData(SkillW.spellKey).mana
			end

			if EReady then
				combo1 = combo1 + EDamage
				combo2 = combo2 + EDamage
				combo3 = combo3 + EDamage
				mana = mana + myHero:GetSpellData(SkillE.spellKey).mana
			end

			if RReady then
				combo2 = combo2 + RDamage
				combo3 = combo3 + RDamage
				mana = mana + myHero:GetSpellData(SkillR.spellKey).mana
			end

			if BWCReady then
				combo2 = combo2 + BWCDamage
				combo3 = combo3 + BWCDamage
			end

			if RUINEDKINGReady then
				combo2 = combo2 + RUINEDKINGDamage
				combo3 = combo3 + RUINEDKINGDamage
			end

			if IGNITEReady then
				combo3 = combo3 + IGNITEDamage
			end

			killable[i] = 1 -- the default value = harass

			if combo3 >= Unit.health and myHero.mana >= mana then -- all cooldowns needed
				killable[i] = 2
			end

			if combo2 >= Unit.health and myHero.mana >= mana then -- only spells + ulti and items needed
				killable[i] = 3
			end

			if combo1 >= Unit.health and myHero.mana >= mana then -- only spells but no ulti needed
				killable[i] = 4
			end
		end
	end
end

function PluginOnWndMsg(msg,key)
	Target = AutoCarry.GetAttackTarget()

	if ExtraConfig.ProMode then
		if msg == KEY_DOWN and key == KeyQ then CastManualQ(false) end
		if key == KeyW then
			if msg == KEY_DOWN then
				CastManualQ(1)
			elseif msg == KEY_UP then
				CastManualQ(2)
			end
		end
		if msg == KEY_DOWN and key == KeyE then SlowClosestEnemy() end
		if msg == KEY_DOWN and key == KeyR then CastR(Target) end
	end
end

-- End of Varus script

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

--UPDATEURL=https://bitbucket.org/KainBoL/bol/raw/master/Common/SidasAutoCarryPlugin%20-%20Varus.lua
--HASH=CE49C4EA474FB615AB46755B8CF4F097