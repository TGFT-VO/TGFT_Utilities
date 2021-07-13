declare("tgft", {version = "3.16"})
-- Price data Collector and reporter, spotter
--	Lisa201

require("iuplua")
require("iupluacontrols")
dofile("tgftd_http.lua")
dofile("systems.lua")
dofile("json.lua")
dofile("colorcodes.lua")
tgft.ui = dofile'ui.lua'

tgft.alertenter = true
tgft.alertleave = true
tgft.debug = false
tgft.passwd = nil
tgft.username = nil
tgft.unload = false
tgft.TurboOn = false
tgft.nodeid = 0
tgft.objectid = 0
tgft.keys = {}
tgft.stations = {}
tgft.councilcommands = {}
tgft.roids = {}
tgft.warned = false
tgft.watchdent = true
tgft.LastSector = "None"
tgft.Timer = Timer()
tgft.MyPlot = {}
tgft_White = "\127ffffff"
tcs = tcs or ""

LisaJunk = {}

-------------------------------------------------------
-- Debug Print
-------------------------------------------------------
function dprint(message)
print(colorsRGB.text("lightpink")..message)
end

-------------------------------------------------------
-- Process server data received event
-------------------------------------------------------
function tgft.ServerDataEvent(_,data) --ProcessEvent("TGFT_SERVER_DATA", tgft.SrvHead)
local v = data[1][1]
if tgft.debug then dprint("Got data from script -> "..v) end
if v == "liststations" then
	tgft.stations = data[2];
elseif v == "listcouncil" then
	tgft.councilcommands = data;
	tgft.council();
elseif v == "altfinder" then
	tgft.displayrowtext(data);
elseif v == "lastseen" then
	tgft.displaytext(data);
elseif v == "h" then
	print("aych")
	end

end

-------------------------------------------------------
-- CallBack from server requests.
-------------------------------------------------------
function tgft.GetServerData(script,data)
if tgft.debug then dprint("Running script -> "..script..".php") end
urlopen('http://www.tgft.org/vendetta/'..script..'.php', 'POST',
function (not_ok, header, data)
	if not_ok then
		tgft.msg(tgft_White,not_ok)
	else
		if header.status == 200 then --Process what came back
			tgft.SrvHead = json.decode(data)
			ProcessEvent("TGFT_SERVER_DATA", tgft.SrvHead)
		elseif header.status then
			tgft.msg(tgft_White,"ERROR9: HTTP Error "..header.status.."   Script:"..script)
		end
	end
end
,{username=tgft.username, passwd=tgft.passwd, app=tgft.version, data=data})
end

-------------------------------------------------------
-- TEST Server Call back function NOTE the X
-------------------------------------------------------
function tgft.Server_Callback_TextX(not_ok, header, tgft_page)
if tgft.debug then dprint("Lisa Utils Server_Callback Function...") end
local tgft_srvdata	= {}
  if not_ok then
  	print("\127ffffffERROR17: "..not_ok)
  else
    if header.status == 200 then --Process what came back
		local beg = string.find(tgft_page, "[", nil, true)
		local backwards = string.reverse(tgft_page)
		local ending = #tgft_page - string.find(backwards, "]", nil, true) + 1
		print("Beg:"..beg.."  End:"..ending)
  	else
		if header.status then
    		tgft.msg(tgft_White,"ERROR2: HTTP Error "..header.status)
		end
  	end --Process what came back
   end
end

-------------------------------------------------------
-- Server Call back function
-------------------------------------------------------
function tgft.Server_Callback_Text(not_ok, header, tgft_page)
if tgft.debug then dprint("Lisa Utils Server_Callback Function...") end
local tgft_srvdata	= {}
  if not_ok then
  	print("\127ffffffERROR1: "..not_ok)
  else
    if header.status == 200 then --Process what came back
  		for token in string.gmatch(tgft_page, "[^\n]+") do --Convert to table
  			if token ~= "\r" then
				table.insert(tgft_srvdata,token)
				print("\127ffffff"..token)
			end
		end
  	else
		if header.status then
    		tgft.msg(tgft_White,"ERROR2: HTTP Error "..header.status)
		end
  	end --Process what came back
   end
end

