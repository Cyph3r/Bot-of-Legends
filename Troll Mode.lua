--[[
Troll Mode
by Kain
Copyright 2013

Download: https://bitbucket.org/KainBoL/bol/raw/master/Troll%20Mode.lua

        \|||/       
         (o o)       
,----ooO--(_)-------.
| Please            |
|   don't feed the  |
|     TROLL's !     |
'--------------Ooo--'
        |__|__|      
         || ||       
        ooO Ooo   

--]]

if myHero == nil then myHero = GetMyHero() end

local version = "1.1"

local InsultPhrases = {
	-- Add new insults below.
	"All your base are belong to us!",
	"Hey, you have something on your chin... 3rd one down...",
	"Your birth certificate is an apology from the condom factory.",
	"Shut up, you'll never be the man your mother is!",
	"You must be the arithmetic man; you add trouble, subtract pleasure, divide attention, and multiply ignorance.",
	"You must have been born on a highway cuz that is where most accidents happen.",
	"It looks like your face caught on fire and someone tried to put it out with a fork.",
	"Your mom is a heifer!",
	"You're so ugly Hello Kitty said goodbye to you.",
	"The beetles will feed on your eyes. The worms will crawl through your lungs. The rain will fall on your rotting skin... until nothing is left of your but bones.",
	"You play like a girl.",
	"You're so ugly that when your mama dropped you off at school she got a fine for littering.",
	"You so stupid, you think a black hole is a racial insult.",
	"There are some things money can't buy. In your case, it'd be a life.",
	"Jesus loves you, but he's the only one who does.",
	"First time with that champion?",
	"If you were twice as smart, you'd still be stupid.",
	"Your momma so fat she has to wear two watches because she covers two time zones.",
	"Do you still love nature... despite what it did to you?",
	"You have a face like a granny being made to eat a turd at gunpoint.",
	"You are a thoroughly uncouth and uncharismatic gentleman. GOOD DAY SIR!",
	"You fight like a cow.",
	"I hear when you were a child your mother wanted to hire somebody to take care of you, but the mafia wanted too much.",
	"Why don’t you shut up and give that hole in your face a chance to heal.",
	"We all sprang from apes, but you didn't spring far enough.",
	"You think you're strong. You only smell strong.",
	"Out of 100,000 sperm, you were the fastest?",
	"You didn't fall out of the stupid tree. You got drug through dumbass forest.",
	"You're so ugly, when you popped out the doctor said awe what a treasure and your mom said yeah lets bury it.",
	"Why don't you slip into something more comfortable? Like a coma.",
	"You couldn't hit water if you fell out of a boat.",
	"Your mom must have a really loud bark!",
	"Your Mother is so dumb, she got hit by a cup and said she got mugged.",
	"Yo momma so fat, she had to be baptized in Sea World.",
	"Your mom's so ugly she made Chuck Norris have a heart attack.",
	"If you said what you thought, you'd be speechless.",
	"You're so fat you need cheat codes to play Wii Fit.",
	"If you really want to know about mistakes you should ask your parents.",
	"You so dumb, you thought a quarterback was a refund.",
	"The only thing that goes erect when I'm near you is my middle finger.",
	"Yo momma's like mayonnaise; she spreads easy.",
	"Your mother was an hamster, and your father smelt of elderberries!",
	"Your wife said she liked seafood. So I gave her crabs.",
	"You have a face only a mother could love.",
	"I refuse to have a battle of wits with an unarmed man.",
	"Yo momma's so fat, she's got more chins thin a chinese phone book.",
	"The only positive thing about you is your HIV status.",
	"With a face like yours, I wish I was blind."
}

