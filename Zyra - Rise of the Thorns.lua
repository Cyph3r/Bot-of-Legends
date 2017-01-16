--[[
        Zyra: Rise of the Thorns - Free Edition
		Author: Kain
		Version: See version variable below.
		Copyright 2013
 
		How to install:
			Place the plugin in BoL/Scripts folder.

		Download: https://bitbucket.org/KainBoL/bol/raw/master/Zyra%20-%20Rise%20of%20the%20Thorns.lua

		Version History:
			Version: 2.3f:
				Modified ranges per 3.13 patch notes.
			Version: 2.3e:
				Logic improvements on Q and E.
				Better double W handling.
				Fixed W when E is disabled or unvailable.
				Removed collision detection on E except if enabled in extras menu.
			Version: 2.2:
				Added new PROdiction.
				Better logic on Q and E handling.
				Better double W handling.
			Version: 2.1c:
				Fixed Q not firing, and missing sometimes when it does.
				Fixed Q-W combo.
				Fixed Q and W not firing when E hasn't been learned yet.
				Added checks for missing or old collision lib.
				Added "BoL Studio Script Updater" url and hash.
			Version 2.0c:
				Completely rewrote script.
				Combos: E+Q+WW+R, E+Q+WW, E+Q+W, E+WW, E+W, Q+WW, E+WW, depending on combo config and situations.
				SBTW: Script does just great, when are you're doing is holding spacebar.
				Pro Mode: Q, W, E, R keys all work as normal, if you choose to use them manually, except Q, E, R all use built in combos and prediction, so you don't have to worry.
				VIP Prediction supported: It has non-VIP prediction also, but you're going to have a much better experience with VIP.
				Harass Mode: Q+WW, E+WW, Q+E+WW, depending on harass config.
				Sida's Auto Carry: Revamped and Reborn supported
				Fully customizable Combo (Q, W, E, R), Harass (Q, W, E), and Draw
				Killsteal with Deadly Bloom and Stranglethorns
				Auto Passive prediction with Killsteal
				Stranglethorns Group prediction using AoE Skillshot Position library, which is built in. This lib is better than MEC for group prediction. Will use VIP prediction on all targets.
				Auto Ignite
				Extensive configuration options in two menus.
				Support Role Mode: One-click Enable to disable killsteal and other options to be a good ADC support. Leave off if you just dont't give a ****.
				Range Circles: Smart range circles turn on and off as their respective spells are available.

			Version: 1.0 Alpha: Unreleased
--]]

if myHero.charName ~= "Zyra" then return end

-- Check to see if user failed to read the forum...
if VIP_USER then
	if FileExist(SCRIPT_PATH..'Common/Collision.lua') then
		require "Collision"

		if type(Collision) ~= "userdata" then
			PrintChat("Your version of Collision.lua is incorrect. Please install v1.1.1 or later in Common folder.")
			return
		else
			assert(type(Collision.GetMinionCollision) == "function")
		end
	else
		PrintChat("Please install Collision.lua v1.1.1 or later in Common folder.")
		return
	end

	if FileExist(SCRIPT_PATH..'Common/2DGeometry.lua') then
		PrintChat("Please delete 2DGeometry.lua from your Common folder.")
	end

	assert(type(LineSegment.intersectionPoints) == "function")
end

function OnLoad()
	Vars()
	Menu()

	PrintChat(" >> Zyra: Rise of the Thorns by Kain loaded!")
end