-------------------------------------------------------
-- Take data in a table and display it on the screen
-------------------------------------------------------
function tgft.displaytext(data)
local txt = "\127ffffff"

	if (#data[1][2] > 1) then -- Multi column data
		--print("Need to write the code for multiple columns here.")
		for i=1, #data[1][2] do -- column Headers
			txt = txt..data[1][2][i].."          "
		end
		print(txt.."\127a0a0a0")
		for i=1, #data[2] do -- rows of data
			txt = ""
			for j=1, #data[2][i] do -- rows of data
				txt = txt..(data[2][i][j].."    ")
			end
			print(txt)
		end
	else -- Process one-line returns...

		local text = "\127ffffff"..data[1][2][1].."\127a0a0a0"
			--print("\127ffffff"..data[1][2][1])
			for j=1, #data[2] do
				text = text.."   '"..data[2][j].."'"
			end
		print(text)
	end
end

-------------------------------------------------------
-- Take data in a formatted table and display it on the screen
-------------------------------------------------------
function tgft.displayrowtext(data)
--LisaJunk = data
local txt = "\127ffffff"
	for row=2, #data[1] do
	txt = "\127ffffff"..data[1][row][1]
		for col=2,#data[1][row] do
			txt = txt.."\127a0a0a0  '"..data[1][row][col].."'"
		end
		print(txt);
	end
end

-------------------------------------------------------
-- create random string for password
-------------------------------------------------------
function tgft.RandomString(length)
if length < 1 then return nil end
local valChars = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
length = length or 1
local array = ""
for i = 1,length do
	local A = math.random(#valChars)
	array = array..string.sub(valChars,A,A)
end
return array
end

-------------------------------------------------------------
-- Toggle Turbo on and off
-------------------------------------------------------------
function turbotoggle()
if tgft.TurboOn then
      gkinterface.GKProcessCommand('+turbo 1')
      gkinterface.GKProcessCommand('+turbo 0')
else
      gkinterface.GKProcessCommand('+turbo 0')
      gkinterface.GKProcessCommand('+turbo 1')
 end
	tgft.TurboOn = not tgft.TurboOn
end

-------------------------------------------------------------
-- Toggle debug on and off
-------------------------------------------------------------
function debugtoggle()
	tgft.debug = not tgft.debug
	if tgft.debug then dprint("debug on") else dprint("debug off") end
end

-------------------------------------------------------------
-- Launch from the ship
-------------------------------------------------------------
function tgft.launch()
RequestLaunch()
end

-------------------------------------------------------
-- Get Keys in your keychain
-------------------------------------------------------
function tgft.Get_Keychain()
if tgft.debug then dprint("tgft is calling the get key routine.") end
tgft.keys = {}
for v = 1, GetNumKeysInKeychain(), 1 do
		local keyid, description, owner, timestamp, access, possessors, active = GetKeyInfo(tonumber(v))
		local key_data = {}
		if active then -- Only active keys have possessor tables...
			Keychain.list(keyid,
				function(isError, message)
				if (isError) then
					print("KEY ERROR:")
				else
					keyid, description, owner, timestamp, access, possessors, active = GetKeyInfo(tonumber(v))
				end
			end)
			local key_data = {ID = keyid, DESC = description, OWN = owner, ACTIVE = active, ACCESS = access, POSS = possessors }
			table.insert(tgft.keys,key_data)
		end
	end
end

-------------------------------------------------------
-- Get a keys index number
-------------------------------------------------------
function tgft.GetKeyIndex(x)
	for i = 1, GetNumKeysInKeychain(), 1 do
		local keyid, description, owner, timestamp, access, possessors, active = GetKeyInfo(tonumber(i))
		if (tonumber(keyid) == tonumber(x)) then return i end
	end
return -1 -- Not found in the list
end

-------------------------------------------------------
-- Verify Key when you enter systems
-------------------------------------------------------
function tgft.VerifyDestination()
	local destsector = NavRoute.GetNextHop()
	if not destsector then return end
	local stationname = "None"
	if destsector==4019 then stationname = "Pelatus Mining Station" end
	if destsector==4317 then stationname = "Bractus IX Planetary Outpost" end
	if destsector==5753 then stationname = "CONQUERABLE STATION" end
	tgft.Sector_Verified()
	if stationname == "None" then return end -- Normal sectors... just return
  	if tgft.debug then dprint("Verify Key for Sector:"..destsector) end

	for i = 1, #tgft.keys, 1 do
		local keyid, description, owner, timestamp, access, possessors, active =
			GetKeyInfo(tonumber(tgft.GetKeyIndex(tgft.keys[i]["ID"])))
		if access then
			for j = 1, # access, 1 do
				if (access[j][1].name==stationname) then
					if (access[j][2].candock) and (access[j][2].iff)then return end
				end
			end
		end
	end
	print("\127ff1010-- WARNING -- Key is NOT VALID for: "..stationname)
end

-------------------------------------------------------
-- Verify faction standing before jumping to systems
-------------------------------------------------------
function tgft.Sector_Verified()
	local destsector = NavRoute.GetNextHop()
  	if tgft.debug then dprint("Verify standing at Destination Sector:"..destsector) end
	local systemid = GetSystemID(destsector)
  	if tgft.debug then dprint("SystemID is:"..systemid) end
	local faction = tgft.System_Names[systemid][3]
  	if tgft.debug then dprint("Local Factin is:"..faction) end
  	if tgft.debug then dprint("Number of stations loaded:"..#tgft.stations) end

	for i = 1, #tgft.stations, 1 do
		if (tonumber(tgft.stations[i][1]) == destsector) then
			faction = tonumber(tgft.stations[i][2])
			break;
		end
	end
	local destfaction = GetPlayerFactionStanding(faction, GetCharacterID()) / 32.768 -1000
	if destfaction < -600 then
		print("\127ff1010-- WARNING -- Faction Standing at Destination: "..math.floor(destfaction))
	elseif destfaction < -590 then
		print("\127FFFF00-- CAUTION -- Check Faction Standing.  Low at Destination! "..math.floor(destfaction))
	end
end

-------------------------------------------------------
-- Saw a player in space
-------------------------------------------------------
function tgft.SawPlayer(event, data)
	if not data then return end
 	local CharName = GetPlayerName(data)
 	local CharID = data
 	if CharName == GetPlayerName(GetCharacterID()) then return end
  	local isNPC = (string.sub( CharName, 1, 1) == "*") or (string.match(CharName, "reading transponder"))
  	if isNPC then return end --Don't log bots...
 	local CharShip = GetPrimaryShipNameOfPlayer(data) or "NO Ship"
 	local CharGuild = GetGuildTag(data)
  	if tgft.debug then dprint("SawPlayer Event:"..event) end
 	if tgft.debug then dprint("Spotted: "..CharName.."   Ship:"..CharShip) end
 	if tgft.alertenter then
		local CharFaction = GetPlayerFaction(CharID)
		local msg = colorsRGB.text("limegreen").."*"

		if CharFaction == 1 then
			msg = msg..colorsRGB.text("blue")
		elseif CharFaction == 2 then
			msg = msg..colorsRGB.text("red")
		else
			msg = msg..colorsRGB.text("yellow")
		end

 		if CharGuild ~= "" then
 			msg = msg.."["..CharGuild.."] "
		end

  		msg = msg..CharName

 		if (CharShip ~= "NO Ship" ) then
			msg = msg..colorsRGB.text("lavender").." in a "..CharShip
			end

  		local distance = 0
		distance = math.ceil(GetPlayerDistance(CharID) or -1)
		if distance > 0 then
			msg = msg.." @ "..distance.."m"
			end

		local local_standing = GetPlayerFactionStanding("sector", CharID) or -1
		if local_standing > 0 then
			local CharStanding = factionfriendlyness(local_standing)
			local StandColor = colorsRGB.text("lightyellow")
			if string.find(CharStanding,"Admire") ~= nil then StandColor = colorsRGB.text("green") end
			if string.find(CharStanding,"Pillar") ~= nil then StandColor = colorsRGB.text("gold") end
			msg = msg..colorsRGB.text("gray").." Local Standing is "..StandColor..CharStanding
			end
 		print(msg)
 	end

 	if (CharShip == "NO Ship" ) then return end -- Don't send spots with no ships.
 	local whereat = ShortLocationStr(GetCurrentSectorid())
	if tgft.debug then dprint("Sending player spot: "..CharName.."  Guild: "..CharGuild.." Ship: "..CharShip.."  CharID: "..CharID) end
	local mydata = {}
	table.insert(mydata,CharName)
	table.insert(mydata,CharGuild)
	table.insert(mydata,CharID)
	table.insert(mydata,whereat)
	table.insert(mydata,GetPlayerName(GetCharacterID()))
	table.insert(mydata,CharShip)
	table.insert(mydata,tgft.passwd)
	local senddata = json.encode( mydata )
	urlopen('http://www.tgft.org/vendetta/playerspot3.php', 'POST',tgft.Server_Callback_Text , {username=tgft.username, passwd=tgft.passwd, app=tgft.version, data=senddata})
 end

-------------------------------------------------------
-- Saw player leave sector
-------------------------------------------------------
function tgft.PlayerLeft(event,data)
	if not tgft.alertleave then return end
	if not data then return end
	local characteris = GetPlayerName(data)
	local hischarid = data
	if characteris == GetPlayerName(GetCharacterID()) then return end
	local isNPC = (string.sub( characteris, 1, 1) == "*") or (string.match(characteris, "reading transponder"))
	if isNPC then return end --Don't log bots...
	local hisguild = GetGuildTag(data)
	local hisguildprint = ""
	if hisguild ~= "" then
 		hisguildprint = "["..hisguild.."] "
 	end
 	local CharFaction = GetPlayerFaction(hischarid)
	local msg = colorsRGB.text("limegreen").."*"
		if CharFaction == 1 then
			msg = msg..colorsRGB.text("blue")
		elseif CharFaction == 2 then
			msg = msg..colorsRGB.text("red")
		else
			msg = msg..colorsRGB.text("yellow")
		end
	msg = msg..hisguildprint..characteris..tgft_White.." Left the Sector"
	print(msg)
end

-------------------------------------------------------
-- Last Seen data
-------------------------------------------------------
function tgft.Lastseen(_, data)
if not data then return end
if tgft.debug then dprint("Lastseenplayer called") end
local senddata = json.encode( data )
tgft.GetServerData("lastseenplayer",senddata)
end

-------------------------------------------------------
-- Alt Finder
-------------------------------------------------------
function tgft.Altfinder(_, data)
if not data then return end
if tgft.debug then dprint("Altfinder called.") end
local senddata = json.encode( data )
if tgft.debug then dprint("++>"..senddata.."<++") end
tgft.GetServerData("altfinder8",senddata)

end

-------------------------------------------------------
-- Lookup Item Low System
-------------------------------------------------------
function tgft.LookupItemLowSystem(_, data)
if not data then return end
urlopen('http://www.tgft.org/vendetta/lookupitemlowsystem.php', 'GET',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, name=data[1],systemname=data[2]})
if tgft.debug then dprint("LookupStation called") end
end

-------------------------------------------------------
-- Lookup Item High System
-------------------------------------------------------
function tgft.LookupItemHighSystem(_, data)
if not data then return end
urlopen('http://www.tgft.org/vendetta/lookupitemhighsystem.php', 'GET',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, name=data[1],systemname=data[2]})
if tgft.debug then print("LookupStation called") end
end

-------------------------------------------------------
-- Sector Data Update
-------------------------------------------------------
function tgft.SectorUpdate(_, data)
	if (tgft.username == nil or tgft.username == '' or (string.len(tgft.username)<1)) then
		tgft.Init()
		end

	local secempty = 0
	local sectorid = GetCurrentSectorid()
	local secname = ShortLocationStr(sectorid)
	if (secname == tgft.LastSector) then return end
	local secstorm = 0
	if IsStormPresent() then
		secstorm = 1
	end
	local botinfo = GetBotSightedInfoForSector(sectorid) or "N/A"
	botinfo = string.gsub(botinfo, "Bots Sighted: ", "")
	local distance = radar.GetNearestObjectDistance()
	if distance == -1 then
		secempty = 1
	end
	if tgft.debug then dprint("Sector Updated.") end
	urlopen('http://www.tgft.org/vendetta/sectordata.php', 'POST',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, secempty=secempty,sectorid=sectorid,secname=secname,secstorm=secstorm,botinfo=botinfo,secempty=secempty})
	tgft.LastSector = secname
