--[[
    Good Evade 0.13c
V08:
- smoothness
- more skillshots
- improved wall detection
- slightly improved evasion from FOG skillshots
- improved multiple skillshots dodging
- nil error fixes
- priority to cc dodging
- draw optimizations
V09:
- leona E dodge improving
- will dodge noncc more often now
- TurretsPE check
- perfomance optimizations
- smooth oprimizations (less hp -> less smooth)
- cass Q, karthus Q
V010-012:
 - bugfixes
V013:
 - more dashes (Graves / Ezreal / Kassadin / Riven / Corki / Tristana / Renekton) with custom logic 
 (check code, ex Ez will only use E on blitz / ashe / leona)
V013b:
 - shoulndt break channeled spells anymore
 - green error spam fix 
v013c:
 - lucian dash  
]]

-- Config ----------------------------------------------------------------------
if not VIP_USER then return end

NONE = 0
ALLY = 1
ENEMY = 2
NEUTRAL = 4
ALL = 7

class 'TurretsPE' -- {
    TurretsPE.tables = {
        [ALLY] = {},
        [ENEMY] = {},
        [NEUTRAL] = {}
    }

    TurretsPE.instance = ""

    function TurretsPE:__init()
        self.modeCount = 7

        for i = 1, objManager.maxObjects, 1 do
            local turret = objManager:GetObject(i)
            self:AddObject(turret)
        end

        AddCreateObjCallback(function(obj) self:OnCreateObj(obj) end)
    end

    function TurretsPE:OnCreateObj(obj)
        self:AddObject(obj)
    end

    function TurretsPE.GetObjects(mode, range, pFrom)
        return TurretsPE.Instance():GetObjectsFromTable(mode, range, pFrom)
    end

    function TurretsPE.Instance()
        if TurretsPE.instance == "" then TurretsPE.instance = TurretsPE() end return TurretsPE.instance 
    end

    function TurretsPE:AddObject(obj)
        if obj ~= nil and obj.valid and obj.type == "obj_AI_Turret" then
            DelayAction(function(obj)
                if obj.team == myHero.team then table.insert(TurretsPE.tables[ALLY], obj) return end
                if obj.team == TEAM_ENEMY then table.insert(TurretsPE.tables[ENEMY], obj) return end
                if obj.team == TEAM_NEUTRAL then table.insert(TurretsPE.tables[NEUTRAL], obj) return end
            end, 0, {obj})
        end
    end 

    function TurretsPE:GetObjectsFromTable(mode, range, pFrom)
        if mode > self.modeCount then mode = self.modeCount end 
        if range == nil or range < 0 then range = math.huge end
        if pFrom == nil then pFrom = myHero end
        tempTable = {}

        for i, tableType in pairs(TurretsPE.tables) do
            if bit32.band(mode, i) == i then 
                for k,v in pairs(tableType) do 
                    if v and v.valid then 
                        if v.visible and GetDistance(v, pFrom) <= range then table.insert(tempTable, v) end
                    else table.remove(tableType, k) k = k - 1 end
                end 
            end 
        end 
        return tempTable
    end
-- }

class 'CollisionPE' -- {
    HERO_ALL = 1
    HERO_ENEMY = 2
    HERO_ALLY = 3


    function CollisionPE:__init(sRange, projSpeed, sDelay, sWidth)
        uniqueId = uniqueId + 1
        self.uniqueId = uniqueId

        self.sRange = sRange
        self.projSpeed = projSpeed
        self.sDelay = sDelay
        self.sWidth = sWidth/2

        self.enemyMinions = minionManager(MINION_ALL, 2000, myHero, MINION_SORT_HEALTH_ASC)
        self.minionupdate = 0
    end

    function CollisionPE:GetMinionCollision(pStart, pEnd)
        self.enemyMinions:update()

        local distance =  GetDistance(pStart, pEnd)
        local prediction = TargetPredictionVIP(self.sRange, self.projSpeed, self.sDelay, self.sWidth)
        local mCollision = {}

        if distance > self.sRange then
            distance = self.sRange
        end

        local V = Vector(pEnd) - Vector(pStart)
        local k = V:normalized()
        local P = V:perpendicular2():normalized()

        local t,i,u = k:unpack()
        local x,y,z = P:unpack()

        local startLeftX = pStart.x + (x *self.sWidth)
        local startLeftY = pStart.y + (y *self.sWidth)
        local startLeftZ = pStart.z + (z *self.sWidth)
        local endLeftX = pStart.x + (x * self.sWidth) + (t * distance)
        local endLeftY = pStart.y + (y * self.sWidth) + (i * distance)
        local endLeftZ = pStart.z + (z * self.sWidth) + (u * distance)
        
        local startRightX = pStart.x - (x * self.sWidth)
        local startRightY = pStart.y - (y * self.sWidth)
        local startRightZ = pStart.z - (z * self.sWidth)
        local endRightX = pStart.x - (x * self.sWidth) + (t * distance)
        local endRightY = pStart.y - (y * self.sWidth) + (i * distance)
        local endRightZ = pStart.z - (z * self.sWidth)+ (u * distance)

        local startLeft = WorldToScreen(D3DXVECTOR3(startLeftX, startLeftY, startLeftZ))
        local endLeft = WorldToScreen(D3DXVECTOR3(endLeftX, endLeftY, endLeftZ))
        local startRight = WorldToScreen(D3DXVECTOR3(startRightX, startRightY, startRightZ))
        local endRight = WorldToScreen(D3DXVECTOR3(endRightX, endRightY, endRightZ))
       
        local poly = Polygon(Point(startLeft.x, startLeft.y),  Point(endLeft.x, endLeft.y), Point(startRight.x, startRight.y),   Point(endRight.x, endRight.y))

         for index, minion in pairs(self.enemyMinions.objects) do
            if minion ~= nil and minion.valid and not minion.dead then
                if GetDistance(pStart, minion) < distance then
                    local pos, t, vec = prediction:GetPrediction(minion) 
                    local lineSegmentLeft = LineSegment(Point(startLeftX,startLeftZ), Point(endLeftX, endLeftZ))
                    local lineSegmentRight = LineSegment(Point(startRightX,startRightZ), Point(endRightX, endRightZ))
                    local toScreen, toPoint
                    if pos ~= nil then
                        toScreen = WorldToScreen(D3DXVECTOR3(minion.x, minion.y, minion.z))
                        toPoint = Point(toScreen.x, toScreen.y)
                    else 
                        toScreen = WorldToScreen(D3DXVECTOR3(minion.x, minion.y, minion.z))
                        toPoint = Point(toScreen.x, toScreen.y)
                    end


                    if poly:contains(toPoint) then
                        table.insert(mCollision, minion)
                    else
                        if pos ~= nil then
                            distance1 = Point(pos.x, pos.z):distance(lineSegmentLeft)
                            distance2 = Point(pos.x, pos.z):distance(lineSegmentRight)
                        else 
                            distance1 = Point(minion.x, minion.z):distance(lineSegmentLeft)
                            distance2 = Point(minion.x, minion.z):distance(lineSegmentRight)
                        end
                        if (distance1 < (getHitBoxRadius(minion)*2+10) or distance2 < (getHitBoxRadius(minion) *2+10)) then
                            table.insert(mCollision, minion)
                        end
                    end
                end
            end
        end
        if #mCollision > 0 then return true, mCollision else return false, mCollision end
    end

    function CollisionPE:GetHeroCollision(pStart, pEnd, mode)
        if mode == nil then mode = HERO_ENEMY end
        local heros = {}

        for i = 1, heroManager.iCount do
            local hero = heroManager:GetHero(i)
            if (mode == HERO_ENEMY or mode == HERO_ALL) and hero.team ~= myHero.team then
                table.insert(heros, hero)
            elseif (mode == HERO_ALLY or mode == HERO_ALL) and hero.team == myHero.team and not hero.isMe then
                table.insert(heros, hero)
            end
        end

        local distance =  GetDistance(pStart, pEnd)
        local prediction = TargetPredictionVIP(self.sRange, self.projSpeed, self.sDelay, self.sWidth)
        local hCollision = {}

        if distance > self.sRange then
            distance = self.sRange
        end

        local V = Vector(pEnd) - Vector(pStart)
        local k = V:normalized()
        local P = V:perpendicular2():normalized()

        local t,i,u = k:unpack()
        local x,y,z = P:unpack()

        local startLeftX = pStart.x + (x *self.sWidth)
        local startLeftY = pStart.y + (y *self.sWidth)
        local startLeftZ = pStart.z + (z *self.sWidth)
        local endLeftX = pStart.x + (x * self.sWidth) + (t * distance)
        local endLeftY = pStart.y + (y * self.sWidth) + (i * distance)
        local endLeftZ = pStart.z + (z * self.sWidth) + (u * distance)
        
        local startRightX = pStart.x - (x * self.sWidth)
        local startRightY = pStart.y - (y * self.sWidth)
        local startRightZ = pStart.z - (z * self.sWidth)
        local endRightX = pStart.x - (x * self.sWidth) + (t * distance)
        local endRightY = pStart.y - (y * self.sWidth) + (i * distance)
        local endRightZ = pStart.z - (z * self.sWidth)+ (u * distance)

        local startLeft = WorldToScreen(D3DXVECTOR3(startLeftX, startLeftY, startLeftZ))
        local endLeft = WorldToScreen(D3DXVECTOR3(endLeftX, endLeftY, endLeftZ))
        local startRight = WorldToScreen(D3DXVECTOR3(startRightX, startRightY, startRightZ))
        local endRight = WorldToScreen(D3DXVECTOR3(endRightX, endRightY, endRightZ))
       