local SpellPhrases = {
	-- Add new phrases below.
	{name="Annie", spell = _R, chat="KATTIBERS!!!"},
	{name="Blitzcrank", spell = _Q, chat="YOINK!"},
	{name="Blitzcrank", spell = _R, chat="QUIET!!"},
	{name="Caitlyn", spell = _R, chat="BOOM, HEADSHOT!!"},
	{name="Corki", spell = _R, chat="BOOM, HEADSHOT!!"},
	{name="Chogath", spell = _R, chat="NOM NOM NOM"},
	{name="Darius", spell = _R, chat="GET DUNKED, SON!"},
	{name="Draven", spell = _R, chat="This whole thing is Draven me crazy!"},
	{name="DrMundo", spell = _R, chat="MUNDO GO WHERE HE PLEASES"},
	{name="Garen", spell = _R, chat="DEMACIA!!!"},
	{name="Irelia", spell = _R, chat="That's totally Ireliavent."},
	{name="Karthus", spell = _R, chat="KABOOM!!!"},
	{name="Katarina", spell = _R, chat="SPIN 2 WIN!!!"},
	{name="Lux", spell = _R, chat="I'M FIRIN' MY LAZAR!!!"},
	{name="Lux", spell = _R, chat="This lux like it's gonna get ugly..."},
	{name="MasterYi", spell = _Q, chat="Like a ninja..."},
	{name="Nidalee", spell = _Q, chat="Javelin to the face!"},
	{name="Pantheon", spell = _R, chat="This is SPARTA!!!"},
	{name="Skarner", spell = _R, chat="Illegal parking!"},
	{name="Singed", spell = _E, chat="How about an acid bath... muahahaha!"},
	{name="Singed", spell = _R, chat="Oh, did I singe your eyebrows?"},
	{name="Sona", spell = _R, chat="Dance, Dance, Baby Tonight!"},
	{name="Twitch", spell = _R, chat="You guys make me Twitch with anger..."},
	{name="Thresh", spell = _Q, chat="Get over here!"},
	{name="Tryndamere", spell = _R, chat="I'M TRYNDAQUEER! AHAHAHHA"},
	{name="Vladimir", spell = _W, chat="TROLOLOLOLOL"},
	{name="Vladimir", spell = _R, chat="You Vlad, bro?"},
	{name="Zed", spell = _W, chat="That's what she Zed!"},
	{name="Zilean", spell = _W, chat="Time flies like arrow, fruit flies like banana."},
	{name="Ziggs", spell = _R, chat="Mega Bomb!"},

	-- Example of how to add new champions or phrases.
	-- The format is crucial. The script will break with formatting mistakes.
	{name="Example", spell = _Q, chat="Phrase 1"},
	{name="Example", spell = _Q, chat="Phrase 2"},
	{name="Example", spell = _Q, chat="Phrase 3"},
	{name="Example", spell = _W, chat="Phrase 4"},
	{name="Example", spell = _W, chat="Phrase 5"},
	{name="Example", spell = _R, chat="Phrase 6"}
}

local CoachPhrases = {
	-- Add new coach phrases below.
	-- In the case of kda, a positive severity means good, and a negative severity means bad.
	{event="kill",   severity=1,  chat="Good job."},
	{event="death",  severity=1,  chat="Shake it off."},
	{event="kill",   severity=1,  chat="Nice."},
	{event="death",  severity=1,  chat="Try again."},
	{event="kill",   severity=2,  chat="A little streak here?"},
	{event="death",  severity=2,  chat="You are better than this."},
	{event="kill",   severity=3,  chat="Farm their ass!"},
	{event="death",  severity=3,  chat="C'mon, get more kills!"},
	{event="kill",   severity=3,  chat="Farm their ass!"},
	{event="kill",   severity=3,  chat="Killing spree!"},
	{event="kill",   severity=3,  chat="You're doing great!"},
	{event="kill",   severity=3,  chat="You going pro yet?"},
	{event="death",  severity=3,  chat="You quitting yet?"},
	{event="death",  severity=3,  chat="Embarassing."},
	{event="death",  severity=3,  chat="Seriously?"},
	{event="death",  severity=3,  chat="Cry me a river."},
	{event="assist", severity=2,  chat="Nice assist."},
	{event="assist", severity=3,  chat="Great supporting!"},
	{event="kda",    severity=1,  chat="You're off to a good start."},
	{event="kda",    severity=-1, chat="Not the best start."},
	{event="kda",    severity=2,  chat="Good work."},
	{event="kda",    severity=2,  chat="Doing well!"},
	{event="kda",    severity=-2, chat="Eh, you need to spend more time practicing."},
	{event="kda",    severity=-2, chat="Fail."},
	{event="kda",    severity=3,  chat="You're pwning those nubs."},
	{event="kda",    severity=3,  chat="Smashing job."},
	{event="kda",    severity=3,  chat="Killer instincts!"},
	{event="kda",    severity=-3, chat="Baddy, you need to just surrender already."},
	{event="kda",    severity=-3, chat="Just save yourself some trouble and uninstall LoL."},
	{event="kda",    severity=-3, chat="Time to get in more bot games."}
}

alertedQ = false
alertedW = false
alertedE = false
alertedR = false

local lastSpamEmote = 0

local phrase = {}
local lastPhrase = nil
local lastInsult = nil
local lastCoach = nil
local lastCoachKDA = nil

local lastKills = nil
local lastDeaths = nil
local lastAssists = nil
local lastKDA = nil

function OnLoad()
	Menu()
	LoadMyHeroPhrases()
	PrintChat(" >> Troll Mode loaded!")
end