end

-------------------------------------------------------
-- Search Items
-------------------------------------------------------
function tgft.SearchItems(_, data)
if not data then return end
urlopen('http://www.tgft.org/vendetta/searchitems.php', 'GET',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, name=data[1]})
if tgft.debug then dprint("SearchItem called") end
end

-------------------------------------------------------
-- Lookup Item Low Price
-------------------------------------------------------
function tgft.LookupItemLow(_, data)
if not data then return end
urlopen('http://www.tgft.org/vendetta/lookupitemlow.php', 'GET',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, name=data[1]})
if tgft.debug then dprint("LookupItemLow called") end
end

-------------------------------------------------------
-- Lookup Item High Price
-------------------------------------------------------
function tgft.LookupItemHigh(_, data)
if not data then return end
urlopen('http://www.tgft.org/vendetta/lookupitemhigh.php', 'GET',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, name=data[1]})
if tgft.debug then dprint("LookupItemHigh called") end
end

-------------------------------------------------------
-- Lookup Station names and factions
-------------------------------------------------------
function tgft.Stations(_, data)
if not data then return end
urlopen('http://www.tgft.org/vendetta/stations.php', 'POST',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, data=json.encode(data)})
if tgft.debug then dprint("Lookup Stations called") end
end

-------------------------------------------------------
-- Lookup Bots
-------------------------------------------------------
function tgft.SearchBots(_, data)
if not data then return end
urlopen('http://www.tgft.org/vendetta/searchbots2.php', 'POST',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, data=json.encode(data)})
if tgft.debug then dprint("Lookup Bots called") end
end