        local poly = Polygon(Point(startLeft.x, startLeft.y),  Point(endLeft.x, endLeft.y), Point(startRight.x, startRight.y),   Point(endRight.x, endRight.y))

        for index, hero in pairs(heros) do
            if hero ~= nil and hero.valid and not hero.dead then
                if GetDistance(pStart, hero) < distance then
                    local pos, t, vec = prediction:GetPrediction(hero) 
                    local lineSegmentLeft = LineSegment(Point(startLeftX,startLeftZ), Point(endLeftX, endLeftZ))
                    local lineSegmentRight = LineSegment(Point(startRightX,startRightZ), Point(endRightX, endRightZ))
                    local toScreen, toPoint
                    if pos ~= nil then
                        toScreen = WorldToScreen(D3DXVECTOR3(pos.x, hero.y, pos.z))
                        toPoint = Point(toScreen.x, toScreen.y)
                    else 
                        toScreen = WorldToScreen(D3DXVECTOR3(hero.x, hero.y, hero.z))
                        toPoint = Point(toScreen.x, toScreen.y)
                    end


                    if poly:contains(toPoint) then
                        table.insert(hCollision, hero)
                    else
                        if pos ~= nil then
                            distance1 = Point(pos.x, pos.z):distance(lineSegmentLeft)
                            distance2 = Point(pos.x, pos.z):distance(lineSegmentRight)
                        else 
                            distance1 = Point(hero.x, hero.z):distance(lineSegmentLeft)
                            distance2 = Point(hero.x, hero.z):distance(lineSegmentRight)
                        end
                        if (distance1 < (getHitBoxRadius(hero)*2+10) or distance2 < (getHitBoxRadius(hero) *2+10)) then
                            table.insert(hCollision, hero)
                        end
                    end
                end
            end
        end
        if #hCollision > 0 then return true, hCollision else return false, hCollision end
    end

    function CollisionPE:GetCollision(pStart, pEnd)
        local b , minions = self:GetMinionCollision(pStart, pEnd)
        local t , heros = self:GetHeroCollision(pStart, pEnd, HERO_ENEMY)

        if not b then return t, heros end 
        if not t then return b, minions end 

        local all = {}

        for index, hero in pairs(heros) do
            table.insert(all, hero)
        end

        for index, minion in pairs(minions) do
            table.insert(all, minion)
        end 

        return true, all
    end

    function getHitBoxRadius(target)
        return GetDistance(target, target.minBBox)/2
    end
-- }