function Vars()
	version = "2.3f"

	QRange, QSpeed, QDelay, QRadius = 800, math.huge, 0.7, 85 -- Old Delay: 0.500
	WRange, WSpeed, WDelay, WRadius = 825, math.huge, 0.2432, 10
	ERange, ESpeed, EDelay, EWidth = 1100, 1150, 0.16, 70 -- Some discrepency on delay: between .16 and .25
	RRange, RSpeed, RDelay, RRadius = 700, math.huge, 0.500, 500
	PRange, PSpeed, PDelay, PWidth = 1470, 1870, 0.500, 60 -- Need to review this. Passive missing more than it should.

	igniteRange = 600

	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, QRange, DAMAGE_MAGIC, false)

	useProdiction = false

	if VIP_USER then
		useProdiction = false

		tpQ = TargetPredictionVIP(QRange, QSpeed, QDelay, QRadius*2)
		tpE = TargetPredictionVIP(ERange, ESpeed, EDelay, EWidth)
		tpR = TargetPredictionVIP(RRange, RSpeed, RDelay, RRadius*2)
		tpP = TargetPredictionVIP(PRange, PSpeed, PDelay, PWidth)

		PrintChat("<font color='#CCCCCC'> >> Kain's Zyra - VIP Prediction Loaded <<</font>")
	else
		tpQ = TargetPrediction(QRange, QSpeed, QDelay*1000, QRadius*2)
		tpE = TargetPrediction(ERange, ESpeed/1000, EDelay*1000, EWidth)
		tpR = TargetPrediction(RRange, RSpeed, RDelay*1000, RRadius*2)
		tpP = TargetPrediction(PRange, PSpeed/1000, PDelay*1000, PWidth)
		PrintChat("<font color='#CCCCCC'> >> Kain's Zyra - Free Prediction <<</font>")
	end

	igniteSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)

	KeyQ = string.byte("Q")
	KeyW = string.byte("W")
	KeyE = string.byte("E")
	KeyR = string.byte("R")

	lastE = 0

	updateTextTimers = {}
	enemyMinions = {}

	IgniteRange = 600

	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		ignite = SUMMONER_1
    elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	else
		ignite = nil
	end

	QReady, WReady, EReady, RReady = false, false, false, false
	DFGSlot, HXGSlot, BWCSlot, STDSlot, SheenSlot, TrinitySlot, LichBaneSlot = nil, nil, nil, nil, nil, nil, nil
	DFGReady, HXGReady, BWCReady, STDReady, IReady = false, false, false, false, false

	enemyMinions = minionManager(MINION_ENEMY, ERange, myHero, MINION_SORT_HEALTH_ASC)

	-- Objects
	objZyraQ = "zyra_Q_cas.troy"
	objZyraE = "Zyra_E_sequence_impact.troy"

	isSACRunning = IsRunningSAC()

	debugMode = false
end