function Menu()
	TrollModeConfig = scriptConfig("Troll Mode - "..version, "Troll Mode")
	TrollModeConfig:addParam("sep", "----- [ Emote ] -----", SCRIPT_PARAM_INFO, "")
	TrollModeConfig:addParam("info", "Joke      (Ctrl+1)",  SCRIPT_PARAM_INFO, "")
	TrollModeConfig:addParam("info", "Taunt     (Ctrl+2)", SCRIPT_PARAM_INFO, "")
	TrollModeConfig:addParam("info", "Dance   (Ctrl+3)", SCRIPT_PARAM_INFO, "")
	TrollModeConfig:addParam("info", "Laugh   (Ctrl+4)", SCRIPT_PARAM_INFO, "")
	TrollModeConfig:addParam("sep", "----- [ Emote Spam ] -----", SCRIPT_PARAM_INFO, "")
	TrollModeConfig:addParam("SpamLaugh", "Spam Laugh", SCRIPT_PARAM_ONOFF, false)
	TrollModeConfig:addParam("SpamJoke", "Spam Joke",  SCRIPT_PARAM_ONOFF, false)
	TrollModeConfig:addParam("SpamTaunt", "Spam Taunt", SCRIPT_PARAM_ONOFF, false)
	TrollModeConfig:addParam("SpamFrequency", "Spam Frequency", SCRIPT_PARAM_SLICE, 3, 1, 60, 0)
	TrollModeConfig:addParam("sep", "----- [ Chat ] -----", SCRIPT_PARAM_INFO, "")
	TrollModeConfig:addParam("Insult", "Random Insult  (F5)", SCRIPT_PARAM_ONKEYDOWN, false, 116) -- F5
	TrollModeConfig:addParam("SpellChat", "Spell Chat", SCRIPT_PARAM_ONOFF, true)
	TrollModeConfig:addParam("EnableInsults", "Enable Insults", SCRIPT_PARAM_ONOFF, true)
	TrollModeConfig:addParam("PersonalCoach", "Personal Coach", SCRIPT_PARAM_ONOFF, true)
	TrollModeConfig:addParam("ChatThrottle", "Spell Chat Throttle", SCRIPT_PARAM_ONOFF, false)
	TrollModeConfig:addParam("ChatThrottleFrequency", "Throttle Min. Seconds", SCRIPT_PARAM_SLICE, 120, 1, 600, 0)
end

function LoadMyHeroPhrases()
	for i = 1, #SpellPhrases, 1 do
		if myHero.charName == SpellPhrases[i].name then
			table.insert(phrase, SpellPhrases[i])
		end
	end
end

function OnTick()
	if myHero.dead then return end
 
	if TrollModeConfig.SpellChat and phrase ~= nil then
		CheckSpellPhrases()
	end

	if TrollModeConfig.EnableInsults and TrollModeConfig.Insult then
		Insult()
	end

	if TrollModeConfig.PersonalCoach then
		Coach()
	end

	if TrollModeConfig.SpamLaugh or TrollModeConfig.SpamJoke or TrollModeConfig.SpamTaunt then
		SpamEmote()
	end
end

function SpamEmote()
	if (GetTickCount() - lastSpamEmote) > (TrollModeConfig.SpamFrequency * 1000) then
		lastSpamEmote = GetTickCount()
		myHero:MoveTo(mousePos.x, mousePos.z)

		if TrollModeConfig.SpamLaugh then SendChat("/l") end
		if TrollModeConfig.SpamJoke then SendChat("/j") end
		if TrollModeConfig.SpamTaunt then SendChat("/t") end
	end
end

function Coach()
	if not lastKills or not lastDeaths or not lastAssists or not lastKDA then
		lastCoach = 0
		CoachSay("Have a good game!")
		lastKills = 0
		lastDeaths = 0
		lastAssists = 0
		lastKDA = 0

		return
	end

	if lastCoach and GetTickCount() < (lastCoach + (30 * 1000)) then return end

	local deaths = nil
	if myHero.deaths > 0 then
		deaths = myHero.deaths
	else
		deaths = 1
	end

	local kda = (myHero.kills + (myHero.assists / 2)) / deaths

	if not lastCoachKDA or (GetTickCount() > (lastCoachKDA + (60 * 1000))) then
		if kda > lastKDA then
			if kda > 3.0 then
				SendCoachPhrase("kda", 3)
			elseif kda > 2.0 then
				SendCoachPhrase("kda", 2)
			end
		elseif kda < lastKDA then
			if kda < .5 then
				SendCoachPhrase("kda", -3)
			elseif kda < 0.8 then
				SendCoachPhrase("kda", -2)
			end
		end
	end

	if myHero.kills > lastKills then
		if myHero.kills > 8 then
			SendCoachPhrase("kill", 3)
		elseif myHero.kills > 4 then
			SendCoachPhrase("kill", 2)
		else
			SendCoachPhrase("kill", 1)
		end
	end

	if myHero.deaths > lastDeaths then
		if myHero.deaths > 8 then
			SendCoachPhrase("death", 3)
		elseif myHero.deaths > 4 then
			SendCoachPhrase("death", 2)
		else
			SendCoachPhrase("death", 1)
		end
	end

	if myHero.assists > lastAssists then
		if myHero.assists > 8 then
			SendCoachPhrase("assist", 3)
		elseif myHero.assists > 4 then
			SendCoachPhrase("assist", 2)
		else
			SendCoachPhrase("assist", 1)
		end
	end

	lastKills = myHero.kills
	lastDeaths = myHero.deaths
	lastAssists = myHero.assists
	lastKDA = kda