_G.evade = false
evadeBuffer = 15 -- expand the dangerous area (safer evades in laggy situations)
moveBuffer = 25 -- additional movement distance (champions stop a few pixels before their destination)
smoothing = 75 -- make movements smoother by moving further between evasion phases
local collizion = CollisionPE(500, 400, 0, 100)
champions = {
    ["Lux"] = {charName = "Lux", skillshots = {
        ["Light Binding"] =  {name = "Light Binding", spellName = "LuxLightBinding", spellDelay = 250, projectileName = "LuxLightBinding_mis.troy", projectileSpeed = 1200, range = 1300, radius = 80, type = "line", cc = "true"},
		["Lucent Singularity"] =  {name = "Lucent Singularity", spellName = "LuxLightStrikeKugel", spellDelay = 237, projectileName = "LuxLightstrike_mis.troy", projectileSpeed = 1310, range = 1100, radius = 187.5, type = "circular", cc = "false"},
    }},
    ["Nidalee"] = {charName = "Nidalee", skillshots = {
        ["Javelin Toss"] = {name = "Javelin Toss", spellName = "JavelinToss", spellDelay = 100, projectileName = "nidalee_javelinToss_mis.troy", projectileSpeed = 1300, range = 1500, radius = 60, type = "line", cc = "false"}
    }},
    ["Karma"] = {charName = "Karma", skillshots = {
        ["Inner Flame"] = {name = "Inner Flame", spellName = "KarmaQ", spellDelay = 218, projectileName = "TEMP_KarmaQMis.troy", projectileSpeed = 1575, range = 950, radius = 80, type = "line", cc = "false"},
		["Inner Flame"] = {name = "Inner Flame", spellName = "KarmaQ", spellDelay = 218, projectileName = "TEMP_KarmaQMMis.troy", projectileSpeed = 1575, range = 950, radius = 80, type = "line", cc = "false"}
    }},
		
    ["Gragas"] = {charName = "Gragas", skillshots = {
        ["Barrel Roll"] = {name = "Barrel Roll", spellName = "GragasBarrelRollMissile", spellDelay = 250, projectileName = "gragas_barrelroll_mis.troy", projectileSpeed = 1000, range = 1100, radius = 175, type = "circular", cc = "false"}
    }},
    ["Kennen"] = {charName = "Kennen", skillshots = {
        ["Thundering Shuriken"] = {name = "Thundering Shuriken", spellName = "KennenShurikenHurlMissile1", spellDelay = 180, projectileName = "kennen_ts_mis.troy", projectileSpeed = 1640, range = 1050, radius = 53, type = "line", cc = "false"}
    }},
    ["Amumu"] = {charName = "Amumu", skillshots = {
        ["Bandage Toss"] = {name = "Bandage Toss", spellName = "BandageToss", spellDelay = 250, projectileName = "Bandage_beam.troy", projectileSpeed = 2000, range = 1100, radius = 80, type = "line", cc = "true"}
    }},
    ["Lee Sin"] = {charName = "LeeSin", skillshots = {
        ["Sonic Wave"] = {name = "Sonic Wave", spellName = "BlindMonkQOne", spellDelay = 250, projectileName = "blindMonk_Q_mis_01.troy", projectileSpeed = 1800, range = 1100, radius = 60, type = "line", cc = "false"}
    }},
    ["Morgana"] = {charName = "Morgana", skillshots = {
        ["Dark Binding"] = {name = "Dark Binding", spellName = "DarkBindingMissile", spellDelay = 250, projectileName = "DarkBinding_mis.troy", projectileSpeed = 1200, range = 1300, radius = 70, type = "line", cc = "true"}
    }},
    ["Ezreal"] = {charName = "Ezreal", skillshots = {
        ["Mystic Shot"]             = {name = "Mystic Shot",      spellName = "EzrealMysticShotMissile",      spellDelay = 250,  projectileName = "Ezreal_mysticshot_mis.troy",  projectileSpeed = 1975, range = 1200,  radius = 80,  type = "line", cc = "false"},
        --["Essence Flux"]            = {name = "Essence Flux",     spellName = "EzrealEssenceFluxMissile",     spellDelay = 250,  projectileName = "Ezreal_essenceflux_mis.troy", projectileSpeed = 1510, range = 1050,  radius = 60,  type = "line", cc = "false"},        
        ["Trueshot Barrage"]        = {name = "Trueshot Barrage", spellName = "EzrealTrueshotBarrage",        spellDelay = 1000, projectileName = "Ezreal_TrueShot_mis.troy",    projectileSpeed = 1990, range = 20000, radius = 250, type = "line", cc = "false"},
        ["Mystic Shot (Pulsefire)"] = {name = "Mystic Shot",      spellName = "EzrealMysticShotPulseMissile", spellDelay = 250,  projectileName = "Ezreal_mysticshot_mis.troy",  projectileSpeed = 1975, range = 1200,  radius = 80,  type = "line", cc = "false"}
    }},
    ["Ahri"] = {charName = "Ahri", skillshots = {
        ["Orb of Deception"] = {name = "Orb of Deception", spellName = "AhriOrbofDeception", spellDelay = 250, projectileName = "Ahri_Orb_mis.troy",   projectileSpeed = 1660, range = 1000, radius = 50, type = "line", cc = "false"},
        ["Charm"]            = {name = "Charm",            spellName = "AhriSeduce",         spellDelay = 250, projectileName = "Ahri_Charm_mis.troy", projectileSpeed = 1535, range = 1000, radius = 50, type = "line", cc = "true"}
    }},
    ["Leona"] = {charName = "Leona", skillshots = {
        ["Zenith Blade"] = {name = "LeonaZenithBlade", spellName = "LeonaZenithBlade", spellDelay = 250, projectileName = "Leona_ZenithBlade_mis.troy", projectileSpeed = 2000, range = 900, radius = 90, type = "line", cc = "true"},
        ["Solar Flare"] = {name = "SolarFlare", spellName = "LeonaSolarFlare", spellDelay = 250, projectileName = "TEST", projectileSpeed = 1000, range = 1200, radius = 250, type = "circular", cc = "true"}
    }},
    ["Chogath"] = {charName = "Chogath", skillshots = {
        ["Rupture"] = {name = "Rupture", spellName = "Rupture", spellDelay = 290, projectileName = "rupture_cas_01_red_team.troy", projectileSpeed = 1000, range = 950, radius = 190, type = "circular", cc = "true"}
    }},
    ["Blitzcrank"] = {charName = "Blitzcrank", skillshots = {
        ["RocketGrab"] = {name = "RocketGrab", spellName = "RocketGrabMissile", spellDelay = 125, projectileName = "FistGrab_mis.troy", projectileSpeed = 1800, range = 1050, radius = 70, type = "line", cc = "true"}
    }},
    ["Anivia"] = {charName = "Anivia", skillshots = {
        ["Flash Frost"] = {name = "Flash Frost", spellName = "FlashFrostSpell", spellDelay = 250, projectileName = "Cryo_FlashFrost_mis.troy", projectileSpeed = 850, range = 1100, radius = 110, type = "line", cc = "true"}
    }},
    ["Zyra"] = {charName = "Zyra", skillshots = {
        ["Grasping Roots"] = {name = "Grasping Roots", spellName = "ZyraGraspingRoots", spellDelay = 250, projectileName = "Zyra_E_sequence_impact.troy", projectileSpeed = 1150, range = 1150, radius = 70,  type = "line", cc = "true"},
        ["Zyra Passive Death"] = {name = "Zyra Passive", spellName = "ZyraPassiveDeathMissile", spellDelay = 250, projectileName = "zyra_passive_plant_mis_fire.troy", projectileSpeed = 1900, range = 1474, radius = 70,  type = "line", cc = "false"},
    }},
    ["Nautilus"] = {charName = "Nautilus", skillshots = {
        ["Dredge Line"] = {name = "Dredge Line", spellName = "NautilusAnchorDragMissile", spellDelay = 250, projectileName = "Nautilus_Q_mis.troy", projectileSpeed = 1965, range = 1075, radius = 60, type = "line", cc = "true"}
    }},
    ["Caitlyn"] = {charName = "Caitlyn", skillshots = {
        ["Piltover Peacemaker"] = {name = "Piltover Peacemaker", spellName = "CaitlynPiltoverPeacemaker", spellDelay = 625, projectileName = "caitlyn_Q_mis.troy", projectileSpeed = 2150, range = 1300, radius = 60, type = "line", cc = "false"}
    }},
    ["Mundo"] = {charName = "DrMundo", skillshots = {
        ["Infected Cleaver"] = {name = "Infected Cleaver", spellName = "InfectedCleaverMissile", spellDelay = 250, projectileName = "dr_mundo_infected_cleaver_mis.troy", projectileSpeed = 1975, range = 1050, radius = 70, type = "line", cc = "false"}
    }},
    ["Brand"] = {charName = "Brand", skillshots = {
        ["Brand Missile"] = {name = "BrandBlazeMissile", spellName = "BrandBlazeMissile", spellDelay = 250, projectileName = "BrandBlaze_mis.troy", projectileSpeed = 1565, range = 1100, radius = 50, type = "line", cc = "false"},
    }},
    ["Corki"] = {charName = "Corki", skillshots = {
        ["Missile Barrage small"] = {name = "Missile Barrage small", spellName = "MissileBarrageMissile", spellDelay = 175, projectileName = "corki_MissleBarrage_mis.troy", projectileSpeed = 1950, range = 1250, radius = 50, type = "line", cc = "false"},
        ["Missile Barrage big"] = {name = "Missile Barrage big", spellName = "MissileBarrageMissile2", spellDelay = 175, projectileName = "corki_MissleBarrage_DD_mis.troy", projectileSpeed = 1950, range = 1250, radius = 50, type = "line", cc = "false"}
    }},
    ["Swain"] = {charName = "Swain", skillshots = {
        ["Nevermove"] = {name = "Nevermove", spellName = "SwainShadowGrasp", spellDelay = 250, projectileName = "swain_shadowGrasp_transform.troy", projectileSpeed = 1000, range = 900, radius = 180, type = "circular", cc = "true"}
    }},
    ["Ashe"] = {charName = "Ashe", skillshots = {
        ["EnchantedArrow"] = {name = "EnchantedArrow", spellName = "EnchantedCrystalArrow", spellDelay = 125, projectileName = "EnchantedCrystalArrow_mis.troy", projectileSpeed = 1600, range = 25000, radius = 150, type="line", cc = "true"}
    }},
    ["KogMaw"] = {charName = "KogMaw", skillshots = {
        ["Living Artillery"] = {name = "Living Artillery", spellName = "KogMawLivingArtillery", spellDelay = 250, projectileName = "KogMawLivingArtillery_cas_green.troy", projectileSpeed = 1050, range = 2200, radius = 180, type="circular", cc = "false"}
    }},
    ["KhaZix"] = {charName = "KhaZix", skillshots = {
        ["KhaZix W Missile"] = {name = "KhaZix W Enhanced", spellName = "KhaZixW", spellDelay = 250, projectileName = "Khazix_W_mis.troy", projectileSpeed = 1700, range = 1025, radius = 70, type="line", cc = "false"},
    }},
    ["Zed"] = {charName = "Zed", skillshots = {
        ["ZedShuriken"] = {name = "ZedShuriken", spellName = "ZedShuriken", spellDelay = 0, projectileName = "Zed_Q_Mis.troy", projectileSpeed = 1700, range = 925, radius = 50, type="line", cc = "false"}
    }},
    ["Leblanc"] = {charName = "Leblanc", skillshots = {
        ["Ethereal Chains"] = {name = "Ethereal Chains", spellName = "LeblancSoulShackle", spellDelay = 250, projectileName = "leBlanc_shackle_mis.troy", projectileSpeed = 1585, range = 960, radius = 50, type = "line", cc = "true"},
        ["Ethereal Chains R"] = {name = "Ethereal Chains R", spellName = "LeblancSoulShackleM", spellDelay = 250, projectileName = "leBlanc_shackle_mis_ult.troy", projectileSpeed = 1585, range = 960, radius = 50, type = "line", cc = "true"},
    }},
    ["Elise"] = {charName = "Elise", skillshots = {
        ["Cocoon"] = {name = "Cocoon", spellName = "EliseHumanE", spellDelay = 250, projectileName = "Elise_human_E_mis.troy", projectileSpeed = 1450, range = 1100, radius = 70, type="line", cc = "true"}
    }},
    ["Lulu"] = {charName = "Lulu", skillshots = {
        ["luluQ1"] = {name = "luluQ1", spellName = "LuluQMissile", spellDelay = 100, projectileName = "Lulu_Q_Mis.troy", projectileSpeed = 1450, range = 1000, radius = 50, type="line", cc = "false"},
        ["luluQ2"] = {name = "luluQ2", spellName = "LuluQ", spellDelay = 250, projectileName = "Lulu_Q_Mis.troy", projectileSpeed = 1375, range = 1000, radius = 50, type="line", cc = "false"}
    }},
    ["Thresh"] = {charName = "Thresh", skillshots = {
        ["ThreshQ"] = {name = "ThreshQ", spellName = "ThreshQ", spellDelay = 500, projectileName = "Thresh_Q_whip_beam.troy", projectileSpeed = 1900, range = 1100, radius = 70, type="line", cc = "true"}
    }},
    ["Shen"] = {charName = "Shen", skillshots = {
        ["ShadowDash"] = {name = "ShadowDash", spellName = "ShenShadowDash", spellDelay = 125, projectileName = "shen_shadowDash_mis.troy", projectileSpeed = 2000, range = 575, radius = 50, type="line", cc = "true"}
    }},
    ["Quinn"] = {charName = "Quinn", skillshots = {
        ["QuinnQ"] = {name = "QuinnQ", spellName = "QuinnQ", spellDelay = 100, projectileName = "Quinn_Q_missile.troy", projectileSpeed = 1550, range = 1050, radius = 80, type="line", cc = "true"}
    }},
    ["Nami"] = {charName = "Nami", skillshots = {
        ["NamiQ"] = {name = "NamiQ", spellName = "NamiQ", spellDelay = 700, projectileName = "Nami_Q_mis.troy", projectileSpeed = 800, range = 875, radius = 225, type="circular", cc = "true"},    
    }},
    ["Malphite"] = {charName = "Malphite", skillshots = {
        ["UFSlash"] = {name = "UFSlash", spellName = "UFSlash", spellDelay = 250, projectileName = "TEST", projectileSpeed = 1800, range = 1000, radius = 160, type="line", cc = "true"},    
    }},
    ["Sejuani"] = {charName = "Sejuani", skillshots = {
        ["SejuaniR"] = {name = "SejuaniR", spellName = "SejuaniGlacialPrisonCast", spellDelay = 250, projectileName = "Sejuani_R_mis.troy", projectileSpeed = 1600, range = 1200, radius = 110, type="line", cc = "true"},    
    }},
    ["Varus"] = {charName = "Varus", skillshots = {
        ["VarusR"] = {name = "VarusR", spellName = "VarusR", spellDelay = 250, projectileName = "VarusRMissile.troy", projectileSpeed = 2000, range = 1250, radius = 100, type="line", cc = "true"},
    }},
    ["Fizz"] = {charName = "Fizz", skillshots = {
        ["FizzR1"] = {name = "FizzR1", spellName = "FizzMarinerDoom", spellDelay = 250, projectileName = "Fizz_UltimateMissile.troy", projectileSpeed = 1375, range = 1300, radius = 80, type = "line", cc = "true"}, -- line part
    }},
    ["Karthus"] = {charName = "Karthus", skillshots = {
        ["Lay Waste"] = {name = "Lay Waste", spellName = "LayWaste", spellDelay = 390, projectileName = "LayWaste_point.troy", projectileSpeed = 500, range = 875, radius = 140, type = "circular", cc = "false"}
    }},
    ["Cassiopeia"] = {charName = "Cassiopeia", skillshots = {
        ["Noxious Blast"] = {name = "Noxious Blast", spellName = "CassiopeiaNoxiousBlast", spellDelay = 200, projectileName = "CassNoxiousSnakePlane_green.troy", projectileSpeed = 460, range = 850, radius = 150, type = "circular", cc = "false"},
    }},                 
}

-- Globals ---------------------------------------------------------------------
enemyes = {}
nAllies = 0
allies = {}
nEnemies = 0
evading             = false
allowCustomMovement = true
captureMovements    = true
lastMovement        = {}
detectedSkillshots  = {}
nSkillshots = 0
CastingSpell = false

-- Code ------------------------------------------------------------------------
function getTarget(targetId)
    if targetId ~= 0 and targetId ~= nil then
        return objManager:GetObjectByNetworkId(targetId)
    end
    return nil
end