function Menu()
	ZyraConfig = scriptConfig("Zyra by Kain: Main - v"..version, "Zyra")

	ZyraConfig:addParam("sep", "----- [ Main ] -----", SCRIPT_PARAM_INFO, "")
	ZyraConfig:addParam("Combo","Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	ZyraConfig:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	ZyraConfig:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	ZyraConfig:addParam("SupportMode", "Support Role Mode", SCRIPT_PARAM_ONOFF, false)

	ZyraConfig:addParam("sep", "----- [ Combo Spells ] -----", SCRIPT_PARAM_INFO, "")
	ZyraConfig:addParam("ComboQ", "Use Deadly Bloom", SCRIPT_PARAM_ONOFF, true)
	ZyraConfig:addParam("ComboW", "Use Rampant Growth", SCRIPT_PARAM_ONOFF, true)
	ZyraConfig:addParam("ComboE", "Use Grasping Roots", SCRIPT_PARAM_ONOFF, true)
	ZyraConfig:addParam("DoubleW", "Double Seed on Combo", SCRIPT_PARAM_ONOFF, true)

	ZyraConfig:addParam("sep", "----- [ Harass Spells ] -----", SCRIPT_PARAM_INFO, "")
	ZyraConfig:addParam("HarassQ", "Use Deadly Bloom", SCRIPT_PARAM_ONOFF, true)
	ZyraConfig:addParam("HarassW", "Use Rampant Growth", SCRIPT_PARAM_ONOFF, true)
	ZyraConfig:addParam("HarassE", "Use Grasping Roots", SCRIPT_PARAM_ONOFF, false)

	ZyraConfig:addParam("sep", "----- [ Strangle Group ] -----", SCRIPT_PARAM_INFO, "")
	ZyraConfig:addParam("UltGroup", "Ult Enemy Team", SCRIPT_PARAM_ONOFF, true)
	ZyraConfig:addParam("UltGroupMinimum", "Ult Enemy Team Min.", SCRIPT_PARAM_SLICE, 3, 2, 5, 0)

	ZyraConfig:addParam("sep", "----- [ Killsteal ] -----", SCRIPT_PARAM_INFO, "")
	ZyraConfig:addParam("UltKillsteal", "Stranglethorn Killsteal", SCRIPT_PARAM_ONOFF, true)
	ZyraConfig:addParam("DeadlyBloomKS", "Deadly Bloom Killsteal", SCRIPT_PARAM_ONOFF, true)

	ZyraExtraConfig = scriptConfig("Zyra by Kain: Extras", "Zyra")
	ZyraExtraConfig:addParam("sep", "----- [ Misc ] -----", SCRIPT_PARAM_INFO, "")
	ZyraExtraConfig:addParam("MinionMarker", "Minion Marker", SCRIPT_PARAM_ONOFF, true)
	ZyraExtraConfig:addParam("Passive", "Auto Passive", SCRIPT_PARAM_ONOFF, true)

	ZyraExtraConfig:addParam("sep", "----- [ Advanced ] -----", SCRIPT_PARAM_INFO, "")
	ZyraExtraConfig:addParam("UseECollision", "Avoid Collisions on E", SCRIPT_PARAM_ONOFF, false)
	ZyraExtraConfig:addParam("HitChanceMin", "Prediction Hit Chance Min.", SCRIPT_PARAM_SLICE, 60, 1, 100, 0)
	ZyraExtraConfig:addParam("DoubleIgnite", "Don't Double Ignite", SCRIPT_PARAM_ONOFF, true)
	ZyraExtraConfig:addParam("ProMode", "Use Auto QWER Keys", SCRIPT_PARAM_ONOFF, true)
	ZyraExtraConfig:addParam("sep", "----- [ Draw ] -----", SCRIPT_PARAM_INFO, "")
	ZyraExtraConfig:addParam("DisableDraw", "Disable Draw", SCRIPT_PARAM_ONOFF, false)
	ZyraExtraConfig:addParam("DrawFurthest", "Draw Furthest Spell Available", SCRIPT_PARAM_ONOFF, true)
	ZyraExtraConfig:addParam("DrawTargetArrow", "Draw Arrow to Target", SCRIPT_PARAM_ONOFF, true)
	ZyraExtraConfig:addParam("DrawQ", "Draw Deadly Bloom", SCRIPT_PARAM_ONOFF, true)
	ZyraExtraConfig:addParam("DrawW", "Draw Rampant Growth", SCRIPT_PARAM_ONOFF, true)
	ZyraExtraConfig:addParam("DrawE", "Draw Grasping Roots", SCRIPT_PARAM_ONOFF, true)
	ZyraExtraConfig:addParam("DrawR", "Draw Stranglethorns", SCRIPT_PARAM_ONOFF, true)

	ZyraConfig:permaShow("Combo")
	ZyraConfig:permaShow("Harass")
	ZyraConfig:permaShow("Farm")

	ts.name = "Zyra"
	ZyraConfig:addTS(ts)
end

function IsRunningSAC()
	if _G.EnemyMinions then
		return true -- SAC Loaded
	else
		return false -- SAC not running
	end
end

function SpellCheck()
	DFGSlot, HXGSlot, BWCSlot, BRKSlot, STDSlot, SheenSlot, TrinitySlot, LichBaneSlot = GetInventorySlotItem(3128),
	GetInventorySlotItem(3146), GetInventorySlotItem(3144), GetInventorySlotItem(3153), GetInventorySlotItem(3131),
	GetInventorySlotItem(3057), GetInventorySlotItem(3078), GetInventorySlotItem(3100)

	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)

	DFGReady = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
	HXGReady = (HXGSlot ~= nil and myHero:CanUseSpell(HXGSlot) == READY)
	BWCReady = (BWCSlot ~= nil and myHero:CanUseSpell(BWCSlot) == READY)
	BRKReady = (BRKSlot ~= nil and myHero:CanUseSpell(BRKSlot) == READY)

	IReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
end

function UseItems(enemy)
    if enemy and not enemy.dead and GetDistance(enemy) < 550 then
        if DFGReady then CastSpell(DFGSlot, enemy) end
        if HXGReady then CastSpell(HXGSlot, enemy) end
        if BWCReady then CastSpell(BWCSlot, enemy) end
        if BRKReady then CastSpell(BRKSlot, enemy) end
    end
end

function OnTick()
	ts:update()

	SpellCheck()

	if ts ~= nil and ts.target ~= nil then
		if IsPassiveUp() then -- myHero is dead, but in passive state.
			if QReady and ZyraExtraConfig.Passive then
				Passive()
			end
		elseif not myHero.dead then
			AutoIgnite()
			if ZyraConfig.Combo then
				-- UseItems(ts.target)
				Combo()
			end
			if ZyraConfig.Harass then Harass() end
			if ZyraConfig.Farm then Farm() end
		end
	end