-------------------------------------------------------
-- Remove " from item names...
-------------------------------------------------------
function tgft.RemQuote(data)
data = string.gsub(data, '"', '')
return data
end

-------------------------------------------------------
-- Station Buy Price Update
-------------------------------------------------------
function tgft.BuyUpdate(_, data)
local stationid = GetStationLocation()
local stationsmarket = {}
for _,info in StationSellableInventoryPairs() do
	local item = {}
	if (info.type ~= nil) then
		local onepcs = GetStationSellableInventoryPriceByID(info.itemid, 1)
		local many = GetStationSellableInventoryPriceByID(info.itemid, 1000000) / 1000000
		local static = 0
		if (onepcs==many) then -- Check for static price...
			static = 1
		end
		table.insert(item, stationid) -- 0
		table.insert(item, info.itemtype) -- 1 Really the ItemID
		local temp = tgft.RemQuote(info.name)
		table.insert(item, temp) -- 2
		table.insert(item, info.type) -- 3
		table.insert(item, info.price) -- 4
		table.insert(item, static) -- 5
		table.insert(stationsmarket, item)
	end
end
local senddata = json.encode( stationsmarket )
if tgft.debug then dprint("Stations Buy prices updated! ") end
urlopen('http://www.tgft.org/vendetta/stationbuyprice.php', 'POST',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, data=senddata})
end