function getLastMovementDestination()
    if lastMovement.type == 3 then
        heroPosition = Point(myHero.x, myHero.z)

        target = getTarget(lastMovement.targetId)
        if _isValidTarget(target) then
            targetPosition = Point(target.x, target.z)

            local attackRange = (myHero.range + GetDistance(myHero.minBBox, myHero.maxBBox) / 2 + GetDistance(target.minBBox, target.maxBBox) / 2)

            if attackRange <= heroPosition:distance(targetPosition) then
                return targetPosition + (heroPosition - targetPosition):normalized() * attackRange
            else
                return heroPosition
            end
        else
            return heroPosition
        end
    elseif lastMovement.type == 7 then
        heroPosition = Point(myHero.x, myHero.z)

        target = getTarget(lastMovement.targetId)
        if _isValidTarget(target) then
            targetPosition = Point(target.x, target.z)

            local castRange = myHero:GetSpellData(lastMovement.spellId).range

            if castRange <= heroPosition:distance(targetPosition) then
                return targetPosition + (heroPosition - targetPosition):normalized() * castRange
            else
                return heroPosition
            end
        else
            local castRange = myHero:GetSpellData(lastMovement.spellId).range

            if castRange <= heroPosition:distance(lastMovement.destination) then
                return lastMovement.destination + (heroPosition - lastMovement.destination):normalized() * castRange
            else
                return heroPosition
            end
        end
    else
        return lastMovement.destination
    end
end

