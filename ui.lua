require( "iuplua" )
require( "iupluacontrols" )
local ui = {}

local help_text = 'Utilities v'..tgft.version..'\n'..
"-- Networking functions are turned off by default in this version.\n"..
"-- To enable them, use /tgftnet.\n"..
"-- As of version 2.02, your setting for networking will saved between sessions.\n\n"..
"\t This is a plugin created by Lisa201 of TGFT, and everyone is free to use it.\n"..
"\t Do not run this plugin if you believe it's risks outweight it's benefit.\n"..
"\t In searches, you can use the wildcard symbol which is the %.  Such as /search Neutron blaster%\n"..
"\t Price data for buying and selling goods in VO is sent to the server and accessed with the price functions below.\n"..
"\t Bot data is saved, and also sector info like storms and if the sector has roids.\n"..
"\t To toggle all network functions, use /tgftnet.\n\n"..
"\t Disclaimer: With networking on: Collects and transmits data on sectors, players that you encounter and price data for items in stations.\n"..
"\t Data translated is not anonymous and will provide information about your location and those around you to TGFT.\n"..
"\t Analysis of this data could reveal sensitive details about your characters movements, travel companions,\n"..
"\t and be used to identify alternate characters.\n"..
"alarm\t\t\tToggles the reporting of your Trident attacks to guild chat.\n" ..
--"alertenterleave\t\tToggles the reporting of all players entering or leaving sector.\n"..
"autounload\t\tToggle auto-unloading.  Used to drop cargo in a station fast, unloads, then launches your ship.\n"..
"\t\t\tCan be useful for station takes when reloading in a trident.  It will launch you as soon as you dock.\n"..
"mydent\t\tPlot to the sector that your Trident is parked in.\n" ..
"turbotoggle\tToggle turbo on and off.  Use a bind such as /bind T turbotoggle\n"..
"launch\t\tLaunch your ship.  Bind it with /bind L launch\n"..
"tgft_init\t\tRe-Initialize the plugin.\n"..
"bindsave\t\tTells VO to save the binds you have in place.\n"..
"\n-- Functions below this are only available with networking turned on --\n"..
"search\t\tSearch for Items in VO.  /search tiles | /search neutron\n"..
"botsearch\t\tSearch for locations of bots.  /botsearch kannik | /botsearch guardian\n"..
'lowprice\t\tLookup lowest price of items.  /lowprice plasteel | /lowprice "phase blaster"\n'..
'highprice\t\tLookup highest price of items.  /highprice plasteel | /highprice "phase blaster"\n'..
"stations\t\tSearch Stations.  /stations dau | /stations biocom | /stations Orbital\n"..
'players\t\tList where a player was seen.  /players lisa | /players edras | players "latos h-2" | /players famy\n'..
"\n-- *The following commands are restricted to TGFT guild members only *. --\n"..
'lowsystem\t\tLookup lowest price of items in a system.  /lowprice plasteel dau | /lowprice "phase blaster" nyrius\n'..
'highsystem\t\tLookup highest price of items in a system.  /highprice plasteel dau | /highprice "phase blaster" nyrius\n'..
"hostile\t\tAdd or remove a person/guild to our hostile list.\n"..
"app\t\t\tAdd or remove a  person from out applicants list.\n"..
"\t\t\tAdd a player to the applicants list:  /app + theplayer\n"..
"\t\t\tMark a player as ready for Interview:  /app i theplayer\n"..
"\t\t\tMark a player as a probie:  /app p theplayer\n"..
"\t\t\tRemove a player from the app list:  /app - theplayer\n"..
"guilditem\t\tUpdate the list of items available to other guild members.\n"

function ui:ShowHelp()
	StationHelpDialog:Open(help_text)
end

function ui:ShowOutput(data)
	StationHelpDialog:Open(data)
end

local button_help = iup.stationbutton{title="Help", hotkey=iup.K_h, action=ui.ShowHelp}
local button_ok = iup.stationbutton{title="OK"}
	
local lisaframe = iup.vbox{
	iup.hbox{iup.fill{}, iup.label{title="TGFT Utilities "..tgft.version,font=Font.H3}, iup.fill{}},
	iup.fill{size=20},
	iup.hbox{iup.fill{size=12}, options_box, iup.fill{}, gap=8},
	iup.fill{size=8},
	iup.hbox{button_help, iup.fill{}, button_ok, gap=8},
	alignment="ACENTER",
}
	
	-- Create Dialog --
ui.dialog = iup.dialog{
	iup.vbox{
		iup.fill{},
		iup.hbox{
			iup.fill{},
			iup.stationhighopacityframe{
				iup.stationhighopacityframebg{
					lisaframe,
					expand="NO",
					gap=8,
				},
			},
			iup.fill{},
		},
		iup.fill{},
	},
	BGCOLOR = "0 0 0 160 *",
	FULLSCREEN="NO",
	RESIZE="NO",
	BORDER="NO",
	MENUBOX="YES",
	TOPMOST="YES",
	DEFAULTESC=button_ok,
	DEFAULTENTER=button_ok,
}

ui.dialog:map()
	
function ui:Show()
	ui.Update(self) --reset control values in case of changed by console
	ShowDialog(ui.dialog,iup.CENTER,iup.CENTER)
	iup.Refresh(ui.dialog)
end
	
	--capture state of controls and save to config
function ui:Hide()
	HideDialog(ui.dialog)
end
	
function button_ok.action() 
	ui.Hide(button_ok) 
end

return ui
		