-------------------------------------------------------
-- Station Update of things you can buy here
-------------------------------------------------------
function tgft.StationUpdate(_, data)
local item = {}
local sectorid = GetCurrentSectorid()
if tgft.debug then dprint("SectorID:"..sectorid) end
if (GetCurrentStationType() == 1) then return end
local stationid = GetStationLocation()
if tgft.debug then dprint("StationID:"..stationid) end
local name = GetStationName(stationid)
if tgft.debug then dprint("Name:"..name) end
local faction = GetStationFaction(stationid)
if tgft.debug then dprint("Faction:"..faction) end
table.insert(item,sectorid)
table.insert(item,stationid)
table.insert(item,name)
table.insert(item,faction)
item = json.encode( item )
urlopen('http://www.tgft.org/vendetta/stationinfo.php', 'POST',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, data=item})
if tgft.debug then dprint("Station Data Updated.   stationinfo.php") end

local senddata = {}
for i=1, GetNumStationMerch() do
	item = {}
	local info = GetStationMerchInfo(i)
	info.mass = tonumber(string.match(info.extendeddesc, "Mass: (%d+) kg") or 0)
	table.insert(item, info.itemid)
	table.insert(item, info.mass)
	table.insert(item, info.type)
	table.insert(item, info.volume)
	table.insert(item, info.name)
	table.insert(item, info.price)
	table.insert(item, stationid)
	table.insert(item, 0)
	table.insert(senddata, item)
end

local senddata = json.encode( senddata )
urlopen('http://www.tgft.org/vendetta/stationitems3.php', 'POST',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, data=senddata})
if tgft.debug then dprint("Station Items Sold Updated.   stationitems.php") end
tgft.BuyUpdate(_, data)
end

-------------------------------------------------------
-- Price Update part 2
-------------------------------------------------------
function tgft.PriceUpdate2(_, data)
UnregisterEvent(tgft.BuyUpdate,"STATION_UPDATE_DESIREDITEMS")
print("Prices have been updated.")
tgft.Timer:SetTimeout(2000,tgft.BuyUpdate)
end