function OnLoad()
    stopEvade()

	isVayne = false
	if myHero.charName == "Vayne" then 
	    isVayne = true
	end
	isGraves = false
	if myHero.charName == "Graves" then 
	    isGraves = true
	end
	isEzreal = false
	if myHero.charName == "Ezreal" then 
	    isEzreal = true
	end
	isKassadin = false
	if myHero.charName == "Kassadin" then 
	    isKassadin = true
	end
	isRiven = false
	if myHero.charName == "Riven" then 
	    isRiven = true
	end
	isRenekton = false		    
	if myHero.charName == "Renekton" then 
	    isRenekton = true
	end	
	isTristana = false
	if myHero.charName == "Tristana" then 
	    isTristana = true
	end
	isCorki = false
	if myHero.charName == "Corki" then 
	    isCorki = true
	end
	isLucian = false
	if myHero.charName == "Lucian" then 
	    isLucian = true
	end	

    lastMovement = {
        destination = Point(myHero.x, myHero.z),
        moveCommand = Point(myHero.x, myHero.z),
        type = 2,
        targetId = nil,
        spellId = nil,
        approachedPoint = nil
    }

    PerfectEvadeConfig = scriptConfig("Good Evade", "goodEvade")
    PerfectEvadeConfig:addParam("dodgeEnabled", "Dodge Skillshots", SCRIPT_PARAM_ONOFF, true)
    PerfectEvadeConfig:addParam("drawEnabled", "Draw Skillshots", SCRIPT_PARAM_ONOFF, true)
    PerfectEvadeConfig:addParam("dodgeCConly", "Dodge CC only spells", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    PerfectEvadeConfig:permaShow("dodgeEnabled")

    for i = 1, heroManager.iCount do
        local hero = heroManager:GetHero(i)
        if hero.team ~= myHero.team then
            table.insert(enemyes, hero)
        elseif hero.team == myHero.team and hero.nEnemies ~= myHero.networkID then
            table.insert(allies, hero)
        end
    end

    if #enemyes == 5 then
        for i, skillShotChampion in pairs(champions) do
            if skillShotChampion.charName ~= enemyes[1].charName and skillShotChampion.charName ~= enemyes[2].charName and skillShotChampion.charName ~= enemyes[3].charName
            and skillShotChampion.charName ~= enemyes[4].charName and skillShotChampion.charName ~= enemyes[5].charName then
                champions[i] = nil
            end
        end
    end

    player:RemoveCollision()
    player:SetVisionRadius(1700)

    PerfectEvadeConfig.dodgeEnabled = true

    PrintChat(" >> Good Evade 0.13b loaded")
end

function OnSendPacket(p)
    local packet = Packet(p)
    if packet:get('name') == 'S_MOVE' then
        if packet:get('sourceNetworkId') == myHero.networkID then
            if captureMovements then
                lastMovement.destination = Point(packet:get('x'), packet:get('y'))
                lastMovement.type = packet:get('type')
                lastMovement.targetId = packet:get('targetNetworkId')

                if evading then
                    for i, detectedSkillshot in pairs(detectedSkillshots) do
                        if detectedSkillshot and detectedSkillshot.evading and inDangerousArea(detectedSkillshot, Point(myHero.x, myHero.z)) then
                            dodgeSkillshot(detectedSkillshot)
                            break
                        end
                    end
                end
            end
            if not allowCustomMovement then
                packet:block()
            end           
        end
    elseif packet:get('name') == 'S_CAST' then
        if captureMovements then
            lastMovement.spellId = packet:get('spellId')
            lastMovement.type = 7
            lastMovement.targetId = packet:get('targetNetworkId')
            lastMovement.destination = Point(packet:get('toX'), packet:get('toY'))

            if evading then
                for i, detectedSkillshot in pairs(detectedSkillshots) do
                    if detectedSkillshot and detectedSkillshot.evading and inDangerousArea(detectedSkillshot, Point(myHero.x, myHero.z)) then
                        dodgeSkillshot(detectedSkillshot)
                        break
                    end
                end
            end
        end

        if not allowCustomMovement then
            packet:block()
        end
    end
end

function getSideOfLine(linePoint1, linePoint2, point)
    if not point then return 0 end
    result = ((linePoint2.x - linePoint1.x) * (point.y - linePoint1.y) - (linePoint2.y - linePoint1.y) * (point.x - linePoint1.x))
    if result < 0 then
        return -1
    elseif result > 0 then
        return 1
    else
        return 0
    end
end

function dodgeSkillshot(skillshot)
    if PerfectEvadeConfig.dodgeEnabled and not myHero.dead and (CastingSpell == false or lastMovement.spellId == RECALL) then
        if skillshot.skillshot.type == "line" then
            dodgeLineShot(skillshot)
        else
            dodgeCircularShot(skillshot)
        end
    end
end

function dodgeCircularShot(skillshot)
	smoothing = 0
    skillshot.evading = true

    heroPosition = Point(myHero.x, myHero.z)

    moveableDistance = myHero.ms * math.max(skillshot.endTick - GetTickCount() - GetLatency(), 0) / 1000
    evadeRadius = skillshot.skillshot.radius + hitboxSize / 2 + evadeBuffer + moveBuffer

    safeTarget = skillshot.endPosition + (heroPosition - skillshot.endPosition):normalized() * evadeRadius

    if getLastMovementDestination():distance(skillshot.endPosition) <= evadeRadius then
        closestTarget = skillshot.endPosition + (getLastMovementDestination() - skillshot.endPosition):normalized() * evadeRadius
    else
        closestTarget = nil
    end
        
    lineDistance = Line(heroPosition, getLastMovementDestination()):distance(skillshot.endPosition)
    directionTarget = heroPosition + (getLastMovementDestination() - heroPosition):normalized() * (math.sqrt(heroPosition:distance(skillshot.endPosition)^2 - lineDistance^2) + math.sqrt(evadeRadius^2 - lineDistance^2))
    if directionTarget:distance(skillshot.endPosition) >= evadeRadius + 1 then
        directionTarget = heroPosition + (getLastMovementDestination() - heroPosition):normalized() * (math.sqrt(evadeRadius^2 - lineDistance^2) - math.sqrt(heroPosition:distance(skillshot.endPosition)^2 - lineDistance^2))
    end

    possibleMovementTargets = {}
    intersectionPoints = Circle(skillshot.endPosition, evadeRadius):intersectionPoints(Circle(heroPosition, moveableDistance))
    if #intersectionPoints == 2 then
        leftTarget = intersectionPoints[1]
        rightTarget = intersectionPoints[2]

        local theta = ((-skillshot.endPosition + leftTarget):polar() - (-skillshot.endPosition + rightTarget):polar()) % 360
        if ((theta >= 180 and getSideOfLine(skillshot.endPosition, leftTarget, directionTarget) 
            == getSideOfLine(skillshot.endPosition, leftTarget, heroPosition) 
            and getSideOfLine(skillshot.endPosition, rightTarget, directionTarget) 
            == getSideOfLine(skillshot.endPosition, rightTarget, heroPosition)) 
        or (theta <= 180 and (getSideOfLine(skillshot.endPosition, leftTarget, directionTarget) 
            == getSideOfLine(skillshot.endPosition, leftTarget, heroPosition) 
            or getSideOfLine(skillshot.endPosition, rightTarget, directionTarget) 
            == getSideOfLine(skillshot.endPosition, rightTarget, heroPosition)))) then
            table.insert(possibleMovementTargets, directionTarget)
        end

        if _isValidTarget(closestTarget) and ((theta >= 180 and getSideOfLine(skillshot.endPosition, leftTarget, closestTarget) == getSideOfLine(skillshot.endPosition, leftTarget, heroPosition) and getSideOfLine(skillshot.endPosition, rightTarget, closestTarget) == getSideOfLine(skillshot.endPosition, rightTarget, heroPosition)) or (theta <= 180 and (getSideOfLine(skillshot.endPosition, leftTarget, closestTarget) == getSideOfLine(skillshot.endPosition, leftTarget, heroPosition) or getSideOfLine(skillshot.endPosition, rightTarget, closestTarget) == getSideOfLine(skillshot.endPosition, rightTarget, heroPosition)))) then
            table.insert(possibleMovementTargets, closestTarget)
        end

        table.insert(possibleMovementTargets, safeTarget)
        table.insert(possibleMovementTargets, leftTarget)
        table.insert(possibleMovementTargets, rightTarget)
    else
        if skillshot.skillshot.radius <= moveableDistance then
            table.insert(possibleMovementTargets, closestTarget)
            table.insert(possibleMovementTargets, directionTarget)
            table.insert(possibleMovementTargets, safeTarget)
        end
    end

    closestPoint = findBestDirection(getLastMovementDestination(), possibleMovementTargets)
    if closestPoint ~= nil then
        closestPoint = closestPoint + (closestPoint - heroPosition):normalized() * smoothing
        evadeTo(closestPoint.x, closestPoint.y, skillshot.skillshot.cc == "true")
    elseif NeedDash(skillshot, true) then
        if not evading then
            -- CAN NOT EVADE - STILL TRY IT
            --safeTarget = safeTarget + (safeTarget - heroPosition):normalized() * smoothing
            evadeTo(safeTarget.x, safeTarget.y, true)
        end
    end
end

function dodgeLineShot(skillshot)
    heroPosition = Point(myHero.x, myHero.z)
    
    _setSmoothing(skillshot)

    skillshot.evading = true

    skillshotLine = Line(skillshot.startPosition, skillshot.endPosition)
    distanceFromSkillshotPath = skillshotLine:distance(heroPosition)
    evadeDistance = skillshot.skillshot.radius + hitboxSize / 2 + evadeBuffer + moveBuffer

    normalVector = Point(skillshot.directionVector.y, -skillshot.directionVector.x):normalized()
    nessecaryMoveWidth = evadeDistance - distanceFromSkillshotPath

    evadeTo1 = heroPosition + normalVector * nessecaryMoveWidth
    evadeTo2 = heroPosition - normalVector * nessecaryMoveWidth
    if skillshotLine:distance(evadeTo1) >= skillshotLine:distance(evadeTo2) then
        longitudinalApproachLength = calculateLongitudinalApproachLength(skillshot, nessecaryMoveWidth)
        if longitudinalApproachLength >= 0 then
            evadeToTarget1 = evadeTo1 - skillshot.directionVector * longitudinalApproachLength
        end

        longitudinalApproachLength = calculateLongitudinalApproachLength(skillshot, evadeDistance + distanceFromSkillshotPath)
        if longitudinalApproachLength >= 0 then
            evadeToTarget2 = heroPosition - normalVector * (evadeDistance + distanceFromSkillshotPath) - skillshot.directionVector * longitudinalApproachLength
        end

        longitudinalRetreatLength = calculateLongitudinalRetreatLength(skillshot, nessecaryMoveWidth)
        if longitudinalRetreatLength >= 0 then
            evadeToTarget3 = evadeTo1 + skillshot.directionVector * longitudinalRetreatLength
        end

        longitudinalRetreatLength = calculateLongitudinalRetreatLength(skillshot, evadeDistance + distanceFromSkillshotPath)
        if longitudinalRetreatLength >= 0 then
            evadeToTarget4 = heroPosition - normalVector * (evadeDistance + distanceFromSkillshotPath) + skillshot.directionVector * longitudinalRetreatLength
        end

        safeTarget = evadeTo1

        closestPoint = getLastMovementDestination() + normalVector * (evadeDistance - skillshotLine:distance(getLastMovementDestination()))
        closestPoint2 = getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, getLastMovementDestination()) + normalVector * evadeDistance
    else
        longitudinalApproachLength = calculateLongitudinalApproachLength(skillshot, nessecaryMoveWidth)
        if longitudinalApproachLength >= 0 then
            evadeToTarget1 = evadeTo2 - skillshot.directionVector * longitudinalApproachLength
        end

        longitudinalApproachLength = calculateLongitudinalApproachLength(skillshot, evadeDistance + distanceFromSkillshotPath)
        if longitudinalApproachLength >= 0 then
            evadeToTarget2 = heroPosition + normalVector * (evadeDistance + distanceFromSkillshotPath) - skillshot.directionVector * longitudinalApproachLength
        end

        longitudinalRetreatLength = calculateLongitudinalRetreatLength(skillshot, nessecaryMoveWidth)
        if longitudinalRetreatLength >= 0 then
            evadeToTarget3 = evadeTo2 + skillshot.directionVector * longitudinalRetreatLength
        end

        longitudinalRetreatLength = calculateLongitudinalRetreatLength(skillshot, evadeDistance + distanceFromSkillshotPath)
        if longitudinalRetreatLength >= 0 then
            evadeToTarget4 = heroPosition + normalVector * (evadeDistance + distanceFromSkillshotPath) + skillshot.directionVector * longitudinalRetreatLength
        end

        safeTarget = evadeTo2

        closestPoint = getLastMovementDestination() - normalVector * (evadeDistance - skillshotLine:distance(getLastMovementDestination()))
        closestPoint2 = getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, getLastMovementDestination()) - normalVector * evadeDistance
    end

    if skillshotLine:distance(getLastMovementDestination()) <= evadeDistance then
        directionTarget = findBestDirection(getLastMovementDestination(), {closestPoint, closestPoint2, getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, getLastMovementDestination()) - normalVector * evadeDistance, getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, getLastMovementDestination()) + normalVector * evadeDistance})
    else
        if getSideOfLine(skillshot.startPosition, skillshot.endPosition, getLastMovementDestination()) == getSideOfLine(skillshot.startPosition, skillshot.endPosition, heroPosition) then
            if skillshotLine:distance(heroPosition) <= skillshotLine:distance(getLastMovementDestination()) then
                directionTarget = heroPosition + (getLastMovementDestination()-heroPosition):normalized() * ((evadeDistance - distanceFromSkillshotPath) * heroPosition:distance(getLastMovementDestination())) / (skillshotLine:distance(getLastMovementDestination()) - distanceFromSkillshotPath)
            else
                directionTarget = heroPosition + (getLastMovementDestination()-heroPosition):normalized() * ((evadeDistance + distanceFromSkillshotPath) * heroPosition:distance(getLastMovementDestination())) / (distanceFromSkillshotPath - skillshotLine:distance(getLastMovementDestination()))
            end
        else
            directionTarget = heroPosition + (getLastMovementDestination() - heroPosition):normalized() * (evadeDistance + distanceFromSkillshotPath) * heroPosition:distance(getLastMovementDestination()) / (skillshotLine:distance(getLastMovementDestination()) + distanceFromSkillshotPath)
        end
    end

    evadeTarget = nil
    --[[if (evadeToTarget1 ~= nil and evadeToTarget3 ~= nil and Line(evadeToTarget1, evadeToTarget3):distance(directionTarget) <= 1 and getSideOfLine(evadeToTarget1, getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, evadeToTarget1), directionTarget) ~= getSideOfLine(evadeToTarget3, getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, evadeToTarget3), directionTarget)) or (evadeToTarget2 ~= nil and evadeToTarget4 ~= nil and Line(evadeToTarget2, evadeToTarget4):distance(directionTarget) <= 1 and getSideOfLine(evadeToTarget2, getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, evadeToTarget2), directionTarget) ~= getSideOfLine(evadeToTarget4, getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, evadeToTarget4), directionTarget)) or (evadeToTarget1 ~= nil and evadeToTarget3 == nil and getSideOfLine(heroPosition, evadeToTarget1, skillshot.startPosition) ~= getSideOfLine(heroPosition, evadeToTarget1, directionTarget)) or (evadeToTarget2 ~= nil and evadeToTarget4 == nil and getSideOfLine(heroPosition, evadeToTarget2, skillshot.startPosition) ~= getSideOfLine(heroPosition, evadeToTarget2, directionTarget)) then
        evadeTarget = directionTarget
    else]]
        possibleMovementTargets = {}

    if (evadeToTarget1 ~= nil and evadeToTarget3 ~= nil and Line(evadeToTarget1, evadeToTarget3):distance(closestPoint2) <= 1 and getSideOfLine(evadeToTarget1, getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, evadeToTarget1), closestPoint2) ~= getSideOfLine(evadeToTarget3, getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, evadeToTarget3), closestPoint2)) or (evadeToTarget2 ~= nil and evadeToTarget4 ~= nil and Line(evadeToTarget2, evadeToTarget4):distance(closestPoint2) <= 1 and getSideOfLine(evadeToTarget2, getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, evadeToTarget2), closestPoint2) ~= getSideOfLine(evadeToTarget4, getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, evadeToTarget4), closestPoint2)) or (evadeToTarget1 ~= nil and evadeToTarget3 == nil and getSideOfLine(heroPosition, evadeToTarget1, skillshot.startPosition) ~= getSideOfLine(heroPosition, evadeToTarget1, closestPoint2)) or (evadeToTarget2 ~= nil and evadeToTarget4 == nil and getSideOfLine(heroPosition, evadeToTarget2, skillshot.startPosition) ~= getSideOfLine(heroPosition, evadeToTarget2, closestPoint2)) then
        table.insert(possibleMovementTargets, closestPoint2)
    end

    if evadeToTarget1 ~= nil then
        table.insert(possibleMovementTargets, evadeToTarget1)
    end

    if evadeToTarget2 ~= nil then
        --table.insert(possibleMovementTargets, evadeToTarget2)
    end

    if evadeToTarget3 ~= nil then
        table.insert(possibleMovementTargets, evadeToTarget3)
    end

    if evadeToTarget4 ~= nil then
        --table.insert(possibleMovementTargets, evadeToTarget4)
    end

    evadeTarget = findBestDirection(getLastMovementDestination(), possibleMovementTargets)
    --end

    -- try to evade until spellshields are implemented -- TEMPORARY OVERRIDE !!!
    if evadeTarget == nil then
        --evadeTarget = safeTarget
    end

    if _isValidTarget(evadeTarget) then
        if getSideOfLine(skillshot.startPosition, skillshot.endPosition, evadeTarget) == getSideOfLine(skillshot.startPosition, skillshot.endPosition, getLastMovementDestination()) and skillshotLine:distance(getLastMovementDestination()) > evadeDistance then
            pathDirectionVector = (evadeTarget - heroPosition)
            if getSideOfLine(skillshot.startPosition, skillshot.endPosition, heroPosition) == getSideOfLine(skillshot.startPosition, skillshot.endPosition, evadeTarget) then
                evadeTarget = evadeTarget + pathDirectionVector:normalized() * (pathDirectionVector:len() + smoothing / (evadeDistance - distanceFromSkillshotPath) * pathDirectionVector:len())
            else
                evadeTarget = evadeTarget + pathDirectionVector:normalized() * (pathDirectionVector:len() + smoothing / (evadeDistance + distanceFromSkillshotPath) * pathDirectionVector:len())
            end
        end
        evadeTo(evadeTarget.x, evadeTarget.y, NeedDash(skillshot, false))
    elseif NeedDash(skillshot, true) then
        -- USE SPELLSHIELDS AND ABILITES TO EVADE
        evadeTo(safeTarget.x, safeTarget.y, true)
    end