end

function IsPassiveUp()
	return myHero:GetSpellData(_Q).name == myHero:GetSpellData(_W).name or myHero:GetSpellData(_W).name == myHero:GetSpellData(_E).name
end

function OnCreateObj(object)
--[[
	if object then
		if object.name:find(objZyraQ) ~= nil and GetDistance(object) < QRange then
			-- Already handled elsewhere.
		end

		if object.name:find(objZyraE) ~= nil and GetDistance(object) < ERange then
			-- Already handled elsewhere.
		end
	end
--]]
end

function OnDeleteObj(object)
	-- Nothing to see here.
end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name == myHero:GetSpellData(_E).name then
		DamageOnRoot(spell)
	end
end

function DamageOnRoot(spell)
	if spell.endPos and ts and ts.target and ValidTarget(ts.target) then
		local EPos = tpE:GetPrediction(ts.target)
		if EPos then
			local intersection = LineSegment(Point(myHero.x, myHero.z), Point(spell.endPos.x, spell.endPos.z)):intersectionPoints(LineSegment(Point(ts.target.x, ts.target.z), Point(EPos.x, EPos.z)))[1]
			if intersection and GetDistance(intersection) < QRange then
				if QReady then
					CastSpell(_Q, intersection.x, intersection.y)
				end
				if WReady then
					if debugMode then PrintChat("onprocess W: "..intersection.x.."!"..intersection.y) end
					CastW(intersection.x, intersection.y)
					if WReady and ZyraConfig.DoubleW then
						if debugMode then PrintChat("onprocess double W: "..intersection.x.."!"..intersection.y) end
						CastW(intersection.x, intersection.y)
					end
				end
			elseif WReady then
				if VIP_USER then
					CastW(spell.endPos.x, spell.endPos.z)
				end
				if WReady and ZyraConfig.DoubleW then
					if VIP_USER then
						CastW(spell.endPos.x, spell.endPos.z)
					end
				end
			end
		end
	end
end

function Combo()
	if not ts or not ts.target then return end

	if not ValidTarget(ts.target) then return end

	-- Root combo
	if EReady and ZyraConfig.ComboE then
		CastE(ts.target)
	end

	-- Fires when target is already rooted.
	if QReady and ZyraConfig.ComboQ then
		CastQ(ts.target)
	end

	if not ZyraConfig.SupportMode and QReady and ZyraConfig.DeadlyBloomKS then
		DeadlyBloomKillsteal()
	end

	SpellCheck()

	if not ZyraConfig.SupportMode and (not QReady or not ZyraConfig.ComboQ) and (not EReady or not ZyraConfig.ComboE) and RReady and ZyraConfig.UltKillsteal then
		UltKillsteal()
	end

	if RReady and ZyraConfig.UltGroup then
		UltGroup(false)
	end
end

function CastQ(enemy)
	if not enemy and ts and ts.target then enemy = ts.target end

	if QReady then
		if not enemy.canMove then
			CastSpell(_Q, enemy.x, enemy.z)
			if GetDistance(enemy) < WRange then
				CastW(enemy.x, enemy.z)
				if debugMode then PrintChat("Q,W stun: Tried to cast W.") end
			else
				if debugMode then PrintChat("Q,W stun: W out of range error.") end
			end
		elseif ENotReadyToUse() then
			if VIP_USER and useProdiction then
				predic = tpQ:EnableTarget(enemy, true)
			else
				predic = GetQPrediction(enemy)
				return FireQ(enemy, predic, myHero:GetSpellData(_Q))
			end
		end
	end
end

function CastW(posX, posZ)
	if VIP_USER then
		Packet("S_CAST", {spellId = _W, fromX = posX, fromY = posZ, toX = posX, toY = posZ}):send()
	else
		CastSpell(_W, posX, posZ)
	end
end

function CastE(enemy)
	if not enemy and ts and ts.target then enemy = ts.target end

	if EReady then
		if VIP_USER and useProdiction then
			predic = tpE:EnableTarget(ts.target, true)
		else
			predic = GetEPrediction(ts.target)
			return FireE(ts.target, predic, myHero:GetSpellData(_E))
		end
	end