-------------------------------------------------------
-- Price Update
-------------------------------------------------------
function tgft.PriceUpdate(_, data)
if not data then return end
if string.find(data.msg, "sold for a total amount") then
	RegisterEvent(tgft.PriceUpdate2,"STATION_UPDATE_DESIREDITEMS")
	print("Station prices will update in about a minute...")
	end
end

-------------------------------------------------------
-- Find my Trident
-------------------------------------------------------
function tgft.FindDent(_, data)
	local items = {}
	for itemid,v in PlayerInventoryPairs() do
		local itemname = GetInventoryItemName(itemid)
		local stationid = GetInventoryItemLocation(itemid)
		local sectorid = SplitStationID(stationid)
		local itype = GetInventoryItemLongDesc(itemid)
		if string.find(itype,"Trident Type") then
			local location = ShortLocationStr(sectorid)
			if (location=="0 @-0") then
				print("-- Active Ship --")
				break
			end
			items = {itype=itype, location=location, itemname=itemname}
			print("\127ffffffYour dent is in: "..location.."   Navigation route set.")
			local location = string.match(location, '(%a+)').." "..string.match(location, '(%a%-%d+)')
			NavRoute.SetFinalDestination(SectorIDFromLocationStr(location))
		end
	end
end

-------------------------------------------------------
-- Add an item to the guild list
-------------------------------------------------------
function tgft.GuildItem(_, data) -- command, qty, "item name"
if not data then
	print("no data")
	return
	end
local senddata = json.encode( data )
urlopen('http://www.tgft.org/vendetta/guilditem.php', 'POST',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, data=senddata})
if tgft.debug then dprint("GuildItems called") end
end

-------------------------------------------------------
-- Unload cargo, and re-launch on docking event
-------------------------------------------------------
function tgft.Unload2()
local shipinv = GetShipInventory(GetActiveShipID())
local cargolist = shipinv.cargo
local unloadlist = {}
for k,itemid in ipairs(cargolist) do
	local itemquantity = GetInventoryItemQuantity(itemid)
	if itemquantity then
		table.insert(unloadlist, {itemid=itemid, quantity=itemquantity})
	end
end
CheckStorageAndUnloadCargo(unloadlist)
tgft.Timer:SetTimeout(500,RequestLaunch)
end

-------------------------------------------------------
-- Unload cargo enable disable events
-------------------------------------------------------
function tgft.Unload()
	if (tgft.unload) then
	print("Auto Unload-Launch OFF")
	tgft.unload = not tgft.unload
	UnregisterEvent(tgft.Unload2, "ENTERED_STATION")
	else
	print("Auto Unload-Launch ON")
	tgft.unload = not tgft.unload
	RegisterEvent(tgft.Unload2, "ENTERED_STATION")
	end
end

-------------------------------------------------------
-- Modify Hostile list
-------------------------------------------------------
function tgft.Hostile(_,data)
--if not data then return end
urlopen('http://www.tgft.org/vendetta/hostile.php', 'POST',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, data=json.encode(data)})
if tgft.debug then print("HOSTILE called") end
end

-------------------------------------------------------
-- Modify App list
-------------------------------------------------------
function tgft.App(_,data)
--if not data then return end
urlopen('http://www.tgft.org/vendetta/applicants.php', 'POST',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, data=json.encode(data)})
if tgft.debug then dprint("Applicants called") end
end

-------------------------------------------------------
-- Load list of council commands
-------------------------------------------------------
function tgft.GetCouncilCommands(_, data)
tgft.GetServerData("listcouncil")
--if tgft.debug then print("ListCouncil called") end
end

-------------------------------------------------------
-- Init
-------------------------------------------------------
function tgft.Connection()
print("Connected...")
end

-------------------------------------------------------
-- Last Seen Data for UI
-------------------------------------------------------
function tgft.LastSeenData(_, data)
if not data then return end
urlopen('http://www.tgft.org/vendetta/lastseendata.php', 'POST',tgft.Server_Callback_TextX, {username=tgft.username, passwd=tgft.passwd, app=tgft.version, data=json.encode(data)})
if tgft.debug then dprint("LastseenData called") end
end

-------------------------------------------------------
-- Save Binds
-------------------------------------------------------
function tgft.BindSave(_, data)
print("\127ffffffSaving current binds....")
gkinterface.GKSaveCfg()
end