end

function _setSmoothing(skillshot)
    heroPosition = Point(myHero.x, myHero.z)
    local m1 = heroPosition:distance(skillshot.startPosition)
    local m2 = skillshot.endPosition:distance(skillshot.startPosition)
    smoothing = m1 / m2 * 100
    smoothing = math.max(smoothing, 0)
    smoothing = math.min(smoothing, 100)
    if _isDangerSkillshot(skillshot) then
    	smoothing = 0
    end
    if not isVayne and not isRiven and not isCorki and not isGraves and not isLucian
        and not isRenekton and not isEzreal and not isTristana and not isKassadin then
        smoothing = 0
    end 
end
function _isDangerSkillshot(skillshot)
	if skillshot.skillshot.name == "LeonaZenithBlade" 
		or skillshot.skillshot.name == "EnchantedArrow" 
		or skillshot.skillshot.name == "RocketGrab" then
		return true
	else
		return false
	end	
end

function InsideTheWall(evadeTestPoint)
    local heroPosition = Point(myHero.x, myHero.z)
    local dist = evadeTestPoint:distance(heroPosition)
    local interval = 50
    local nChecks = math.ceil((dist+50)/50)

    if evadeTestPoint.x == 0 or evadeTestPoint.y == 0 then
        return true
    end 
    for k=1, nChecks, 1 do
        local checksPos = evadeTestPoint + (evadeTestPoint - heroPosition):normalized()*(interval*k)
        if IsWall(D3DXVECTOR3(checksPos.x, myHero.y, checksPos.y)) then
            return true
        end
    end
    if IsWall(D3DXVECTOR3(evadeTestPoint.x + 20, myHero.y, evadeTestPoint.y + 20)) then return true end
    if IsWall(D3DXVECTOR3(evadeTestPoint.x + 20, myHero.y, evadeTestPoint.y - 20)) then return true end
    if IsWall(D3DXVECTOR3(evadeTestPoint.x - 20, myHero.y, evadeTestPoint.y - 20)) then return true end
    if IsWall(D3DXVECTOR3(evadeTestPoint.x - 20, myHero.y, evadeTestPoint.y + 20)) then return true end

    return false
end

function GetCollision(evadeTestPoint)
    local collizionPos = {x = evadeTestPoint.x, y = myHero.y, z = evadeTestPoint.y}
    return collizion:GetMinionCollision(myHero, collizionPos)
end

--[[function findBestDirectionOld(referencePoint, possiblePoints) --old
    closestPoint = nil
    closestDistance = nil
    for i, point in pairs(possiblePoints) do
        if point ~= nil then
            distance = point:distance(referencePoint)
            if (closestDistance == nil or distance <= closestDistance) and not InsideTheWall(point) then
                closestDistance = distance
                closestPoint = point
            end
        end
    end
    
    return closestPoint
end]]

function findBestDirection(referencePoint, possiblePoints)
    local closestPoint = nil
    local closestDistance = nil

    local TurretsPE = TurretsPE.GetObjects(ENEMY, 1500, myHero)
    local turret = nil
    if #TurretsPE >= 1 then turret = Point(TurretsPE[1].x, TurretsPE[1].z) end
    local enemy = nil
    if #enemyes >= 1 then enemy = Point(enemyes[1].x, enemyes[1].z) end

    for i, point in pairs(possiblePoints) do
        if point ~= nil then
            distance = point:distance(referencePoint)
            if (closestDistance == nil or distance <= closestDistance) and not InsideTheWall(point)
            and (not turret or (turret and point:distance(turret) > 800)) then
                closestDistance = distance
                closestPoint = point
            end
        end
    end     

    if not closestPoint and turret then
        for i, point in pairs(possiblePoints) do
            if point ~= nil then
                distance = point:distance(referencePoint)
                if (closestDistance == nil or distance <= closestDistance) and not InsideTheWall(point) then
                    closestDistance = distance
                    closestPoint = point
                end
            end
        end -- dodging under turret too
    end

    return closestPoint
end

function calculateLongitudinalApproachLength(skillshot, d)
    v1 = skillshot.skillshot.projectileSpeed
    v2 = myHero.ms
    longitudinalDistance = math.max(skillshotPosition(skillshot, GetTickCount()):distance(getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, Point(myHero.x, myHero.z))) - hitboxSize / 2 - skillshot.skillshot.radius, 0)  + v1 * math.max(skillshot.startTick - GetTickCount(), 0) / 1000

    preResult = -d^2 * v1^4 + d^2 * v2^2 * v1^2 + longitudinalDistance^2 * v2^2 * v1^2
    if preResult >= 0 then
        result = (math.sqrt(preResult) - longitudinalDistance * v2^2) / (v1^2 - v2^2)
        if result >= 0 then
            return result
        end
    end

    return -1
end

function calculateLongitudinalRetreatLength(skillshot, d)
    v1 = skillshot.skillshot.projectileSpeed
    v2 = myHero.ms
    longitudinalDistance = math.max(skillshotPosition(skillshot, GetTickCount()):distance(getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, Point(myHero.x, myHero.z))) - hitboxSize / 2 - skillshot.skillshot.radius, 0) + v1 * math.max(skillshot.startTick - GetTickCount(), 0) / 1000

    preResult = -d^2 * v1^4 + d^2 * v2^2 * v1^2 + longitudinalDistance^2 * v2^2 * v1^2
    if preResult >= 0 then
        result = (math.sqrt(preResult) + longitudinalDistance * v2^2) / (v1^2 - v2^2)
        if result >= 0 then
            return result
        end
    end

    return -1
end

function inDangerousArea(skillshot, coordinate)
    if skillshot.skillshot.type == "line" then
        return inRange(skillshot, coordinate) 
        and not skillshotHasPassed(skillshot, coordinate) 
        and Line(skillshot.startPosition, skillshot.endPosition):distance(coordinate) < (skillshot.skillshot.radius + hitboxSize / 2 + evadeBuffer) 
        and coordinate:distance(skillshot.startPosition + skillshot.directionVector) <= coordinate:distance(skillshot.startPosition - skillshot.directionVector)
    else
        return coordinate:distance(skillshot.endPosition) <= skillshot.skillshot.radius + hitboxSize / 2 + evadeBuffer
    end
end

function inRange(skillshot, coordinate)
    return getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, coordinate):distance(skillshot.startPosition) <= skillshot.skillshot.range
end

function OnCreateObj(object)
    if object ~= nil and object.type == "obj_GeneralParticleEmmiter" then
        --if not object.name:lower():find("odin") and not object.name:lower():find("drawfx") then print(object.name) end
        for i, skillShotChampion in pairs(champions) do
            for i, skillshot in pairs(skillShotChampion.skillshots) do
                if skillshot.projectileName == object.name then
                    for i, detectedSkillshot in pairs(detectedSkillshots) do
                        if detectedSkillshot.skillshot.projectileName == skillshot.projectileName then
                            return
                        end
                    end

                    for i = 1, heroManager.iCount, 1 do
                        currentHero = heroManager:GetHero(i)
                        if currentHero.team == myHero.team and skillShotChampion.charName == currentHero.charName then
                            return
                        end
                    end

                    startPosition = Point(object.x, object.z)
                    if skillshot.cc == "true" or (nEnemies <= 2 and not PerfectEvadeConfig.dodgeCConly) then
                        if skillshot.type == "line" then
                            skillshotToAdd = {object = object, startPosition = startPosition, endPosition = nil, directionVector = nil, 
                            startTick = GetTickCount(), endTick = GetTickCount() + skillshot.range/skillshot.projectileSpeed*1000, 
                            skillshot = skillshot, evading = false}
                        else
                            endPosition = Point(object.x, object.z)
                            table.insert(detectedSkillshots, {startPosition = startPosition, endPosition = endPosition, 
                            directionVector = (endPosition - startPosition):normalized(), startTick = GetTickCount() + skillshot.spellDelay, 
                            endTick = GetTickCount() + skillshot.spellDelay + skillshot.projectileSpeed, skillshot = skillshot, evading = false})
                        end
                    end
                    return
                end
            end
        end
    end
end

function OnAnimation(unit, animationName)
	if unit.isMe and (animationName == "Idle1" or animationName == "Run") then CastingSpell = false end
end

