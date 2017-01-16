--[[
	Tick Limiter and Test Case by Kain
--]]

-- Tick Limiter Vars
local tickFrequency = 1
local Priority = { High = 1, Medium = 2, Low = 3 }

-- Test Vars
local drawCount = 0
local test1Count = 0
local test2Count = 0

local lastTick = 0
local lastDrawCount = 0
local lastTest1Count = 0
local lastTest2Count = 0
local stutterLag = false

local debugMode = true

function OnLoad()
    TickLimiterConfig = scriptConfig("Tick Limiter", "Tick Limiter")
	TickLimiterConfig:addParam("FPSMin", "Minimum Allowed FPS", SCRIPT_PARAM_SLICE, 30, 1, 200, 0)
	TickLimiterConfig:addParam("FPSTarget", "Desired Target FPS", SCRIPT_PARAM_SLICE, 50, 1, 200, 0)
	TickLimiterConfig:addParam("InsertLag", "Test: Insert Lag Amount", SCRIPT_PARAM_SLICE, 0, 0, 1000, 0)
	TickLimiterConfig:addParam("InsertStutter", "Test: Insert Stutter Lag", SCRIPT_PARAM_ONOFF, true)
	

    PrintChat(">> Tick Limiter <<")
end

function OnTick()
	InsertLag()
	if not IsTickReady(Priority.Low) then return false end
end

function OnDraw()
	if not IsTickReady(Priority.High) then return false end

	drawCount = drawCount + 1

	-- Do draw stuff here.

	DrawCircle(myHero.x, myHero.y, myHero.z, 100, 0x0099CC) -- Blue
	DrawCircle(myHero.x, myHero.y, myHero.z, 200, 0xFFFF00) -- Yellow
	DrawCircle(myHero.x, myHero.y, myHero.z, 300, 0x00FF00) -- Green
	DrawCircle(myHero.x, myHero.y, myHero.z, 400, 0xFF0000) -- Red
end

function InsertLag()
	if TickLimiterConfig.InsertLag == 0 and not TickLimiterConfig.InsertStutter then return end

	if TickLimiterConfig.InsertStutter then
		if GetTickCount() - lastTick > 500 then
			stutterLag = not stutterLag
		end
	end

	if (not TickLimiterConfig.InsertStutter or TickLimiterConfig.InsertStutter and stutterLag) then
		local j
		for i = 1, TickLimiterConfig.InsertLag * math.random(1000), 1 do
			-- Waste time
			j = GetTickCount() * 1000
		end
	end
end

function TickReport()
	local tick = GetTickCount()
	if math.fmod(tick, 100) == 0 then
		local diffTicks = tick - lastTick
		local diffDraws = drawCount - lastDrawCount
		local ticksPerDraw = math.ceil(diffTicks / diffDraws)
	
		if diffTicks ~= 0 and diffDraws ~= 0 and diffTicks >= diffDraws and lastTick ~= 0 then 
			PrintChat("Tick Report: FPS="..GetFPS()..", TickFrequency="..tickFrequency..", TicksPerDraw="..ticksPerDraw)
		end
		lastTick = tick
		lastDrawCount = drawCount
	end
end

function IsTickReady(priority)
	-- Tick Limiter: Improves FPS. Kain was here.

	-- Thresholds
	local maxTickFrequency = 150 -- Represents the max. ticks at which a high priority task will run.
	local tickChange = 5

	-- local clock = math.ceil(os.clock() * 1000)
	local tick = GetTickCount()
	local fps = GetFPS()

	if not priority then priority = Priority.Low end

	if (fps < TickLimiterConfig.FPSMin) and (tickFrequency <= maxTickFrequency) then
		tickFrequency = tickFrequency + tickChange
	elseif (fps >= TickLimiterConfig.FPSTarget) and (tickFrequency > tickChange) then
		tickFrequency = tickFrequency - tickChange
	end

	-- PrintChat(""..tick.."!"..(tickFrequency * priority).."! "..tickFrequency)
	if debugMode then TickReport() end

	if math.fmod(tick, (tickFrequency * priority) ) == 0 then
		return true
	else
		return false
	end
end

--UPDATEURL=
--HASH=E8CFEADA9C41C85A4DBBFC0129335533