end

function FireQ(unit, predic, spell)
	if QReady and ValidTarget(unit, QRange) and predic and GetDistance(predic) < QRange and not unit.dead then
		local isEnemyRetreating = IsEnemyRetreating(unit, predic)
		if not isEnemyRetreating or (isEnemyRetreating and not IsNearRangeLimit(predic, QRange)) then
			CastSpell(_Q, predic.x, predic.z)
			if ZyraConfig.DoubleW or myHero:CanUseSpell(_E) == NOTLEARNED and ShouldCastW() then
				if GetDistance(predic) < WRange then
					CastW(predic.x, predic.z)
					if debugMode then PrintChat("Q,W: Tried to cast W.") end
				else
					if debugMode then PrintChat("Q,W: W out of range error.") end
				end
			end

			return true
		end
	end

	return false
end

function FireE(unit, predic, spell)
	if EReady and ValidTarget(unit, ERange) and predic and GetDistance(predic) < ERange and not unit.dead then
		local isEnemyRetreating = IsEnemyRetreating(unit, predic)
		if not isEnemyRetreating or (isEnemyRetreating and not IsNearRangeLimit(predic, ERange)) then
			-- This part is tricky. If non-VIP, then do W normally, then E.
			-- If VIP, then do E, then W using packets.
			if not VIP_USER and ShouldCastW() then CastW(predic.x, predic.z) end

			local castedE = false

			local col = nil
			if ZyraExtraConfig.UseECollision then
				col = GetECollision(predic, unit)
			end

			if not ZyraExtraConfig.UseECollision or not col then
				if debugMode then PrintChat("Cast E") end
				CastSpell(_E, predic.x, predic.z)
				castedE = true
			end

			SpellCheck()

			-- Cast W if E was cast.
			if VIP_USER and castedE and ShouldCastW() then
				if GetDistance(predic) < WRange then
					CastW(predic.x, predic.z)
					if debugMode then PrintChat("E,W: Tried to cast W.") end
				else
					if debugMode then PrintChat("E,W: W out of range error.") end
				end
			end
			if debugMode then PrintChat("E W") end
			return true
		end
	end

	return false
end

function IsNearRangeLimit(obj, range)
	if GetDistance(obj) >= (range * .95) then
		return true
	else
		return false
	end
end

function IsEnemyRetreating(target, predic)
	if GetDistance(predic) > GetDistance(target) then
		return true
	else
		return false
	end
end

function ShouldCastW()
	-- if WReady and ((ZyraConfig.Combo and ZyraConfig.ComboW) or (ZyraConfig.Harass and ZyraConfig.HarassW)) then
	if ((ZyraConfig.Combo and ZyraConfig.ComboW) or (ZyraConfig.Harass and ZyraConfig.HarassW)) then
		return true
	else
		return false
	end
end

function ENotReadyToUse()
	if not EReady or (ZyraConfig.Combo and not ZyraConfig.ComboE) or (ZyraConfig.Harass and not ZyraConfig.HarassE) then
		return true
	end

	return (myHero:CanUseSpell(_E) == COOLDOWN and (myHero:GetSpellData(_E).cd - myHero:GetSpellData(_E).currentCd > 1.5)) or myHero:CanUseSpell(_E) == NOTLEARNED
end

function Harass()
	if not ValidTarget(ts.target) then return end

	if QReady and ZyraConfig.HarassQ then
--[[
		local predPos = GetQPrediction(ts.target)
		if predPos then
			CastSpell(_Q, predPos.x, predPos.z)
			if WReady and ZyraConfig.HarassW then
				CastW(predPos.x, predPos.z)
			end
		end
--]]
		CastQ(ts.target)
	end

	if EReady and ZyraConfig.HarassE then
--[[
		local predPos = GetEPrediction(ts.target)
		if predPos then
			local col = GetECollision(predPos, ts.target)
			if not col then
				CastSpell(_E, predPos.x, predPos.z)
				if WReady and ZyraConfig.HarassW then
					CastW(predPos.x, predPos.z)
				end
			end
		end
--]]
		CastE(ts.target)
	end
end