function OnProcessSpell(unit, spell)
	--For detect start of channeled spells
	 if unit.isMe and myHero.charName == "MasterYi" and spell.name == GetSpellData(_W).name then
	  CastingSpell = true
	 elseif unit.isMe and myHero.charName == "Nunu" and spell.name == GetSpellData(_R).name then
	  CastingSpell = true
	 elseif unit.isMe and myHero.charName == "MissFortune" and spell.name == GetSpellData(_R).name then
	  CastingSpell = true
	 elseif unit.isMe and myHero.charName == "Malzahar" and spell.name == GetSpellData(_R).name then
	  CastingSpell = true
	 elseif unit.isMe and myHero.charName == "Katarina" and spell.name == GetSpellData(_R).name then
	  CastingSpell = true
	 elseif unit.isMe and myHero.charName == "Janna" and spell.name == GetSpellData(_R).name then
	  CastingSpell = true
	 elseif unit.isMe and myHero.charName == "Galio" and spell.name == GetSpellData(_R).name then
	  CastingSpell = true
	 elseif unit.isMe and myHero.charName == "FiddleSticks" and spell.name == GetSpellData(_W).name then
	  CastingSpell = true
	 end

    if lastMovement.type == 7 and myHero.team == unit.team and unit.name == myHero.name then
        lastMovement.type = 3
    end
    --print(spell.name)
    if not myHero.dead and unit.team ~= myHero.team then
        for i, skillShotChampion in pairs(champions) do
            if skillShotChampion.charName == unit.charName then
                for i, skillshot in pairs(skillShotChampion.skillshots) do
                    if skillshot.spellName == spell.name then
                        startPosition = Point(unit.x, unit.z)
                        endPosition = Point(spell.endPos.x, spell.endPos.z)
                        directionVector = (endPosition - startPosition):normalized()
                        if skillshot.cc == "true" or (nEnemies <= 2 and not PerfectEvadeConfig.dodgeCConly) then
                            if skillshot.type == "line" then
                                table.insert(detectedSkillshots, {startPosition = startPosition, endPosition = startPosition + directionVector * skillshot.range,
                                directionVector = directionVector, startTick = GetTickCount() + skillshot.spellDelay, 
                                endTick = GetTickCount() + skillshot.spellDelay + skillshot.range/skillshot.projectileSpeed*1000, skillshot = skillshot, evading = false})
                            else
                                table.insert(detectedSkillshots, {startPosition = startPosition, endPosition = endPosition, 
                                directionVector = directionVector, startTick = GetTickCount() + skillshot.spellDelay, 
                                endTick = GetTickCount() + skillshot.spellDelay + skillshot.projectileSpeed, skillshot = skillshot, evading = false})
                            end
                        end
                        return
                    end
                end
            end
        end
    end
end

function skillshotPosition(skillshot, tickCount)
    if skillshot.skillshot.type == "line" then
        return skillshot.startPosition + skillshot.directionVector * math.max(tickCount - skillshot.startTick, 0) * skillshot.skillshot.projectileSpeed / 1000
    else
        return skillshot.endPosition
    end
end

function skillshotHasPassed(skillshot, coordinate)
    footOfPerpendicular = getPerpendicularFootpoint(skillshot.startPosition, skillshot.endPosition, coordinate)
    currentSkillshotPosition = skillshotPosition(skillshot, GetTickCount() - 2 * GetLatency())

    return (getSideOfLine(coordinate, footOfPerpendicular, currentSkillshotPosition) ~= getSideOfLine(coordinate, footOfPerpendicular, skillshot.startPosition)) and currentSkillshotPosition:distance(footOfPerpendicular) >= ((skillshot.skillshot.radius + hitboxSize / 2))
end

function getPerpendicularFootpoint(linePoint1, linePoint2, point)
    distanceFromLine = Line(linePoint1, linePoint2):distance(point)
    directionVector = (linePoint2 - linePoint1):normalized()

    footOfPerpendicular = point + Point(-directionVector.y, directionVector.x) * distanceFromLine
    if Line(linePoint1, linePoint2):distance(footOfPerpendicular) > distanceFromLine then
        footOfPerpendicular = point - Point(-directionVector.y, directionVector.x) * distanceFromLine
    end

    return footOfPerpendicular
end

function OnTick()
	nSkillshots = 0
	for _, detectedSkillshot in pairs(detectedSkillshots) do
		if detectedSkillshot then nSkillshots = nSkillshots + 1 end
	end

    if not allowCustomMovement and nSkillshots == 0 then
        stopEvade()
    end

    hitboxSize = GetDistance(myHero.minBBox, myHero.maxBBox)

    nEnemies = CountEnemyHeroInRange(1500)
    table.sort(enemyes, function(x,y) return GetDistance(x) < GetDistance(y) end)

    if skillshotToAdd ~= nil and skillshotToAdd.object ~= nil and skillshotToAdd.object.valid and (GetTickCount() - skillshotToAdd.startTick) >= GetLatency() then
        skillshotToAdd.directionVector = (Point(skillshotToAdd.object.x, skillshotToAdd.object.z) - skillshotToAdd.startPosition):normalized()
        skillshotToAdd.endPosition = skillshotToAdd.startPosition + skillshotToAdd.directionVector * skillshotToAdd.skillshot.range

        table.insert(detectedSkillshots, skillshotToAdd)

        skillshotToAdd = nil
    end

    heroPosition = Point(myHero.x, myHero.z)
    for i, detectedSkillshot in ipairs(detectedSkillshots) do
        if detectedSkillshot.endTick <= GetTickCount() then
            table.remove(detectedSkillshots, i)
            i = i-1
            if detectedSkillshot.evading then
                continueMovement(detectedSkillshot)
            end
        else
            if evading then
                if detectedSkillshot.evading and not inDangerousArea(detectedSkillshot, heroPosition) then
                    if detectedSkillshot.skillshot.type == "line" then
                        -- SKILLSHOT PASSED
                        if skillshotHasPassed(detectedSkillshot, heroPosition) then
                            continueMovement(detectedSkillshot)

                        -- DESTINATION SAFE
                        elseif not inDangerousArea(detectedSkillshot, getLastMovementDestination()) and (getSideOfLine(detectedSkillshot.startPosition, detectedSkillshot.endPosition, heroPosition) == getSideOfLine(detectedSkillshot.startPosition, detectedSkillshot.endPosition, getLastMovementDestination())) then
                            continueMovement(detectedSkillshot)

                        -- OUT OF RANGE
                        elseif not inRange(detectedSkillshot, heroPosition) and not inRange(detectedSkillshot, getLastMovementDestination()) then
                            continueMovement(detectedSkillshot)

                        -- APPROACH TARGET
                        else
                            if lastMovement.approachedPoint ~= getLastMovementDestination() then
                                footpoint = getPerpendicularFootpoint(detectedSkillshot.startPosition, detectedSkillshot.endPosition, getLastMovementDestination())
                                closestSafePoint = footpoint + Point(-detectedSkillshot.directionVector.y, detectedSkillshot.directionVector.x) * (detectedSkillshot.skillshot.radius + hitboxSize / 2 + evadeBuffer + moveBuffer)
                                if (getSideOfLine(detectedSkillshot.startPosition, detectedSkillshot.endPosition, heroPosition) ~= getSideOfLine(detectedSkillshot.startPosition, detectedSkillshot.endPosition, closestSafePoint)) then
                                    closestSafePoint = footpoint - Point(-detectedSkillshot.directionVector.y, detectedSkillshot.directionVector.x) * (detectedSkillshot.skillshot.radius + hitboxSize / 2 + evadeBuffer + moveBuffer)
                                end

                                captureMovements = false
                                allowCustomMovement = true
                                if detectedSkillshot.skillshot.cc == "true" and (nSkillshots > 1 or GetCollision(closestPoint)) then DashTo(x, y) end
                                myHero:MoveTo(closestSafePoint.x, closestSafePoint.y)
                                lastMovement.moveCommand = Point(closestSafePoint.x, closestSafePoint.y)
                                allowCustomMovement = false
                                captureMovements = true

                                lastMovement.approachedPoint = getLastMovementDestination()
                            end
                        end
                    else
                        evadeRadius = detectedSkillshot.skillshot.radius + hitboxSize / 2 + evadeBuffer + moveBuffer
                        directionVector = (heroPosition - detectedSkillshot.endPosition):normalized()
                        tangentDirectionVector = Point(-directionVector.y, directionVector.x)
                        movementTargetSideOfLine = getSideOfLine(heroPosition, heroPosition + tangentDirectionVector, getLastMovementDestination())
                        skillshotSideOfLine = getSideOfLine(heroPosition, heroPosition + tangentDirectionVector, detectedSkillshot.endPosition)
                        
                        -- DESTINATION SAFE
                        if movementTargetSideOfLine == 0 or movementTargetSideOfLine ~= skillshotSideOfLine then
                            continueMovement(detectedSkillshot)
                        else
                            if getLastMovementDestination():distance(detectedSkillshot.endPosition) <= evadeRadius then
                                closestTarget = detectedSkillshot.endPosition + (getLastMovementDestination() - detectedSkillshot.endPosition):normalized() * evadeRadius
                            else
                                closestTarget = nil
                            end

                            dx = detectedSkillshot.endPosition.x - heroPosition.x
                            dy = detectedSkillshot.endPosition.y - heroPosition.y
                            D_squared = dx * dx + dy * dy
                            if D_squared < evadeRadius * evadeRadius then
                                safePoint1 = heroPosition - tangentDirectionVector * (evadeRadius / 2 + smoothing)
                                safePoint2 = heroPosition + tangentDirectionVector * (evadeRadius / 2 + smoothing)
                            else
                                intersectionPoints = Circle(detectedSkillshot.endPosition, evadeRadius):intersectionPoints(Circle(heroPosition, math.sqrt(D_squared - evadeRadius * evadeRadius)))
                                if #intersectionPoints == 2 then
                                    safePoint1 = heroPosition - (heroPosition - intersectionPoints[1]):normalized() * (evadeRadius / 2 + smoothing)
                                    safePoint2 = heroPosition - (heroPosition - intersectionPoints[2]):normalized() * (evadeRadius / 2 + smoothing)
                                else
                                    safePoint1 = heroPosition - tangentDirectionVector * (evadeRadius / 2 + smoothing)
                                    safePoint2 = heroPosition + tangentDirectionVector * (evadeRadius / 2 + smoothing)
                                end
                            end

                            local theta = ((-detectedSkillshot.endPosition + safePoint2):polar() - (-detectedSkillshot.endPosition + safePoint1):polar()) % 360
                            if _isValidTarget(closestTarget) and (
                                (
                                    theta < 180 and (
                                        getSideOfLine(detectedSkillshot.endPosition, safePoint2, closestTarget) == getSideOfLine(detectedSkillshot.endPosition, safePoint2, heroPosition) and
                                        getSideOfLine(detectedSkillshot.endPosition, safePoint1, closestTarget) == getSideOfLine(detectedSkillshot.endPosition, safePoint1, heroPosition)
                                    )
                                ) or (
                                    theta > 180 and (
                                        getSideOfLine(detectedSkillshot.endPosition, safePoint2, closestTarget) == getSideOfLine(detectedSkillshot.endPosition, safePoint2, heroPosition) or
                                        getSideOfLine(detectedSkillshot.endPosition, safePoint1, closestTarget) == getSideOfLine(detectedSkillshot.endPosition, safePoint1, heroPosition)
                                    )
                                )
                            ) then
                                possibleMovementTargets = {closestTarget, safePoint1, safePoint2}
                            else
                                possibleMovementTargets = {safePoint1, safePoint2}
                            end

                            closestPoint = findBestDirection(getLastMovementDestination(), possibleMovementTargets)
                            if closestPoint ~= nil then
                                captureMovements = false
                                allowCustomMovement = true
                                if detectedSkillshot.skillshot.cc == "true" and (nSkillshots > 1 or GetCollision(closestPoint)) then DashTo(x, y) end
                                myHero:MoveTo(closestPoint.x, closestPoint.y)
                                lastMovement.moveCommand = Point(closestPoint.x, closestPoint.y)
                                allowCustomMovement = false
                                captureMovements = true
                            end
                        end
                    end
                end
            elseif inDangerousArea(detectedSkillshot, heroPosition) then
                dodgeSkillshot(detectedSkillshot)
            end
        end
    end