end

function SendCoachPhrase(event, severity)
	if #CoachPhrases == 0 then
		PrintChat("Coach phrase library is empty!")
		return
	end

	local count = 0

	-- Find number of applicable phrases.
	for i = 1, #CoachPhrases, 1 do
		if CoachPhrases[i].event == event and CoachPhrases[i].severity == severity then
			count = count + 1
		end
	end

		-- Find number of applicable phrases.
	for i = 1, #CoachPhrases, 1 do
		if CoachPhrases[i].event == event and CoachPhrases[i].severity == severity then
			count = count + 1
		end
	end

	-- Send chosen phrase.
	if count == 0 then return end

	local index = 1
	if count > 1 then
		index = math.random(1, count)
	end

	local foundCount = 0
	for i = 1, #CoachPhrases, 1 do
		if CoachPhrases[i].event == event and CoachPhrases[i].severity == severity then
			if count == 1 then
				lastCoach = GetTickCount()
				if event == "kda" then lastCoachKDA = GetTickCount() end
				CoachSay(CoachPhrases[i].chat)
				break
			elseif count > 1 then
				foundCount = foundCount + 1
				if foundCount == index then
					lastCoach = GetTickCount()
					if event == "kda" then lastCoachKDA = GetTickCount() end
					CoachSay(CoachPhrases[i].chat)
					break
				end
			end
		end
	end
end

function CoachSay(chat)
	PrintChat("Coach says, \""..chat.."\"")
end

function UpdateCoachInfo()

end

function CheckSpellPhrases()
	if TrollModeConfig.ChatThrottle and lastPhrase and GetTickCount() < (lastPhrase + (TrollModeConfig.ChatThrottleFrequency * 1000)) then return end

	if myHero:CanUseSpell(_Q) == READY then alertedQ = false end
	if myHero:CanUseSpell(_W) == READY then alertedW = false end
	if myHero:CanUseSpell(_E) == READY then alertedE = false end
	if myHero:CanUseSpell(_R) == READY then alertedR = false end

	if myHero:CanUseSpell(_Q) == COOLDOWN and not alertedQ then
		alertedQ = true
		SendPhrase(_Q)
	end

	if myHero:CanUseSpell(_W) == COOLDOWN and not alertedW then
		alertedW = true
		SendPhrase(_W)
	end

	if myHero:CanUseSpell(_E) == COOLDOWN and not alertedE then
		alertedE = true
		SendPhrase(_E)
	end

	if myHero:CanUseSpell(_R) == COOLDOWN and not alertedR then
		alertedR = true
		SendPhrase(_R)
	end
end

function Insult()
	if #InsultPhrases == 0 then
		PrintChat("Insult library is empty!")
		return
	end

	if lastInsult and GetTickCount() < (lastInsult + 1000) then return end

	local index = math.random(1, #InsultPhrases)
	lastInsult = GetTickCount()
	SendChatMessage(InsultPhrases[index])
end

function SendPhrase(spell)
	if #SpellPhrases == 0 then
		PrintChat("Spell phrase library is empty!")
	end

	if #phrase == 0 then
		return
	end

	local count = 0

	-- Find number of applicable phrases.
	for i = 1, #phrase, 1 do
		if phrase[i].spell == spell then
			count = count + 1
		end
	end

	-- Send chosen phrase.
	if count == 0 then return end

	local index = 1
	if count > 1 then
		index = math.random(1, count)
	end

	local foundCount = 0
	for i = 1, #phrase, 1 do
		if phrase[i].spell == spell then
			if count == 1 then
				lastPhrase = GetTickCount()
				SendChatMessage(phrase[i].chat)
				break
			elseif count > 1 then
				foundCount = foundCount + 1
				if foundCount == index then
					lastPhrase = GetTickCount()
					SendChatMessage(phrase[i].chat)
					break
				end
			end
		end
	end
end

function SendChatMessage(chat)
	SendChat("/t")
	SendChat("/all "..chat)
end

--UPDATEURL=https://bitbucket.org/KainBoL/bol/raw/master/Troll%20Mode.lua
--HASH=3161E5502A37163FB20D82DB0CD87FF4
