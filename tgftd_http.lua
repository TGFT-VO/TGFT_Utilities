declare('TGFTD', {})
user_agent = "TGFT Data Client"

local wanted_headers = {
    location="Location",
    poweredby="X-Powered-By",
    contenttype="Content-type",
    server="Server",
}

local function unescape (s)
    s = string.gsub(s, "+", " ")
    s = string.gsub(s, "%%(%x%x)", function (h)
        return string.char(tonumber(h, 16))
    end)
    return s
end

local function escape (s)
    s = string.gsub(s, "([&=+%c])", function (c)
        return string.format("%%%02X", string.byte(c))
    end)
    s = string.gsub(s, " ", "+")
    return s
end

local function encode (t)
    local s = ""
    for k,v in pairs(t) do
        s = s .. "&" .. escape(k) .. "=" .. escape(v)
    end
    return string.sub(s, 2)     -- remove first `&'
end

local function decode (s)
    local cgi = {}
    for name, value in string.gfind(s, "([^&=]+)=([^&=]+)") do
        name = unescape(name)
        value = unescape(value)
        cgi[name] = value
    end
    return cgi
end

--function K_HTTP.urlopen (url, method, callback, postdata)
function urlopen (url, method, callback, postdata)
    local body = ""
    local header = {}
    header.status = false
    local buffer = ""
    local to_body = false
    local active = false
    local appended = false
    local _, host, path, sock, type, length, rest
    local port = 80
    local gotit = false
    local nolen = false
    local postthis = ""
    if (method == nil) then method = "GET" end

    if not (string.find(url, "http://(.-)/(.*)$")) then url = url..'/' end
    _,_,host,path = string.find(url, "http://(.-)/(.*)$")
    if string.find(host, ':') then
        _, _, host, port = string.find(host, "(.*):(.*)$")
        port = tonumber(port)
    end

    local function callcallback(suc, hd, pg)
        active = false
        if (sock) and (sock.tcp) then
            sock.tcp:Disconnect()
        end
        sock = nil
        if not (callback == nil) then
            return callback(suc, hd, pg)
        end
    end

    if not (postdata == nil) then
        postthis = encode(postdata)
        if (method == "GET") then
            path = path.."?"..postthis
        end
    elseif method == "POST" then
        return callback("I need something to post", nil, nil)
    end

    local request = ""
    request = request..method.." /"..path.." HTTP/1.1\r\n"
    request = request.."Host: "..host..":"..tostring(port).."\r\n"
    request = request.."User-Agent: "..user_agent.."\r\n"
    request = request.."Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5\r\n"
    request = request.."Accept-Language: en-us,en;q=0.5\r\n"
    request = request.."Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n"
    request = request.."Connection: close\r\n"

    if method == "POST" then
        request = request.."Content-Type: application/x-www-form-urlencoded\r\n"
        request = request.."Content-Length: "..string.len(postthis).."\r\n"
        request = request.."\r\n"..postthis
    else
        request = request.."\r\n"
    end

    local function ConnectionTimeOut()
        if active and sock then
            return callcallback("Connection timed out", nil, nil)
        end
    end

    local function ConnectionMade(con, suc)
        if not (suc == nil) then
            return callcallback(suc, nil, nil)
        else
            con:Send(request)
            local t = Timer()
            active = true
            t:SetTimeout(15000, ConnectionTimeOut)
        end
    end
    local function LineReceived(con, line)

        if line == '\r' then
      to_body = true
        end
        if not header.status and string.find(line, "^HTTP") then
            header.status = tonumber(string.sub(line, 10, 10+3))
        end

        if to_body then
            body = body..line..'\n'
            local curlen = string.len(body)
            if not (length == nil) then
                if curlen == length or curlen > length or length == 0 then
                    gotit = true
                    return callcallback(false, header, body)
                end
            else
                if not nolen then
                    print('-- don\'t know the length, waiting for the connection to get closed by the webserver')
                    nolen = true
                end
            end
        else
            local var, val
            _, _, var, val = string.find(line, "(.*): (.*)")
            if not (var == nil) and not (val == nil) then
                for wanted, real in pairs(wanted_headers) do
                    if var == real then
                        header[wanted] = val
                    end
                end
            end

            if string.find(line, "^Content(.*)Length") and length == nil then
                _, _, _, length = string.find(line, "Content(.*): (.*)$")
                length = tonumber(length)
            end
        end
    end
    
    local function ConnectionLost(con)
        print('Data Collector lost connection')
        if (header.status) then
            return callcallback(false, header, body)
        else
            return callcallback("Unknown error", nil, nil)
        end
    end
    sock = make_client(host, port, ConnectionMade, LineReceived, ConnectionLost)
end


--TCP = TCP or {}

-- This whole thing was written by Andy Sloane, a1k0n, one of the Vendetta
-- Online developers over at Guild Software
-- http://a1k0n.net/vendetta/lua/tcpstuff/
-- http://www.guildsoftware.com/company.html

--------------------------------------------------------------
local function SetupLineInputHandlers(conn, conn_handler, line_handler, disconn_handler)
  local buf = ''
  local match
  local connected

  conn.tcp:SetReadHandler(function()
    local msg, errcode = conn.tcp:Recv()
    if not msg then
      if not errcode then return end
      local err = conn.tcp:GetSocketError()
      conn.tcp:Disconnect()
      disconn_handler(conn)
      conn = nil
      return
    end
    buf = buf..msg
    repeat
      buf,match = string.gsub(buf, "^([^\n]*)\n", function(line)
        pcall(line_handler, conn, line)
        return ''
      end)
    until match==0
  end)

  local writeq = {}
  local qhead,qtail=1,1

  -- returns true if some data was written
  -- returns false if we need to schedule a write callback to write more data
  local write_line_of_data = function()
    --print(tostring(conn)..': sending  '..writeq[qtail])
    local bsent = conn.tcp:Send(writeq[qtail])
    -- if we sent a partial line, keep the rest of it in the queue
    if bsent == -1 then
      -- EWOULDBLOCK?  dunno if i can check for that
      return false
      --error(string.format("write(%q) failed!", writeq[qtail]))
    elseif bsent < string.len(writeq[qtail]) then
      -- consume partial line
      writeq[qtail] = string.sub(writeq[qtail], bsent+1, -1)
      return false
    end
    -- consume whole line
    writeq[qtail] = nil
    qtail = qtail + 1
    return true
  end
  
  -- returns true if all available data was written
  -- false if we need a subsequent write handler
  local write_available_data = function()
    while qhead ~= qtail do
      if not write_line_of_data() then
        return false
      end
    end
    qhead,qtail = 1,1
    return true
  end

  local writehandler = function()
    if write_available_data() then 
      conn.tcp:SetWriteHandler(nil)
    end
  end

--------------------------------------------------------------
  function conn:Send(line)
    --print(tostring(conn)..': queueing '..line)
    writeq[qhead] = line
    qhead = qhead + 1
    if not write_available_data() then
      conn.tcp:SetWriteHandler(writehandler)
    end
  end

  local connecthandler = function()
    conn.tcp:SetWriteHandler(writehandler)
    connected = true
--    local err = conn.tcp:GetSocketError()
--    if err then
--      if string.find(err,'WSAEWOULDBLOCK') then 
--        for count = 1,1000000 do end
--        err = conn.tcp:GetSocketError()
--      end
--    end
--    if err then 
----    if not string.find(err, "BLOCK") then
--      conn.tcp:Disconnect()
--      return conn_handler(nil, err)
--    end
    return conn_handler(conn)
  end

  conn.tcp:SetWriteHandler(connecthandler)
end

--------------------------------------------------------------
-- raw version
function make_client(host, port, conn_handler, line_handler, disconn_handler)
  local conn = {tcp=TCPSocket()}

  SetupLineInputHandlers(conn, conn_handler, line_handler, disconn_handler)

  local success,err = conn.tcp:Connect(host, port)
  if not success then return conn_handler(nil, err) end

  return conn
end

--------------------------------------------------------------
function make_server(port, conn_handler, line_handler, disconn_handler)
  local conn = TCPSocket()
  local connected = false
  local buf = ''
  local match

  conn:SetConnectHandler(function()
    local newconn = conn:Accept()
    print('Accepted connection '..newconn:GetPeerName())
    SetupLineInputHandlers({tcp=newconn}, conn_handler, line_handler, disconn_handler)
	end)
  local ok, err = conn:Listen(port)
  if not ok then error(err) end

  return conn
end