-------------------------------------------------------
-- Council functions
-------------------------------------------------------
function tgft.council()
print("Username: "..tgft.username)
	for i=1, #tgft.councilcommands[2] do
		print("Command: "..tgft.councilcommands[2][i][1])
		gkinterface.GKProcessCommand(tgft.councilcommands[2][i][1])
		end
end


-------------------------------------------------------
-- Trident under attack toggle
-------------------------------------------------------
function tgft.watchtoggle(_, data)
if tgft.watchdent then
	UnregisterEvent(tgft.MsgNotification, "MSG_NOTIFICATION")
	print("\127ffffffWatch Dent function is now OFF")
else
	RegisterEvent(tgft.MsgNotification, "MSG_NOTIFICATION")
	print("\127ffffffWatch Dent function is now ON")
end
tgft.watchdent = not tgft.watchdent
end

-------------------------------------------------------
-- Trident under attack function
-------------------------------------------------------
function tgft.MsgNotification(_, data)
if not data then print("No data...") ; return end
if (string.match(data, "Your ship is under attack")) then
	SendChat("**** "..data.." ****", "GUILD")
	end
end

-------------------------------------------------------
-- Init
-------------------------------------------------------
function tgft.Init()
UnregisterEvent(tgft.Init1, "SECTOR_LOADED")
tgft.passwd = gkini.ReadString("TGFT_Util","Password" ,"None")
local net = gkini.ReadString("TGFT_Util","Enabled" ,0)
tgft.username = GetPlayerName(GetCharacterID())
local charid, rank, name = GetGuildMemberInfoByCharID(GetCharacterIDByName(tgft.username))
if ((tgft.passwd == "None") or (string.len(tgft.passwd) < 20)) then
	tgft.passwd = tgft.RandomString(30)
		gkini.WriteString("TGFT_Util", "Password", tgft.passwd)
	if tgft.debug then dprint("Your Password is:"..tgft.passwd) end
end
rank = rank or 0
if rank > 1 then
	tgft.GetCouncilCommands()
	--tgft.council()
end
print("\127ffffffTGFT Utilities Version "..tgft.version)
tgft.GetServerData("liststations")
RegisterEvent(tgft.Get_Keychain, "KEYADDED") -- Update the data after getting a new key.
RegisterEvent(tgft.Get_Keychain, "KEYREMOVED") -- Update the data after Losing a key.
RegisterEvent(tgft.VerifyDestination, "SECTOR_LOADED")
RegisterEvent(tgft.VerifyDestination, "NAVROUTE_CHANGED")
RegisterEvent(tgft.SectorUpdate, "SHIP_SPAWN_CINEMATIC_FINISHED")
RegisterEvent(tgft.StationUpdate, "ENTERED_STATION")
RegisterEvent(tgft.SawPlayer, "PLAYER_ENTERED_SECTOR")
RegisterEvent(tgft.PlayerLeft, "PLAYER_LEFT_SECTOR")
RegisterEvent(tgft.SawPlayer, "SHIP_SPAWNED")
RegisterEvent(tgft.ServerDataEvent, "TGFT_SERVER_DATA")
RegisterEvent(tgft.MsgNotification, "MSG_NOTIFICATION")
RegisterEvent(tgft.PriceUpdate,"CHAT_MSG_CONFIRMATION")
tgft.Get_Keychain()
if tcs and tcs.alm and tcs.alm.state == 1 then
	tgft.alertenter = false
	tgft.alertleave = false
	else
	tgft.alertenter = true
	tgft.alertleave = true
	end
end

-------------------------------------------------------
-- Init
-------------------------------------------------------
function tgft.Init1()
	tgft.Timer:SetTimeout(8000,tgft.Init)
end

-------------------------------------------------------
-- Save Current Nav Plot function
-------------------------------------------------------
function tgft.saveplot(_, data)
--tgft.MyPlot = NavRoute.GetCurrentRoute()



local a = NavRoute.GetCurrentRoute()
for i = 1, #a do
   --local copy = a
   tgft.MyPlot[i] = a[i]
   -- alter the values in the copy
end
end

-------------------------------------------------------
-- Load Saved Nav Plot function
-------------------------------------------------------
function tgft.plot(_, data)
NavRoute.SetFullRoute(tgft.MyPlot)
end