end

function DashTo(x, y)
    if isVayne and  myHero:CanUseSpell(_Q) == READY then
        CastSpell(_Q, x, y)
    end
    if isRiven and  myHero:CanUseSpell(_E) == READY then
        CastSpell(_E, x, y)
    end
    if isGraves and myHero:CanUseSpell(_E) == READY then
        CastSpell(_E, x, y)
    end
    if isEzreal and myHero:CanUseSpell(_E) == READY then
        CastSpell(_E, x, y)
    end
    if isKassadin and myHero:CanUseSpell(_R) == READY then
        CastSpell(_R, x, y)
    end
    if isCorki and myHero:CanUseSpell(_W) == READY then
        CastSpell(_W, x, y)
    end 
    if isRenekton and myHero:CanUseSpell(_E) == READY then
        CastSpell(_E, x, y)
    end 
    if isTristana and myHero:CanUseSpell(_W) == READY then
        CastSpell(_W, x, y)
    end
    if isLucian and myHero:CanUseSpell(_E) == READY then
        CastSpell(_E, x, y)
    end                              
end
function NeedDash(skillshot, forceDash)
	local hp = myHero.health / myHero.maxHealth
    if isVayne and myHero:CanUseSpell(_Q) == READY and skillshot.skillshot.cc == "true" then
		if forceDash or hp < 0.4 then return true end
		if GetCollision(evadeTarget) or nSkillshots > 1 or _isDangerSkillshot(skillshot) then return true end
	end
	if isRiven and myHero:CanUseSpell(_E) == READY and skillshot.skillshot.cc == "true" then
		if forceDash or hp < 0.4 then return true end
		if GetCollision(evadeTarget) or nSkillshots > 1 or _isDangerSkillshot(skillshot) then return true end
	end
	if isGraves and myHero:CanUseSpell(_E) == READY and skillshot.skillshot.cc == "true" then
		if forceDash or hp < 0.4 then return true end
		if _isDangerSkillshot(skillshot) then return true end
	end
	if isEzreal and myHero:CanUseSpell(_E) == READY and skillshot.skillshot.cc == "true" then
		if forceDash or hp < 0.4 then return true end
		if _isDangerSkillshot(skillshot) then return true end
	end
	if isKassadin and myHero:CanUseSpell(_R) == READY and skillshot.skillshot.cc == "true" then
		if forceDash or hp < 0.4 then return true end
		if _isDangerSkillshot(skillshot) then return true end
	end
	if isRenekton and myHero:CanUseSpell(_E) == READY and skillshot.skillshot.cc == "true" then
		if forceDash or hp < 0.4 then return true end
		if _isDangerSkillshot(skillshot) then return true end
	end
	if isTristana and myHero:CanUseSpell(_W) == READY and skillshot.skillshot.cc == "true" then
		if _isDangerSkillshot(skillshot) then return true end
	end
	if isCorki and myHero:CanUseSpell(_W) == READY and skillshot.skillshot.cc == "true" then
		if _isDangerSkillshot(skillshot) then return true end
	end
	if isLucian and myHero:CanUseSpell(_E) == READY and skillshot.skillshot.cc == "true" then
		if forceDash or hp < 0.4 then return true end
		if _isDangerSkillshot(skillshot) then return true end
	end										
	return false
end

function evadeTo(x, y, forceDash)
    startEvade()
    evadePoint = Point(x, y)
    allowCustomMovement = true
    captureMovements = false
    if forceDash then DashTo(x, y) end    
    myHero:MoveTo(x, y)
    lastMovement.moveCommand = Point(x, y)
    captureMovements = true
    allowCustomMovement = false
    evading = true
    evadingTick = GetTickCount()
end

function continueMovement(skillshot)
    if evading then
        skillshot.evading = false
        lastMovement.approachedPoint = nil
        
        stopEvade()
        
        if lastMovement.type == 2 then
            captureMovements = false
            myHero:MoveTo(getLastMovementDestination().x, getLastMovementDestination().y)
            captureMovements = true
        elseif lastMovement.type == 3 then
            target = getTarget(lastMovement.targetId)

            if _isValidTarget(target) then
                captureMovements = false
                myHero:Attack(target)
                captureMovements = true
            else
                captureMovements = false
                myHero:MoveTo(myHero.x, myHero.z)
                captureMovements = true
            end
        elseif lastMovement.type == 10 then
            myHero:HoldPosition()
        elseif lastMovement.type == 7 then
            --[[if myHero.userdataObject ~= nil and myHero.userdataObject:CanUseSpell(lastMovement.spellId) then
                target = getTarget(lastMovement.targetId)
                if _isValidTarget(target) then
                    CastSpell(lastMovement.spellId, target)
                else
                    CastSpell(lastMovement.spellId, lastMovement.destination.x, lastMovement.destination.y)
                end
            end]]
            lastMovement.type = 3
        end
    end
end

function OnDraw()
    --[[if PerfectEvadeConfig.drawEnabled then
        for i, detectedSkillshot in pairs(detectedSkillshots) do
            skillshotPos = skillshotPosition(detectedSkillshot, GetTickCount())

            if detectedSkillshot.skillshot.type == "line" then
                directionVector = detectedSkillshot.endPosition - detectedSkillshot.startPosition
                DrawArrow(D3DXVECTOR3(detectedSkillshot.startPosition.x, myHero.y, detectedSkillshot.startPosition.y), D3DXVECTOR3(directionVector.x, myHero.y, directionVector.y), detectedSkillshot.startPosition:distance(detectedSkillshot.endPosition) + 170, detectedSkillshot.skillshot.radius, -10000000000000000000000, RGBA(255,255,255,0))

                --DrawCircle(skillshotPos.x, myHero.y, skillshotPos.y, detectedSkillshot.skillshot.radius + 10, 0x00FF00)
                --DrawCircle(skillshotPos.x, myHero.y, skillshotPos.y, detectedSkillshot.skillshot.radius, 0xFFFFFF)
                --DrawCircle(skillshotPos.x, myHero.y, skillshotPos.y, detectedSkillshot.skillshot.radius - 10, 0xFFFFFF)
                --DrawCircle(skillshotPos.x, myHero.y, skillshotPos.y, detectedSkillshot.skillshot.radius - 20, 0xFFFFFF)
                --DrawCircle(skillshotPos.x, myHero.y, skillshotPos.y, detectedSkillshot.skillshot.radius - 30, 0xFFFFFF)
            else
                DrawCircle(skillshotPos.x, myHero.y, skillshotPos.y, detectedSkillshot.skillshot.radius, 0x00FF00)
            end
        end
    end]]
end

function _isValidTarget(target)
    return target ~= nil and not target.dead
end

function startEvade()
    allowCustomMovement = false
    if AutoCarry then
        AutoCarry.CanAttack = false
        AutoCarry.CanMove = false
    end
    _G.evade = true
    evading = true  
end

function stopEvade()
	--detectedSkillshots = {}
	allowCustomMovement = true
    if AutoCarry then
        AutoCarry.CanAttack = true
        AutoCarry.CanMove = true
    end
    _G.evade = false
    evading = false
end

function OnWndMsg(msg, key) -- move with Ctrl
    if key == 17 then
        if msg == KEY_DOWN then
            stopEvade()
		end
    end
end