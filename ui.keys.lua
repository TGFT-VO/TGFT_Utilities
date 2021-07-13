local ui = {}

local help_text = 'Keys v'..LK.version..'\n'..
"\t Commands with (s) can take more than one at a time.\t* are retricted to admins.  They simply will do nothing if your character is not in the admin list..\n"..
--"/keys -aadmin username\t\t\t\t\t - * Grants the user permission to modify the user lists.\n"..
"/keys -addown username\t\t\t\t\t - Issues Owner keys to username.  * Also adds them to the Owner key list.\n"..
"/keys -adduser username(s)\t\t\t\t\t - Issues user keys to username.  Also adds them to the user key list.\n"..
--"/keys -addcmd 'some command goes here'\t\t - * Puts a command in the reminder queue.\n"..
--"/keys -addnokey keynum\t\t\t\t\t - Adds Owner key num to the restricted list. Owner keys to not be sent out.\n"..
--"/keys -cmds\t\t\t\t\t\t\t - Runs the commands listed in the queue.  See -listcmd.\n"..
--"/keys -delete keynum(s)\t\t\t\t\t - Deletes the keynum(s).\n"..
--"\t\t\t\t\t\t\t\t\t\t    Note: Delete the Owner key to delete the user key.\n"..
"/keys -guild\t\t\t\t\t\t\t - Issues keys to all on-line guild members and adds them to the user key list.\n"..
"/keys -list\t\t\t\t\t\t\t\t - Lists all keys and their numbers.\n"..
"/keys -listcmds\t\t\t\t\t\t\t - List Commands in the queue.\n"..
"/keys -listkey number\t\t\t\t\t\t - Lists all players that have the key.\n"..
"/keys -listnokeys\t\t\t\t\t\t - Lists keys that are restricted (Your Capship Owner key should be in this list)\n"..
"/keys -listown\t\t\t\t\t\t\t - Lists all your owner keys.\n"..
"/keys -listuser\t\t\t\t\t\t\t - Lists all your user keys.\n"..
--"/keys -purge\t\t\t\t\t\t\t - Purge old user keys that are inactive.\n"..
"/keys -reload\t\t\t\t\t\t\t - Reloads interface ReloadInterface().\n"..
--"/keys -remcmd num\t\t\t\t\t\t - Removes a command from the queue by number.  See -listcmd.\n"..
--"/keys -remnokey\t\t\t\t\t\t - Removes a key from the resticted list.\n"..
"/keys -remove username\t\t\t\t\t - * Removes a user from the user and owner key lists.  Does not revoke keys.\n"..
"/keys -revoke username\t\t\t\t\t - Revokes all user keys from username.  Removes user from both user key list, and Owner key list.\n"..
"/keys -revokeall keynum\t\t\t\t\t - Revokes all users from keynum.  Good for cleaning a key.  Does not remove them from the key lists.\n"..
"/keys -saved\t\t\t\t\t\t\t - Issues keys to all in the saved lists.  User keys to user list, and owner keys to Owner list.\n"..
--"/keys -setpass password\t\t\t\t\t - Sets your password for server access.\n"..
"/keys -show\t\t\t\t\t\t\t - Show saved list of users.  Both users and owners.\n"..
"/keys -ver\t\t\t\t\t\t\t\t - Displays the current version.\n\n"..
"/keystat\t\t\t\t\t\t\t\t - Show keys we have now.  Short version is /ks\n"
--"/scannpc\t\t\t\t\t\t\t\t - Displays info on the npc you have targetd."

	
	
function ui:ShowHelp()
	StationHelpDialog:Open(help_text)
end

function ui:ShowOutput(data)
	StationHelpDialog:Open(data)
end

	local button_help = iup.stationbutton{title="Help", hotkey=iup.K_h, action=ui.ShowHelp}
	local button_ok = iup.stationbutton{title="OK"}
	
	local frame = iup.vbox{
		iup.hbox{iup.fill{}, iup.label{title="Keys v"..LK.version,font=Font.H3}, iup.fill{}},
		iup.fill{size=10},
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
						frame,
						expand="NO",
						gap=8,
					},
				},
				iup.fill{},
			},
			iup.fill{},
		},
		BGCOLOR = "0 0 0 160 *",
		FULLSCREEN="YES",
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
	
	function button_ok.action() ui.Hide(button_ok) end
	return ui
		