-------------------------------------------------------
-- Help
-------------------------------------------------------
function tgft.Help()
tgft.ui:ShowHelp()
end

function tgft.uion()
--tgft.mydlg.mywindow:show()
end
function tgft.uioff()
--tgft.mydlg.mywindow:hide()
end

RegisterUserCommand("tguion",tgft.uion);
RegisterUserCommand("tguioff",tgft.uioff);

-------------------------------------------------------
-- Commands the user can use in quotes
-------------------------------------------------------
RegisterUserCommand("search",tgft.SearchItems);
RegisterUserCommand("botsearch",tgft.SearchBots);
RegisterUserCommand("lowprice",tgft.LookupItemLow);
RegisterUserCommand("highprice",tgft.LookupItemHigh);
RegisterUserCommand("mydent", tgft.FindDent);
RegisterUserCommand("alertenter",tgft.ToggleAlertEnter);
RegisterUserCommand("alertleave",tgft.ToggleAlertLeave);
RegisterUserCommand("stations",tgft.Stations);
RegisterUserCommand("players",tgft.Lastseen);
RegisterUserCommand("altfinder",tgft.Altfinder);
RegisterUserCommand("lastdata",tgft.LastSeenData);

RegisterUserCommand("idebug", debugtoggle);
RegisterUserCommand("guilditem", tgft.GuildItem);
RegisterUserCommand("lowsystem",tgft.LookupItemLowSystem);
RegisterUserCommand("highsystem",tgft.LookupItemHighSystem);

RegisterUserCommand("autounload",tgft.Unload);
RegisterUserCommand("hostile",tgft.Hostile);
RegisterUserCommand("app",tgft.App);
RegisterUserCommand("turbotoggle",turbotoggle);
RegisterUserCommand("launch",tgft.launch);
RegisterUserCommand("init",tgft.Init);
RegisterUserCommand("tgft",tgft.Help);

RegisterUserCommand("bindsave",tgft.BindSave);
RegisterUserCommand("alarm",tgft.watchtoggle);
RegisterUserCommand("saveplot",tgft.saveplot);
RegisterUserCommand("plot",tgft.plot);

-------------------------------------------------------
-- Roid Already in list?
-------------------------------------------------------
function tgft.InRoid(TheID)
local roiddata
	for i = 1, #tgft.roids, 1 do
		if (tgft.roids[i][1] == TheID) then return true end
	end
	return false
end

-------------------------------------------------------
-- Roid Scanner
-------------------------------------------------------
function tgft.roidscanned(event,desc,xnum,roidnum)
if string.find(desc,"Object too far to scan") ~= nil then return end
if (tgft.username == nil or tgft.username == '' or (string.len(tgft.username)<1)) then
	tgft.Init()
	end

local s
local minerals = {}
while (string.len(desc)>0) do
	s = string.sub(desc,1,string.find(desc, "\n")-1)
	desc = string.sub(desc,string.find(desc, "\n")+1)
	if (not string.find(s,"Temper") and not string.find(s,"Mineral")) then
	table.insert(minerals,s)
	end
end

local Sector = GetCurrentSectorid()
local System = GetSystemID(Sector)
local UniqueID = Sector..":"..System..":"..roidnum
if (not tgft.InRoid(UniqueID)) then
	--print("Need to add the roid."..UniqueID)
	table.insert(tgft.roids,{UniqueID,minerals})
	--else print("Already have the roid."..UniqueID)
	end
LisaJunk=tgft.roids
end

-------------------------------------------------------
-- Roid Scanner
-------------------------------------------------------
function tgft.SendRoids()
if (#tgft.roids == 0) then return end
print("Sending Roids to server..."..#tgft.roids)
local senddata=json.encode(tgft.roids)
urlopen('http://www.tgft.org/vendetta/roiddata.php', 'POST',tgft.Server_Callback_Text, {username=tgft.username, passwd=tgft.passwd, data=senddata})
tgft.roids = {} -- Empty the list!
end

-------------------------------------------------------
-- register events
-------------------------------------------------------
RegisterEvent(tgft.Init1, "SECTOR_LOADED")
RegisterEvent(tgft.council, "UTILS_COUNCIL")
RegisterEvent(tgft.roidscanned, "TARGET_SCANNED")
RegisterUserCommand("sendroids",tgft.SendRoids);
RegisterEvent(tgft.SendRoids, "ENTERED_STATION")
