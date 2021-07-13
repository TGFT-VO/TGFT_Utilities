--[[
TCFT2
(c) By Plozi
Version 1.0.0

Based on the original TCFT made by Moda

** Changelog

]]

datacol.Connection = {}

-- Socket callback handlers
-- Connection
datacol.Connection.connect = function(sock,errmsg)
	if (sock) then
		datacol.Connection.PeerName = sock.tcp:GetPeerName()
		if (datacol.Connection.PeerName ~= nil) then
			datacol.Connection.isConnected = true
			print("Connected 001...")

			datacol.Connection.isLoggedin = false
			datacol.Connection.Socket = sock.tcp
			datacol.Connection.Send = sock.Send
			--datacol.SendData({ cmd="100", username=datacol.Settings.Data.username, password=datacol.Settings.Data.password, idstring=datacol.IdString })
		else 
			datacol.Connection.isLoggedin = false
			datacol.Connection.isConnected = false
			--datacol.AddStatus(datacol.colors.GREEN2 .. "(TCFT2) " .. datacol.colors.RED .. "Connection to server failed.", true)
			print("Connection to server failed.")
			if (errmsg) then
				print("Error: " .. errmsg)
				--datacol.AddStatus(datacol.colors.GREEN2 .. "(TCFT2) " .. datacol.colors.RED .. "Error: " .. errmsg)
			else
				print("Unknown error: ")
				--datacol.AddStatus(datacol.colors.GREEN2 .. "(TCFT2) " .. datacol.colors.RED .. "Unknown error.")
			end
		end
	else
		datacol.Connection.isLoggedin = false
		datacol.Connection.isConnected = false
		print("Connection to server failed.")
		if (errmsg) then
			--datacol.AddStatus(datacol.colors.GREEN2 .. "(TCFT2) " .. datacol.colors.RED .. "Error: " .. errmsg)
			print("Error: " .. errmsg)
		else
			print("Unknown error: ")
			--datacol.AddStatus(datacol.colors.GREEN2 .. "(TCFT2) " .. datacol.colors.RED .. "Unknown error.")
		end
	end
end

-- Server close the connection... or lines are down
datacol.Connection.disconnect = function()
	datacol.Connection.isConnected = false
	datacol.Connection.isLoggedin = false
	print("Disconnected 003...")
	--datacol.AddStatus(datacol.colors.GREEN2 .. "(TCFT2) " .. datacol.colors.RED.."Connection to server lost.", true)
	--datacol.SetStatusLine(datacol.colors.RED .. "Not connected to server")
	--datacol.connectButton.title = "Connect"
end

-- Receive data
datacol.Connection.getline = function(sock, line)
	line = string.gsub(line,"[\r\n]","")
	--if (datacol.debug==1) then datacol.AddStatus(datacol.colors.YELLOW..'<<< ' .. line) end
	local data = json.decode(line)
	local cmd = tonumber(data.cmd)
	if (cmd>0) then
		local evtparams = data
		if (datacol.Events[cmd]) then
			--if (datacol.debug==1) then datacol.AddStatus(datacol.colors.YELLOW .. "Received Event from server: " .. cmd) end
			--datacol.Events[cmd](evtparams)
			print("Error: " .. cmd)
		else
			--datacol.AddStatus(datacol.colors.RED .. 'Unknown Event from server: ' .. cmd)
			print("Unknown event: ".. cmd)
		end
	else
		if Line ~= '' then
			local length = string.len(Line);
			print('Invalid Event from server, '..length..' characters: >'..Line..'<')
		end
	end
end

-- Check connection - try connect if disconnected or disconnect if connected
datacol.Connection.CheckConnection = function()
	if (datacol.Connection.isConnected) then
		--SetShipPurchaseColor(229)
		--datacol.SendData({ cmd="101" })
		datacol.Connection.Socket:Disconnect()
		print("Disconnected 001...")
		datacol.Connection.Socket = nil
		datacol.Connection.isConnected = false
		datacol.Connection.isLoggedin = false
		--datacol.connectButton.title = "Connect"
		--datacol.SetStatusLine(datacol.colors.RED .. "Not Connected to the server.")
		--datacol.AddStatus(datacol.colors.GREEN2 .. "(TCFT2) " .. datacol.colors.RED .. "Connection to server closed.", true)
	else
		datacol.Connection.Socket = TCP.make_client(datacol.Server,27056,datacol.Connection.connect,datacol.Connection.getline,datacol.Connection.disconnect)
	end
end

-- Clean up the connection
datacol.Connection.CleanUp = function()
	if (datacol.Connection.isConnected) then
		--datacol.SendData({ cmd="101" })
		datacol.Connection.Socket:Disconnect()
		print("Disconnected 002...")
		datacol.Connection.isConnected = false
		datacol.Connection.isLoggedin = false
	end
end