function Farm()
	enemyMinions:update()
	for _, minion in ipairs(enemyMinions.objects) do
		if ValidTarget(minion) then
			if getDmg("AD", minion, myHero) * 1.1 > minion.health then
				myHero:Attack(minion)
			elseif getDmg("Q", minion, myHero) > minion.health then
				CastSpell(_Q, minion.x, minion.z)
			end
		end
	end
end

function Passive()
	-- Hit any killable enemy.
	for _, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, PRange) and getDmg("P", enemy, myHero) > enemy.health then
			local predPos = GetPPrediction(enemy)
			if predPos then
				CastSpell(_Q, predPos.x, predPos.z)
				return true
			end
		end
	end

	-- No one was killable, so just damage best target.
	if ValidTarget(ts.target, PRange) then
		local predPos = GetPPrediction(ts.target)
		if predPos then
			CastSpell(_Q, predPos.x, predPos.z)
			return true
		end
	end

	return false
end

function UltGroup(manual)
	if not ts or not ts.target then return false end

	if not manual and EnemyCount(myHero, (RRange + RRadius)) < ZyraConfig.UltGroupMinimum then return false end

	local spellPos = GetAoESpellPosition(RRadius, ts.target, RDelay * 1000)

	if spellPos and GetDistance(spellPos) <= RRange then
		if manual or EnemyCount(spellPos, RRadius) >= ZyraConfig.UltGroupMinimum then
			if debugMode then PrintChat("R AoE") end
			CastSpell(_R, spellPos.x, spellPos.z)
			return true
		end
	end

	return false
end

function DeadlyBloomKillsteal()
	if not QReady then return false end

	for _, enemy in pairs(GetEnemyHeroes()) do
		if enemy and not enemy.dead and enemy.health < getDmg("Q", enemy, myHero) then
			CastQ(enemy)
			return true
		end
	end

	return false
end

function UltKillsteal()
	for _, enemy in pairs(GetEnemyHeroes()) do
		if enemy and not enemy.dead and enemy.health < getDmg("R", enemy, myHero) then
			local spellPos = GetAoESpellPosition(RRadius, ts.target, RDelay * 1000)
			if spellPos and GetDistance(spellPos) <= RRange then
				if not enemy.dead then
					if debugMode then PrintChat("R Killsteal") end
					CastSpell(_R, spellPos.x, spellPos.z)
					return true
				end
			end
		end
	end

	return false
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

function AutoIgnite()
	if IReady and not myHero.dead then
		for _, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				if enemy ~= nil and enemy.team ~= myHero.team and not enemy.dead and enemy.visible and GetDistance(enemy) < IgniteRange and enemy.health < getDmg("IGNITE", enemy, myHero) then
					if ZyraExtraConfig.DoubleIgnite and not TargetHaveBuff("SummonerDot", enemy) then
						CastSpell(ignite, enemy)
					elseif not ZyraExtraConfig.DoubleIgnite then
						CastSpell(ignite, enemy)
					end
				end
			end
		end
	end
end

-- Draw

function OnDraw()
	if ZyraExtraConfig.DrawTargetArrow and ts ~= nil and ts.target ~= nil and not ts.target.dead and (ZyraConfig.Combo or ZyraConfig.Harass) then
		DrawArrowsToPos(myHero, ts.target)
	end

	if not ZyraExtraConfig.DisableDraw and not myHero.dead then
		local farSpell = FindFurthestReadySpell()

		-- DrawCircle(myHero.x, myHero.y, myHero.z, getTrueRange(), 0x808080) -- Gray

		if ZyraExtraConfig.DrawQ and QReady and ((ZyraExtraConfig.DrawFurthest and farSpell and farSpell == QRange) or not ZyraExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0x0099CC) -- Blue
		end

		if ZyraExtraConfig.DrawW and WReady and ((ZyraExtraConfig.DrawFurthest and farSpell and farSpell == WRange) or not ZyraExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, WRange, 0xFFFF00) -- Yellow
		end
		
		if ZyraExtraConfig.DrawE and EReady and ((ZyraExtraConfig.DrawFurthest and farSpell and farSpell == ERange) or not ZyraExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0x00FF00) -- Green
		end

		local RRangePlusRadius = RRange + RRadius
		if ZyraExtraConfig.DrawR and RReady and ((ZyraExtraConfig.DrawFurthest and farSpell and farSpell == RRangePlusRadius) or not ZyraExtraConfig.DrawFurthest) then
			DrawCircle(myHero.x, myHero.y, myHero.z, RRangePlusRadius, 0xFF0000) -- Red
		end

		if ts ~= nil and ts.target ~= nil then
			for j=0, 10 do
				DrawCircle(ts.target.x, ts.target.y, ts.target.z, 40 + j*1.5, 0x00FF00) -- Green
			end
		end

		MinionMarkerOnDraw()
	end
end

function MinionMarkerOnDraw()
	if ZyraExtraConfig.MinionMarker then
		if not ZyraConfig.Farm then enemyMinions:update() end
		for _, minion in ipairs(enemyMinions.objects) do
			if ValidTarget(minion) and getDmg("Q", minion, myHero) > minion.health then
				for i = 1, 5 do
					DrawCircle(minion.x, minion.y, minion.z, 50+i, (getDmg("AD", minion, myHero) * 1.1 > minion.health and 0x8080FF00 or 0xFFFF0000))
				end
			end
		end
	end
end

function FindFurthestReadySpell()
	local farSpell = nil

	if ZyraExtraConfig.DrawQ and QReady then farSpell = QRange end
	if ZyraExtraConfig.DrawW and WReady and (not farSpell or WRange > farSpell) then farSpell = WRange end
	if ZyraExtraConfig.DrawE and EReady and (not farSpell or ERange > farSpell) then farSpell = ERange end

	local RRangePlusRadius = RRange + RRadius
	if ZyraExtraConfig.DrawR and RReady and (not farSpell or RRangePlusRadius > farSpell) then farSpell = RRangePlusRadius end

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

function GetQPrediction(enemy)
	if not ValidTarget(enemy) or not IsGoodHitChance(tpQ, enemy) then return end
	return tpQ:GetPrediction(enemy)
end

function GetEPrediction(enemy)
	if not ValidTarget(enemy) or not IsGoodHitChance(tpE, enemy) then return end
	return tpE:GetPrediction(enemy)
end

function GetECollision(pred, enemy)
	if VIP_USER then
		local col = Collision(ERange, ESpeed, EDelay, EWidth)
		if not col then return false end
		return col:GetMinionCollision(myHero, pred)
	else
		return willHitMinion(pred, EWidth)
	end
end

function GetPPrediction(enemy)
	if not ValidTarget(enemy) or not IsGoodHitChance(tpP, enemy) then return end
	return tpP:GetPrediction(enemy)
end

function IsGoodHitChance(spellPred, enemy)
	if VIP_USER and spellPred and enemy and spellPred:GetHitChance(enemy) > (ZyraExtraConfig.HitChanceMin / 100) then
		return true
	elseif not VIP_USER then
		return true
	else
		return false
	end
end

function willHitMinion(predic, width)
	local hitCount = 0
	for _, minionObjectE in pairs(enemyMinions.objects) do
		if minionObjectE ~= nil and string.find(minionObjectE.name,"Minion_") == 1 and minionObjectE.team ~= myHero.team and minionObjectE.dead == false then
			if predic ~= nil and myHero:GetDistance(minionObjectE) < 900 then
				 ex = myHero.x
				 ez = myHero.z
				 tx = predic.x
				 tz = predic.z
				 dx = ex - tx
				 dz = ez - tz
				 if dx ~= 0 then
				 m = dz/dx
				 c = ez - m*ex
				 end
				 mx = minionObjectE.x
				 mz = minionObjectE.z
				 distanc = (math.abs(mz - m*mx - c))/(math.sqrt(m*m+1))
				 if distanc < width and math.sqrt((tx - ex)*(tx - ex) + (tz - ez)*(tz - ez)) > math.sqrt((tx - mx)*(tx - mx) + (tz - mz)*(tz - mz)) then
						return true
				 end
			end
		end
	 end

	 return false
end

function OnWndMsg(msg,key)
	if ts and ts.target and ZyraExtraConfig.ProMode then
		if msg == KEY_DOWN and key == KeyQ then CastQ() end
		if msg == KEY_DOWN and key == KeyE then CastE() end
		if msg == KEY_DOWN and key == KeyR then UltGroup(true) end
	end
end

-- End of Zyra script

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

--UPDATEURL=https://bitbucket.org/KainBoL/bol/raw/master/Zyra%20-%20Rise%20of%20the%20Thorns.lua
--HASH=77D05F9318022C2D776E094D05D6B046
