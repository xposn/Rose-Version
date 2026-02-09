--[[
    SevereUI v6.0 - "Thug Sense" Style
    Drawing-based UI library for Severe external
    Dark / rose accent aesthetic matching Thug Sense
    Uses: Drawing API, getmouseposition(), isleftpressed(), getpressedkeys(), RunService.Render
    Global toggle: HOME key (keycode 36)
]]

----------------------------------------------------------------
-- THEME & LAYOUT
----------------------------------------------------------------

local COLORS = {
    accent     = Color3.fromRGB(200, 140, 140),
    accentHi   = Color3.fromRGB(230, 170, 170),
    accentDim  = Color3.fromRGB(140, 90, 90),
    text       = Color3.fromRGB(255, 255, 255),
    textSec    = Color3.fromRGB(180, 180, 180),
    bg         = Color3.fromRGB(15, 15, 15),
    surface    = Color3.fromRGB(30, 30, 30),
    surface2   = Color3.fromRGB(25, 25, 25),
    dark       = Color3.fromRGB(8, 8, 8),
    outer      = Color3.fromRGB(40, 40, 40),
    inner      = Color3.fromRGB(30, 30, 30),
    border     = Color3.fromRGB(5, 5, 5),
    inactive   = Color3.fromRGB(65, 65, 65),
    tabInact   = Color3.fromRGB(100, 100, 100),
    dim        = Color3.fromRGB(60, 60, 60),
    off        = Color3.fromRGB(30, 30, 30),
    danger     = Color3.fromRGB(255, 85, 85),
    success    = Color3.fromRGB(85, 230, 130),
    white      = Color3.fromRGB(255, 255, 255),
    black      = Color3.fromRGB(0, 0, 0),
    keyBg      = Color3.fromRGB(15, 15, 15),
    light      = Color3.fromRGB(30, 30, 30),
}

local LAYOUT = {
    font         = 0,
    fontSize     = 13,
    titleFont    = 13,
    titleH       = 30,
    tabH         = 28,
    tabW         = 80,
    rowH         = 20,
    rowGap       = 0,
    winPad       = 10,
    secPad       = 6,
    secGap       = 8,
    sliderH      = 6,
    headerH      = 28,
    configDir    = "SevereUI",
    configSub    = "SevereUI/Configs",
}

----------------------------------------------------------------
-- MATH HELPERS
----------------------------------------------------------------

local floor, max, min, abs, clk = math.floor, math.max, math.min, math.abs, os.clock

local function clamp(v, lo, hi) return max(lo, min(hi, v)) end

local function round(n, decimals)
    if decimals == 0 then return floor(n + 0.5) end
    local m = 10 ^ decimals
    return floor(n * m + 0.5) / m
end

local function lerp(a, b, t) return a + (b - a) * t end

local function lerpC3(a, b, t)
    return Color3.new(lerp(a.R, b.R, t), lerp(a.G, b.G, t), lerp(a.B, b.B, t))
end

local function hsvToC3(h, s, v)
    local c = v * s
    local x = c * (1 - abs(((h * 6) % 2) - 1))
    local m = v - c
    local r, g, b = 0, 0, 0
    if     h < 1/6 then r, g, b = c, x, 0
    elseif h < 2/6 then r, g, b = x, c, 0
    elseif h < 3/6 then r, g, b = 0, c, x
    elseif h < 4/6 then r, g, b = 0, x, c
    elseif h < 5/6 then r, g, b = x, 0, c
    else                 r, g, b = c, 0, x end
    return Color3.new(r + m, g + m, b + m)
end

local function c3ToHSV(c)
    local r, g, b = c.R, c.G, c.B
    local hi, lo = max(r, g, b), min(r, g, b)
    local delta = hi - lo
    local h = 0
    if delta > 0 then
        if hi == r then     h = ((g - b) / delta) % 6
        elseif hi == g then h = (b - r) / delta + 2
        else                h = (r - g) / delta + 4 end
        h = h / 6
    end
    local s = (hi == 0) and 0 or (delta / hi)
    return h, s, hi
end

local function inRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

local function textWidth(str)
    return #str * LAYOUT.fontSize * 0.55
end

local function safeCall(fn, ...)
    if fn then
        local success, err = pcall(fn, ...)
        if not success then
            warn("[SevereUI] Callback error:", err)
        end
    end
end

----------------------------------------------------------------
-- KEY MAPS
----------------------------------------------------------------

local KEY_DISPLAY = {
    [8]="BS",[9]="TAB",[13]="ENT",[27]="ESC",[32]="SPC",
    [33]="PGUP",[34]="PGDN",[35]="END",[36]="HOME",
    [37]="LEFT",[38]="UP",[39]="RIGHT",[40]="DOWN",
    [45]="INS",[46]="DEL",
    [65]="A",[66]="B",[67]="C",[68]="D",[69]="E",[70]="F",[71]="G",
    [72]="H",[73]="I",[74]="J",[75]="K",[76]="L",[77]="M",[78]="N",
    [79]="O",[80]="P",[81]="Q",[82]="R",[83]="S",[84]="T",[85]="U",
    [86]="V",[87]="W",[88]="X",[89]="Y",[90]="Z",
    [48]="0",[49]="1",[50]="2",[51]="3",[52]="4",
    [53]="5",[54]="6",[55]="7",[56]="8",[57]="9",
    [112]="F1",[113]="F2",[114]="F3",[115]="F4",[116]="F5",[117]="F6",
    [118]="F7",[119]="F8",[120]="F9",[121]="F10",[122]="F11",[123]="F12",
    [160]="LSHIFT",[161]="RSHIFT",[162]="LCTRL",[163]="RCTRL",[164]="LALT",[165]="RALT",
    [186]=";",[187]="=",[188]=",",[189]="-",[190]=".",[191]="/",
    [192]="`",[219]="[",[220]="\\",[221]="]",[222]="'",
}

-- Name-based key char maps (works with Enum.KeyCode.Name)
local KEY_NAME_CHAR = {
    A="a",B="b",C="c",D="d",E="e",F="f",G="g",
    H="h",I="i",J="j",K="k",L="l",M="m",N="n",
    O="o",P="p",Q="q",R="r",S="s",T="t",U="u",
    V="v",W="w",X="x",Y="y",Z="z",
    Zero="0",One="1",Two="2",Three="3",Four="4",
    Five="5",Six="6",Seven="7",Eight="8",Nine="9",
    Space=" ",Semicolon=";",Equals="=",Comma=",",Minus="-",Period=".",
    Slash="/",BackQuote="`",LeftBracket="[",BackSlash="\\",RightBracket="]",Quote="'",
}
local KEY_NAME_CHAR_UPPER = {
    A="A",B="B",C="C",D="D",E="E",F="F",G="G",
    H="H",I="I",J="J",K="K",L="L",M="M",N="N",
    O="O",P="P",Q="Q",R="R",S="S",T="T",U="U",
    V="V",W="W",X="X",Y="Y",Z="Z",
    Zero=")",One="!",Two="@",Three="#",Four="$",
    Five="%",Six="^",Seven="&",Eight="*",Nine="(",
    Space=" ",Semicolon=":",Equals="+",Comma="<",Minus="_",Period=">",
    Slash="?",BackQuote="~",LeftBracket="{",BackSlash="|",RightBracket="}",Quote="\"",
}
-- Integer-based fallback (Windows VK codes, some executors use these)
local KEY_CHAR = {
    [65]="a",[66]="b",[67]="c",[68]="d",[69]="e",[70]="f",[71]="g",
    [72]="h",[73]="i",[74]="j",[75]="k",[76]="l",[77]="m",[78]="n",
    [79]="o",[80]="p",[81]="q",[82]="r",[83]="s",[84]="t",[85]="u",
    [86]="v",[87]="w",[88]="x",[89]="y",[90]="z",
    [48]="0",[49]="1",[50]="2",[51]="3",[52]="4",
    [53]="5",[54]="6",[55]="7",[56]="8",[57]="9",
    [32]=" ",[186]=";",[187]="=",[188]=",",[189]="-",[190]=".",
    [191]="/",[192]="`",[219]="[",[220]="\\",[221]="]",[222]="'",
}
local KEY_CHAR_UPPER = {
    [65]="A",[66]="B",[67]="C",[68]="D",[69]="E",[70]="F",[71]="G",
    [72]="H",[73]="I",[74]="J",[75]="K",[76]="L",[77]="M",[78]="N",
    [79]="O",[80]="P",[81]="Q",[82]="R",[83]="S",[84]="T",[85]="U",
    [86]="V",[87]="W",[88]="X",[89]="Y",[90]="Z",
    [48]=")",[49]="!",[50]="@",[51]="#",[52]="$",
    [53]="%",[54]="^",[55]="&",[56]="*",[57]="(",
    [32]=" ",[186]=":",[187]="+",[188]="<",[189]="_",[190]=">",
    [191]="?",[192]="~",[219]="{",[220]="|",[221]="}",[222]="\"",
}

-- Resolve a key code to { char, upperChar, isBackspace, isEnter, isShift }
-- Get a canonical string name from any key code format (string, Enum.KeyCode, or integer)
local function keyToName(code)
    if type(code) == "string" then return code end
    if type(code) ~= "number" then
        local ok, n = pcall(function() return code.Name end)
        if ok and type(n) == "string" then return n end
        local s = tostring(code)
        if s then
            local last = s:match("%.(%w+)$")
            if last then return last end
        end
        return nil
    end
    -- Integer to name mapping
    local INT_TO_NAME = {
        [8]="Backspace",[13]="Return",[32]="Space",
        [160]="LeftShift",[161]="RightShift",[162]="LeftControl",[163]="RightControl",
        [164]="LeftAlt",[165]="RightAlt",[36]="Home",
        [65]="A",[66]="B",[67]="C",[68]="D",[69]="E",[70]="F",[71]="G",
        [72]="H",[73]="I",[74]="J",[75]="K",[76]="L",[77]="M",[78]="N",
        [79]="O",[80]="P",[81]="Q",[82]="R",[83]="S",[84]="T",[85]="U",
        [86]="V",[87]="W",[88]="X",[89]="Y",[90]="Z",
        [48]="Zero",[49]="One",[50]="Two",[51]="Three",[52]="Four",
        [53]="Five",[54]="Six",[55]="Seven",[56]="Eight",[57]="Nine",
    }
    return INT_TO_NAME[code]
end

-- Resolve a key code to { char, upperChar, isBackspace, isEnter, isShift }
local function resolveKey(code)
    local name = keyToName(code)
    if name then
        if name == "Backspace" or name == "Back" then return { isBackspace = true } end
        if name == "Return" or name == "Enter" then return { isEnter = true } end
        if name == "LeftShift" or name == "RightShift" then return { isShift = true } end
        local c = KEY_NAME_CHAR[name]
        if c then return { char = c, upperChar = KEY_NAME_CHAR_UPPER[name] } end
    end
    -- Integer fallback for Roblox enum values (97-122 = a-z)
    if type(code) == "number" then
        if code >= 97 and code <= 122 then
            local letter = string.char(code)
            return { char = letter, upperChar = letter:upper() }
        end
        if code >= 48 and code <= 57 then
            local digit = string.char(code)
            local shiftDigits = { ["0"]=")", ["1"]="!", ["2"]="@", ["3"]="#", ["4"]="$", ["5"]="%", ["6"]="^", ["7"]="&", ["8"]="*", ["9"]="(" }
            return { char = digit, upperChar = shiftDigits[digit] or digit }
        end
        if code == 32 then return { char = " ", upperChar = " " } end
    end
    return nil
end

----------------------------------------------------------------
-- DRAWING LAYER
----------------------------------------------------------------

local REFRESH_KEYS = {"Text","Size","Position","Color","Font","Filled","Thickness","ZIndex","Radius","PointA","PointB","PointC","Transparency"}

local function makeObj(kind, props)
    local raw = Drawing.new(kind)
    local cache = {}
    for k, v in pairs(props) do
        raw[k] = v
        cache[k] = v
    end
    return { raw = raw, cache = cache }
end

local function setProp(obj, k, v)
    if not obj then return end
    obj.raw[k] = v
    obj.cache[k] = v
end

local function setVisible(obj, vis)
    if not obj then return end
    if vis then
        for _, k in ipairs(REFRESH_KEYS) do
            if obj.cache[k] ~= nil then obj.raw[k] = obj.cache[k] end
        end
    end
    obj.raw.Visible = vis
end

local function removeObj(obj)
    if obj then pcall(function() obj.raw:Remove() end) end
end

local function bulkVisible(list, vis)
    for _, o in pairs(list) do
        if type(o) == "table" and o.raw then
            setVisible(o, vis)
        end
    end
end

----------------------------------------------------------------
-- INPUT
----------------------------------------------------------------

local mouse = { x = 0, y = 0, down = false, prev = false, rightDown = false, rightPrev = false, keys = {} }

local function pollInput()
    local mp = getmouseposition()
    mouse.x, mouse.y = mp.X, mp.Y
    mouse.prev = mouse.down
    mouse.down = isleftpressed()
    mouse.rightPrev = mouse.rightDown
    mouse.rightDown = isrightpressed()
    mouse.keys = getpressedkeys()
end

local function justClicked()       return mouse.down and not mouse.prev end
local function justReleased()      return not mouse.down and mouse.prev end
local function isHeld()            return mouse.down end
local function justRightClicked()  return mouse.rightDown and not mouse.rightPrev end
local function keyDisplayName(code)
    if code == nil then return "NONE" end
    if KEY_DISPLAY[code] then return KEY_DISPLAY[code] end
    local ok, name = pcall(function() return code.Name end)
    if ok and type(name) == "string" then return name end
    local s = tostring(code)
    if s and #s < 20 then return s end
    return "?"
end
local function isKeyHeld(code)
    if code == nil then return false end
    local codeName = keyToName(code)
    for _, k in ipairs(mouse.keys) do
        -- Direct equality
        if k == code then return true end
        -- Name-based comparison (handles string/Enum/int cross-type)
        if codeName then
            local kName = keyToName(k)
            if kName and kName == codeName then return true end
        end
    end
    return false
end
local function isShiftHeld()
    for _, k in ipairs(mouse.keys) do
        local r = resolveKey(k)
        if r and r.isShift then return true end
    end
    return false
end

----------------------------------------------------------------
-- ANIMATION ENGINE
----------------------------------------------------------------

local activeAnims = {}

local function animate(obj, duration, targets)
    if not obj then return end
    for i = #activeAnims, 1, -1 do
        if activeAnims[i].obj == obj then
            local dominated = true
            for k in pairs(activeAnims[i].to) do
                if not targets[k] then dominated = false; break end
            end
            if dominated then table.remove(activeAnims, i) end
        end
    end
    local from = {}
    for k, v in pairs(targets) do
        from[k] = obj.cache[k] or v
    end
    activeAnims[#activeAnims + 1] = { obj = obj, t0 = clk(), dur = duration, from = from, to = targets }
end

local function tickAnims()
    local now = clk()
    for i = #activeAnims, 1, -1 do
        local a = activeAnims[i]
        local t = clamp((now - a.t0) / a.dur, 0, 1)
        t = 1 - (1 - t) ^ 3
        for k, target in pairs(a.to) do
            if type(target) == "number" then
                setProp(a.obj, k, lerp(a.from[k], target, t))
            else
                setProp(a.obj, k, lerpC3(a.from[k], target, t))
            end
        end
        if t >= 1 then table.remove(activeAnims, i) end
    end
end

----------------------------------------------------------------
-- LIBRARY ROOT
----------------------------------------------------------------

local Lib = {
    Windows          = {},
    Flags            = {},
    SetFlags         = {},
    Folders          = { Root = LAYOUT.configDir, Configs = LAYOUT.configSub },
    _notifList       = {},
    _watermark       = nil,
    _keybindOverlay  = nil,
    _kbOverlayEnabled = true,
    _shown           = true,
    _prevHome        = false,
    _running         = false,
    _renderConn      = nil,
    _openDropdown    = nil,
    _openColorpicker = nil,
    _keybinds        = {},
    _screenW         = 1920,
    _screenH         = 1080,
}

pcall(function()
    if not isfolder(LAYOUT.configDir) then makefolder(LAYOUT.configDir) end
    if not isfolder(LAYOUT.configSub) then makefolder(LAYOUT.configSub) end
end)

----------------------------------------------------------------
-- CONFIG SYSTEM
----------------------------------------------------------------

-- Simple JSON encoder fallback
local function simpleJSONEncode(tbl)
    local result = "{"
    local first = true
    for k, v in pairs(tbl) do
        if not first then result = result .. "," end
        first = false
        local key = type(k) == "string" and ('"' .. k .. '"') or tostring(k)
        local val
        if type(v) == "string" then
            val = '"' .. v:gsub('"', '\\"') .. '"'
        elseif type(v) == "number" or type(v) == "boolean" then
            val = tostring(v)
        elseif type(v) == "table" then
            val = simpleJSONEncode(v)
        else
            val = '"' .. tostring(v) .. '"'
        end
        result = result .. key .. ":" .. val
    end
    return result .. "}"
end

local function simpleJSONDecode(str)
    -- Very basic JSON parser - won't handle all cases but works for simple configs
    local result = {}
    for k, v in str:gmatch('"([^"]+)"%s*:%s*"([^"]*)"') do
        result[k] = v
    end
    for k, v in str:gmatch('"([^"]+)"%s*:%s*(%d+%.?%d*)') do
        result[k] = tonumber(v)
    end
    for k, v in str:gmatch('"([^"]+)"%s*:%s*(true)') do
        result[k] = true
    end
    for k, v in str:gmatch('"([^"]+)"%s*:%s*(false)') do
        result[k] = false
    end
    return result
end

function Lib:GetConfig()
    -- Use simple key=value format (more reliable than JSON)
    local lines = {}
    for k, v in pairs(self.Flags) do
        local t = type(v)
        local value
        if t == "string" then
            value = v
        elseif t == "number" or t == "boolean" then
            value = tostring(v)
        elseif t == "table" then
            -- Color3
            if type(v.R) == "number" and type(v.G) == "number" and type(v.B) == "number" then
                value = v.R .. "," .. v.G .. "," .. v.B
            end
        else
            -- Store keybinds as string names
            value = keyToName(v) or tostring(v)
        end
        if value then
            table.insert(lines, k .. "=" .. value)
        end
    end
    return table.concat(lines, "\n")
end

function Lib:LoadConfig(content)
    local data = {}
    for line in content:gmatch("[^\n]+") do
        local key, value = line:match("([^=]+)=(.+)")
        if key and value then
            -- Parse value types
            if value == "true" then
                data[key] = true
            elseif value == "false" then
                data[key] = false
            elseif value == "nil" then
                data[key] = nil
            elseif tonumber(value) then
                data[key] = tonumber(value)
            elseif value:match("^%d+%.?%d*,%d+%.?%d*,%d+%.?%d*$") then
                -- Color3
                local r, g, b = value:match("([^,]+),([^,]+),([^,]+)")
                data[key] = Color3.fromRGB(tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255)
            else
                -- String (including keybind names)
                data[key] = value
            end
        end
    end

    for k, v in pairs(data) do
        if self.SetFlags[k] then
            self.SetFlags[k](v)
        end
    end
end

function Lib:SaveConfig(filename)
    local path = self.Folders.Configs .. "/" .. filename
    local content = self:GetConfig()
    writefile(path, content)
    self:Notify("Config saved: " .. filename, 3, COLORS.accent)
end

function Lib:DeleteConfig(filename)
    local path = self.Folders.Configs .. "/" .. filename
    pcall(function()
        if isfile(path) then
            delfile(path)
            self:Notify("Deleted: " .. filename, 2, COLORS.accent)
        else
            self:Notify("Not found: " .. filename, 2, COLORS.accent)
        end
    end)
end

function Lib:ListConfigs()
    local files = {}
    pcall(function()
        local list = listfiles(self.Folders.Configs)
        for _, f in ipairs(list) do
            local name = f:match("([^/\\]+)$")
            if name and name:match("%.json$") then
                files[#files + 1] = name
            end
        end
    end)
    table.sort(files)
    return files
end

function Lib:SetAutoload(filename)
    pcall(function()
        local src = self.Folders.Configs .. "/" .. filename
        local dst = self.Folders.Configs .. "/autoload.json"
        if isfile(src) then
            writefile(dst, readfile(src))
            self:Notify("Autoload set: " .. filename, 2, COLORS.accent)
        end
    end)
end

function Lib:RemoveAutoload()
    pcall(function()
        local path = self.Folders.Configs .. "/autoload.json"
        if isfile(path) then
            delfile(path)
            self:Notify("Autoload removed", 2, COLORS.accent)
        end
    end)
end

function Lib:Init()
    pcall(function()
        local path = self.Folders.Configs .. "/autoload.json"
        if isfile(path) then self:LoadConfig(readfile(path)) end
    end)
end

----------------------------------------------------------------
-- NOTIFICATIONS (right side, slide in, progress bar)
----------------------------------------------------------------

local function tickNotifications(lib)
    local now = clk()
    local screenW = lib._screenW
    local alive = {}
    for _, n in ipairs(lib._notifList) do
        local elapsed = now - n.startTime
        if elapsed < n.duration then
            alive[#alive + 1] = n
        else
            removeObj(n.bg); removeObj(n.bgInner); removeObj(n.titleTx); removeObj(n.msgTx); removeObj(n.barBg); removeObj(n.barFill)
        end
    end
    lib._notifList = alive

    local nw = 250
    local nh = 65
    local gap = 8
    for i, n in ipairs(alive) do
        local elapsed = now - n.startTime
        local targetX = screenW - nw - 20
        local startX = screenW + 10
        local targetY = 100 + (i - 1) * (nh + gap)

        local x
        if elapsed < 0.3 then
            local t = clamp(elapsed / 0.3, 0, 1)
            t = 1 - (1 - t) ^ 3
            x = lerp(startX, targetX, t)
        elseif elapsed > n.duration - 0.3 then
            local fadeT = clamp((elapsed - (n.duration - 0.3)) / 0.3, 0, 1)
            x = lerp(targetX, startX, fadeT)
        else
            x = targetX
        end

        local prog = elapsed / n.duration
        local barW = max(0, (nw - 16) * (1 - prog))

        setProp(n.bg, "Position", Vector2.new(x - 1, targetY - 1))
        setProp(n.bg, "Size", Vector2.new(nw + 2, nh + 2))
        setProp(n.bgInner, "Position", Vector2.new(x, targetY))
        setProp(n.bgInner, "Size", Vector2.new(nw, nh))
        setProp(n.titleTx, "Position", Vector2.new(x + 12, targetY + 10))
        setProp(n.msgTx, "Position", Vector2.new(x + 12, targetY + 26))
        setProp(n.barBg, "Position", Vector2.new(x + 8, targetY + nh - 14))
        setProp(n.barBg, "Size", Vector2.new(nw - 16, 3))
        setProp(n.barFill, "Position", Vector2.new(x + 8, targetY + nh - 14))
        setProp(n.barFill, "Size", Vector2.new(barW, 3))
    end
end

function Lib:Notify(message, duration, color)
    duration = duration or 3
    color = color or COLORS.accent
    local startX = self._screenW + 10

    local n = {
        startTime = clk(),
        duration = duration,
        color = color,
        message = message,
        bg = makeObj("Square", { Size = Vector2.new(252, 67), Position = Vector2.new(startX, 0), Color = COLORS.dark, Filled = true, Visible = true, ZIndex = 200 }),
        bgInner = makeObj("Square", { Size = Vector2.new(250, 65), Position = Vector2.new(startX, 0), Color = COLORS.bg, Filled = true, Visible = true, ZIndex = 201 }),
        titleTx = makeObj("Text", { Text = "Config", Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(startX, 0), Visible = true, ZIndex = 203 }),
        msgTx = makeObj("Text", { Text = message, Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.textSec, Position = Vector2.new(startX, 0), Visible = true, ZIndex = 203 }),
        barBg = makeObj("Square", { Size = Vector2.new(234, 3), Position = Vector2.new(startX, 0), Color = COLORS.light, Filled = true, Visible = true, ZIndex = 202 }),
        barFill = makeObj("Square", { Size = Vector2.new(234, 3), Position = Vector2.new(startX, 0), Color = color, Filled = true, Visible = true, ZIndex = 203 }),
    }
    self._notifList[#self._notifList + 1] = n
end

----------------------------------------------------------------
-- WATERMARK (bracket style: [ name ])
----------------------------------------------------------------

function Lib:Watermark(opts)
    local txt = opts.Text or "SevereUI"

    local wm = {
        _text = txt,
        _rainbowEnabled = false,
        _rainHue = 0,
        _lastT = clk(),
        drawings = {},
    }

    local tw = textWidth(txt) + 16

    wm.drawings.bgOuter = makeObj("Square", { Size = Vector2.new(tw, 20), Position = Vector2.new(0, 0), Color = COLORS.surface, Filled = true, Visible = true, ZIndex = 190 })
    wm.drawings.bgInner = makeObj("Square", { Size = Vector2.new(tw - 2, 18), Position = Vector2.new(0, 0), Color = COLORS.bg, Filled = true, Visible = true, ZIndex = 191 })
    wm.drawings.nameTx = makeObj("Text", { Text = txt, Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.accent, Position = Vector2.new(0, 0), Center = true, Visible = true, ZIndex = 192 })

    local function repos(self2, lib)
        local tw = textWidth(self2._text) + 16
        local px = ((lib or Lib)._screenW - tw) / 2
        local py = 8
        setProp(self2.drawings.bgOuter, "Position", Vector2.new(px, py))
        setProp(self2.drawings.bgOuter, "Size", Vector2.new(tw, 20))
        setProp(self2.drawings.bgInner, "Position", Vector2.new(px + 1, py + 1))
        setProp(self2.drawings.bgInner, "Size", Vector2.new(tw - 2, 18))
        -- Center text in the box
        setProp(self2.drawings.nameTx, "Position", Vector2.new(px + tw / 2, py + 3))
    end

    repos(wm, Lib)

    function wm:SetText(t)
        self._text = t
        setProp(self.drawings.nameTx, "Text", t)
        repos(self, Lib)
    end

    function wm:SetVisible(v)
        bulkVisible(self.drawings, v)
    end

    function wm:update()
        repos(self, Lib)
        -- Rainbow name text effect
        if self._rainbowEnabled then
            local now = clk()
            self._rainHue = (self._rainHue + (now - self._lastT) * 0.3) % 1
            self._lastT = now
            -- Cycle through hue for accent-like rainbow
            local h = self._rainHue
            local r = math.sin(h * 2 * math.pi + 0) * 0.5 + 0.5
            local g = math.sin(h * 2 * math.pi + 2) * 0.5 + 0.5
            local b = math.sin(h * 2 * math.pi + 4) * 0.5 + 0.5
            setProp(self.drawings.nameTx, "Color", Color3.new(r, g, b))
        end
    end

    self._watermark = wm
    return wm
end

----------------------------------------------------------------
-- KEYBIND OVERLAY WINDOW (floating keybinds list)
----------------------------------------------------------------

local function tickKeybindOverlay(lib)
    if not lib._keybindOverlay then return end
    local ov = lib._keybindOverlay

    -- Hide everything if disabled
    if not lib._kbOverlayEnabled then
        bulkVisible(ov.drawings, false)
        for _, d in ipairs(ov.entryDrawings) do removeObj(d) end
        ov.entryDrawings = {}
        return
    end

    -- Collect all keybinds (skip hidden ones and Always mode)
    local allBinds = {}
    for _, kb in ipairs(lib._keybinds) do
        if kb.key and not kb._hideFromOverlay then
            local name = kb._kbOverlayName or kb._label or "Keybind"
            local keyStr = keyDisplayName(kb.key)
            local active = false

            if kb.mode == "Toggle" then
                active = kb.toggled
                allBinds[#allBinds + 1] = { name = name, key = keyStr, active = active }
            elseif kb.mode == "Hold" then
                active = kb:isBoundKeyHeld()
                -- Always show Hold keybinds, grey when not held
                allBinds[#allBinds + 1] = { name = name, key = keyStr, active = active }
            end
            -- Always mode keybinds are not shown in overlay
        end
    end

    local hasItems = #allBinds > 0
    local lineH = 13
    local titleH = 16
    local sepGap = 3
    local pad = 4
    -- Compute width from longest entry
    local maxTW = textWidth("keybinds") + 12
    for _, entry in ipairs(allBinds) do
        local tw = textWidth("(" .. entry.key .. ") " .. entry.name) + 12
        if tw > maxTW then maxTW = tw end
    end
    local boxW = max(maxTW + pad * 2, 90)
    local contentH = #allBinds * lineH
    local totalH = titleH + sepGap + contentH + pad

    -- Remove old entry drawings
    for _, d in ipairs(ov.entryDrawings) do removeObj(d) end
    ov.entryDrawings = {}

    if hasItems then
        bulkVisible(ov.drawings, true)
        local x = ov.x
        local y = ov.y
        setProp(ov.drawings.bgOuter, "Position", Vector2.new(x, y))
        setProp(ov.drawings.bgOuter, "Size", Vector2.new(boxW, totalH))
        setProp(ov.drawings.bgInner, "Position", Vector2.new(x + 1, y + 1))
        setProp(ov.drawings.bgInner, "Size", Vector2.new(boxW - 2, totalH - 2))
        setProp(ov.drawings.titleTx, "Position", Vector2.new(x + boxW / 2, y + 2))
        setProp(ov.drawings.sepLine, "Position", Vector2.new(x + pad, y + titleH))
        setProp(ov.drawings.sepLine, "Size", Vector2.new(boxW - pad * 2, 1))

        -- Draw entries centered, gray when off
        local ly = y + titleH + sepGap
        for _, entry in ipairs(allBinds) do
            local t = "(" .. entry.key .. ") " .. entry.name
            local tw = textWidth(t)
            local tx = x + (boxW - tw) / 2
            local col = entry.active and COLORS.text or COLORS.dim
            local td = makeObj("Text", { Text = t, Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = col, Position = Vector2.new(tx, ly), Visible = true, ZIndex = 182 })
            ov.entryDrawings[#ov.entryDrawings + 1] = td
            ly = ly + lineH
        end
    else
        bulkVisible(ov.drawings, false)
    end

    -- Drag handling (only when UI is shown)
    if hasItems and lib._shown then
        local x, y = ov.x, ov.y
        if inRect(mouse.x, mouse.y, x, y, boxW, titleH) and justClicked() then
            ov.dragging = true
            ov.dragOffX = mouse.x - x
            ov.dragOffY = mouse.y - y
        end
        if ov.dragging then
            if isHeld() then
                ov.x = mouse.x - ov.dragOffX
                ov.y = mouse.y - ov.dragOffY
            else
                ov.dragging = false
            end
        end
    else
        ov.dragging = false
    end
end

local function createKeybindOverlay(lib)
    local ov = {
        x = 30, y = 30,
        dragging = false,
        dragOffX = 0, dragOffY = 0,
        drawings = {},
        entryDrawings = {},
    }
    -- Simple 2-layer border: outer dark + inner bg (no list bg box, no extra layers)
    ov.drawings.bgOuter = makeObj("Square", { Size = Vector2.new(90, 30), Position = Vector2.new(30, 30), Color = COLORS.surface, Filled = true, Visible = false, ZIndex = 179 })
    ov.drawings.bgInner = makeObj("Square", { Size = Vector2.new(88, 28), Position = Vector2.new(31, 31), Color = COLORS.bg, Filled = true, Visible = false, ZIndex = 180 })
    ov.drawings.titleTx = makeObj("Text", { Text = "keybinds", Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(75, 32), Center = true, Visible = false, ZIndex = 182 })
    ov.drawings.sepLine = makeObj("Square", { Size = Vector2.new(82, 1), Position = Vector2.new(34, 46), Color = COLORS.accent, Filled = true, Visible = false, ZIndex = 181 })

    lib._keybindOverlay = ov
end

----------------------------------------------------------------
-- WINDOW (multi-layered nested borders, Thug Sense style)
----------------------------------------------------------------

function Lib:Window(opts)
    local w, h = opts.Size and opts.Size.X or 560, opts.Size and opts.Size.Y or 450
    local x, y = opts.Position and opts.Position.X or 100, opts.Position and opts.Position.Y or 100

    local win = {
        x = x, y = y, w = w, h = h,
        visible = true,
        dragging = false, dragX = 0, dragY = 0,
        pages = {},
        currentPage = nil,
        drawings = {},
        _tabAnimActive = false,
        _tabAnimStart = 0,
        _tabAnimFrom = 0,
        _tabAnimTo = 0,
        _tabAnimNow = 0,
        _tabAnimWidth = 0,
    }

    -- Title text above the layered border (like Thug Sense)
    win.drawings.titleTx = makeObj("Text", { Text = opts.Name or "Window", Size = LAYOUT.titleFont, Font = LAYOUT.font, Color = COLORS.textSec, Position = Vector2.new(x + 10, y - 16), Visible = true, ZIndex = 1 })
    -- Multi-layered borders (5 layers: dark -> outer -> secbg -> outer -> bg)
    win.drawings.layer1 = makeObj("Square", { Size = Vector2.new(w, h), Position = Vector2.new(x, y), Color = COLORS.dark, Filled = true, Visible = true, ZIndex = 1 })
    win.drawings.layer2 = makeObj("Square", { Size = Vector2.new(w - 2, h - 2), Position = Vector2.new(x + 1, y + 1), Color = COLORS.outer, Filled = true, Visible = true, ZIndex = 2 })
    win.drawings.layer3 = makeObj("Square", { Size = Vector2.new(w - 4, h - 4), Position = Vector2.new(x + 2, y + 2), Color = COLORS.surface, Filled = true, Visible = true, ZIndex = 3 })
    win.drawings.layer4 = makeObj("Square", { Size = Vector2.new(w - 6, h - 6), Position = Vector2.new(x + 3, y + 3), Color = COLORS.outer, Filled = true, Visible = true, ZIndex = 4 })
    win.drawings.layer5 = makeObj("Square", { Size = Vector2.new(w - 8, h - 8), Position = Vector2.new(x + 4, y + 4), Color = COLORS.bg, Filled = true, Visible = true, ZIndex = 5 })
    -- Accent underline for tabs (animated)
    win.drawings.tabLine = makeObj("Square", { Size = Vector2.new(80, 3), Position = Vector2.new(x + 14, y + 4 + LAYOUT.tabH + 2), Color = COLORS.accent, Filled = true, Visible = true, ZIndex = 8 })
    -- Content area (inside border, below tabs)
    local cY = y + 4 + LAYOUT.tabH + 6
    local cH = h - (LAYOUT.tabH + 14)
    -- Content area multi-layer border
    win.drawings.contentLayer1 = makeObj("Square", { Size = Vector2.new(w - 20, cH), Position = Vector2.new(x + 10, cY), Color = COLORS.dark, Filled = true, Visible = true, ZIndex = 5 })
    win.drawings.contentLayer2 = makeObj("Square", { Size = Vector2.new(w - 22, cH - 2), Position = Vector2.new(x + 11, cY + 1), Color = COLORS.outer, Filled = true, Visible = true, ZIndex = 6 })
    win.drawings.contentLayer3 = makeObj("Square", { Size = Vector2.new(w - 24, cH - 4), Position = Vector2.new(x + 12, cY + 2), Color = COLORS.surface, Filled = true, Visible = true, ZIndex = 7 })
    win.drawings.contentLayer4 = makeObj("Square", { Size = Vector2.new(w - 26, cH - 6), Position = Vector2.new(x + 13, cY + 3), Color = COLORS.outer, Filled = true, Visible = true, ZIndex = 8 })
    win.drawings.contentLayer5 = makeObj("Square", { Size = Vector2.new(w - 28, cH - 8), Position = Vector2.new(x + 14, cY + 4), Color = COLORS.bg, Filled = true, Visible = true, ZIndex = 9 })

    function win:getContentY()
        return self.y + 4 + LAYOUT.tabH + 6 + 4
    end

    function win:getContentH()
        return self.h - (LAYOUT.tabH + 14) - 8
    end

    function win:getContentW()
        return self.w - 28
    end

    function win:getContentX()
        return self.x + 14
    end

    function win:reposition()
        local x, y, w, h = self.x, self.y, self.w, self.h
        setProp(self.drawings.titleTx, "Position", Vector2.new(x + 10, y - 16))
        setProp(self.drawings.layer1, "Position", Vector2.new(x, y))
        setProp(self.drawings.layer2, "Position", Vector2.new(x + 1, y + 1))
        setProp(self.drawings.layer3, "Position", Vector2.new(x + 2, y + 2))
        setProp(self.drawings.layer4, "Position", Vector2.new(x + 3, y + 3))
        setProp(self.drawings.layer5, "Position", Vector2.new(x + 4, y + 4))
        local cY = y + 4 + LAYOUT.tabH + 6
        local cH = h - (LAYOUT.tabH + 14)
        setProp(self.drawings.contentLayer1, "Position", Vector2.new(x + 10, cY))
        setProp(self.drawings.contentLayer1, "Size", Vector2.new(w - 20, cH))
        setProp(self.drawings.contentLayer2, "Position", Vector2.new(x + 11, cY + 1))
        setProp(self.drawings.contentLayer2, "Size", Vector2.new(w - 22, cH - 2))
        setProp(self.drawings.contentLayer3, "Position", Vector2.new(x + 12, cY + 2))
        setProp(self.drawings.contentLayer3, "Size", Vector2.new(w - 24, cH - 4))
        setProp(self.drawings.contentLayer4, "Position", Vector2.new(x + 13, cY + 3))
        setProp(self.drawings.contentLayer4, "Size", Vector2.new(w - 26, cH - 6))
        setProp(self.drawings.contentLayer5, "Position", Vector2.new(x + 14, cY + 4))
        setProp(self.drawings.contentLayer5, "Size", Vector2.new(w - 28, cH - 8))
        -- Tab underline repositioned by tab update
        for _, pg in ipairs(self.pages) do pg:reposition() end
    end

    function win:update()
        -- Drag from top area of window
        local inTitle = inRect(mouse.x, mouse.y, self.x, self.y, self.w, LAYOUT.tabH + 6)

        if inTitle and justClicked() then
            self.dragging = true
            self.dragX = mouse.x - self.x
            self.dragY = mouse.y - self.y
        end
        if self.dragging then
            if isHeld() then
                self.x = clamp(mouse.x - self.dragX, -self.w + 60, Lib._screenW - 60)
                self.y = clamp(mouse.y - self.dragY, 20, Lib._screenH - 40)
                self:reposition()
            else
                self.dragging = false
            end
        end

        -- Tab animation
        if self._tabAnimActive then
            local now = clk()
            local el = now - self._tabAnimStart
            local p = clamp(el / 0.15, 0, 1)
            self._tabAnimNow = self._tabAnimFrom + (self._tabAnimTo - self._tabAnimFrom) * p
            if p >= 1 then self._tabAnimActive = false end
        end

        -- Tab clicks
        local numTabs = #self.pages
        if numTabs > 0 then
            local tabAreaW = self.w - 28
            local tw = floor(tabAreaW / numTabs)
            local tabY = self.y + 4

            for i, pg in ipairs(self.pages) do
                local tx = self.x + 14 + (i - 1) * tw
                local hov = inRect(mouse.x, mouse.y, tx, tabY, tw, LAYOUT.tabH)

                if pg == self.currentPage then
                    setProp(pg.drawings.tabTxt, "Color", COLORS.accent)
                elseif hov then
                    setProp(pg.drawings.tabTxt, "Color", COLORS.text)
                    if justClicked() then
                        -- Animate underline
                        self._tabAnimActive = true
                        self._tabAnimStart = clk()
                        self._tabAnimFrom = self._tabAnimNow
                        self._tabAnimTo = tx + 4
                        self._tabAnimWidth = tw - 8

                        if self.currentPage then self.currentPage:activate(false) end
                        self.currentPage = pg
                        pg:activate(true)
                    end
                else
                    setProp(pg.drawings.tabTxt, "Color", COLORS.tabInact)
                end
            end

            -- Update tab underline position
            if not self._tabAnimActive and self.currentPage then
                for i, pg in ipairs(self.pages) do
                    if pg == self.currentPage then
                        local tx = self.x + 14 + (i - 1) * tw
                        self._tabAnimNow = tx + 4
                        self._tabAnimWidth = tw - 8
                        break
                    end
                end
            end
            setProp(self.drawings.tabLine, "Position", Vector2.new(self._tabAnimNow, self.y + 4 + LAYOUT.tabH + 2))
            setProp(self.drawings.tabLine, "Size", Vector2.new(self._tabAnimWidth, 3))
        end

        if self.currentPage then self.currentPage:update() end
    end

    function win:SetVisible(vis)
        self.visible = vis
        Lib._shown = vis
        bulkVisible(self.drawings, vis)
        for _, pg in ipairs(self.pages) do
            setVisible(pg.drawings.tabTxt, vis)
            for _, sec in ipairs(pg.sections) do
                sec:setVisible(vis and pg.isActive)
            end
        end
    end

    function win:Page(o) return Lib:_makePage(self, o) end

    self.Windows[#self.Windows + 1] = win
    return win
end

----------------------------------------------------------------
-- PAGE (tab with centered text, animated underline)
----------------------------------------------------------------

function Lib:_makePage(win, opts)
    local idx = #win.pages + 1
    local pg = {
        win = win,
        label = opts.Name or "Tab",
        columns = opts.Columns or 2,
        isActive = false,
        sections = {},
        colStack = {},
        tabIndex = idx,
        drawings = {},
    }
    for c = 1, pg.columns do pg.colStack[c] = 0 end

    local numTabs = idx  -- will grow, but initial positioning
    local tabAreaW = win.w - 28
    local tw = floor(tabAreaW / max(1, idx))
    local tx = win.x + 14 + (idx - 1) * tw
    local ty = win.y + 4

    -- Tab text (centered in tab area)
    pg.drawings.tabTxt = makeObj("Text", { Text = pg.label, Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.tabInact, Center = true, Position = Vector2.new(tx + tw / 2, ty + (LAYOUT.tabH - LAYOUT.fontSize) / 2), Visible = true, ZIndex = 10 })

    function pg:reposition()
        local numTabs = #self.win.pages
        local tabAreaW = self.win.w - 28
        local tw = floor(tabAreaW / max(1, numTabs))
        local tx = self.win.x + 14 + (self.tabIndex - 1) * tw
        local ty = self.win.y + 4
        setProp(self.drawings.tabTxt, "Position", Vector2.new(tx + tw / 2, ty + (LAYOUT.tabH - LAYOUT.fontSize) / 2))
        for _, sec in ipairs(self.sections) do sec:reposition() end
    end

    function pg:activate(yes)
        self.isActive = yes
        if yes then
            setProp(self.drawings.tabTxt, "Color", COLORS.accent)
        else
            setProp(self.drawings.tabTxt, "Color", COLORS.tabInact)
        end
        for _, sec in ipairs(self.sections) do sec:setVisible(yes) end
    end

    function pg:update()
        if not self.isActive then return end
        for _, sec in ipairs(self.sections) do sec:update() end
    end

    function pg:Section(o) return Lib:_makeSection(self, o) end

    win.pages[#win.pages + 1] = pg

    -- Reposition all tabs when a new one is added
    for _, p in ipairs(win.pages) do p:reposition() end

    if idx == 1 then
        win.currentPage = pg
        pg:activate(true)
        -- Initialize tab underline
        local tabAreaW2 = win.w - 28
        local tw2 = floor(tabAreaW2 / 1)
        win._tabAnimNow = win.x + 14 + 4
        win._tabAnimWidth = tw2 - 8
    end
    return pg
end

----------------------------------------------------------------
-- SECTION (nested dark borders with centered header)
----------------------------------------------------------------

function Lib:_makeSection(page, opts)
    local col = opts.Side or 1
    local win = page.win
    local contentW = win:getContentW()
    local colWidth = contentW / page.columns
    local innerW = colWidth - 12
    local sx = win:getContentX() + 6 + (col - 1) * colWidth
    local sy = win:getContentY() + 6 + page.colStack[col]

    local sec = {
        page = page, win = win, col = col,
        x = sx, y = sy, w = innerW,
        totalH = LAYOUT.headerH,
        headerH = LAYOUT.headerH,
        nextElemY = 0,
        elements = {},
        drawings = {},
    }

    -- Nested section borders (dark -> secbg -> bg)
    sec.drawings.border1 = makeObj("Square", { Size = Vector2.new(innerW, sec.totalH), Position = Vector2.new(sx, sy), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 10 })
    sec.drawings.border2 = makeObj("Square", { Size = Vector2.new(innerW - 2, sec.totalH - 2), Position = Vector2.new(sx + 1, sy + 1), Color = COLORS.surface, Filled = true, Visible = false, ZIndex = 11 })
    sec.drawings.inner = makeObj("Square", { Size = Vector2.new(innerW - 4, sec.totalH - 4), Position = Vector2.new(sx + 2, sy + 2), Color = COLORS.bg, Filled = true, Visible = false, ZIndex = 12 })
    -- Header text centered
    sec.drawings.title = makeObj("Text", { Text = opts.Name or "Section", Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Center = true, Position = Vector2.new(sx + innerW / 2, sy + 6), Visible = false, ZIndex = 14 })

    function sec:recalcHeight()
        local prev = self.totalH
        local h = self.headerH + LAYOUT.secPad
        for i, el in ipairs(self.elements) do
            h = h + (el.height or LAYOUT.rowH)
            if i < #self.elements then h = h + LAYOUT.rowGap end
        end
        h = h + LAYOUT.secPad
        self.totalH = h
        setProp(self.drawings.border1, "Size", Vector2.new(self.w, h))
        setProp(self.drawings.border2, "Size", Vector2.new(self.w - 2, h - 2))
        setProp(self.drawings.inner, "Size", Vector2.new(self.w - 4, h - 4))
        page.colStack[self.col] = page.colStack[self.col] + (h - prev)
    end

    function sec:reposition()
        local contentW = self.win:getContentW()
        local colWidth = contentW / self.page.columns
        local bx = self.win:getContentX() + 6 + (self.col - 1) * colWidth
        local by = self.win:getContentY() + 6
        local offset = 0
        for _, other in ipairs(self.page.sections) do
            if other.col == self.col then
                if other == self then break end
                offset = offset + other.totalH + LAYOUT.secGap
            end
        end
        self.x = bx
        self.y = by + offset
        self.w = colWidth - 12
        setProp(self.drawings.border1, "Position", Vector2.new(self.x, self.y))
        setProp(self.drawings.border1, "Size", Vector2.new(self.w, self.totalH))
        setProp(self.drawings.border2, "Position", Vector2.new(self.x + 1, self.y + 1))
        setProp(self.drawings.border2, "Size", Vector2.new(self.w - 2, self.totalH - 2))
        setProp(self.drawings.inner, "Position", Vector2.new(self.x + 2, self.y + 2))
        setProp(self.drawings.inner, "Size", Vector2.new(self.w - 4, self.totalH - 4))
        setProp(self.drawings.title, "Position", Vector2.new(self.x + self.w / 2, self.y + 6))
        for _, el in ipairs(self.elements) do
            if el.reposition then el:reposition() end
        end
    end

    function sec:elemOrigin(relY)
        return self.x + 8, self.y + self.headerH + LAYOUT.secPad + relY
    end

    function sec:elemWidth()
        return self.w - 16
    end

    function sec:addElement(el)
        self.elements[#self.elements + 1] = el
        self.nextElemY = self.nextElemY + (el.height or LAYOUT.rowH) + LAYOUT.rowGap
        self:recalcHeight()
        -- If this section's page is active, make the new element visible
        if self.page.isActive and el.setVisible then
            el:setVisible(true)
        end
    end

    function sec:update()
        for _, el in ipairs(self.elements) do
            if el.update then el:update() end
        end
    end

    function sec:setVisible(v)
        bulkVisible(self.drawings, v)
        for _, el in ipairs(self.elements) do
            if el.setVisible then el:setVisible(v) end
        end
    end

    function sec:Toggle(o)  return Lib:_makeToggle(self, o) end
    function sec:Button(o)  return Lib:_makeButton(self, o) end
    function sec:Slider(o)  return Lib:_makeSlider(self, o) end
    function sec:Label(o)   return Lib:_makeLabel(self, o) end
    function sec:Divider(o) return Lib:_makeDivider(self, o) end
    function sec:Dropdown(o) return Lib:_makeDropdown(self, o) end
    function sec:Colorpicker(o) return Lib:_makeColorpicker(self, o) end
    function sec:Keybind(o) return Lib:_makeKeybind(self, o) end
    function sec:Textbox(o) return Lib:_makeTextbox(self, o) end
    function sec:Listbox(o) return Lib:_makeListbox(self, o) end

    page.sections[#page.sections + 1] = sec
    page.colStack[col] = page.colStack[col] + sec.totalH + LAYOUT.secGap

    -- If this page is already active, make the new section visible
    if page.isActive then
        sec:setVisible(true)
    end
    return sec
end

----------------------------------------------------------------
-- TOGGLE (small square checkbox, Thug Sense style)
----------------------------------------------------------------

function Lib:_makeToggle(sec, opts)
    local flag = opts.Flag or ("t_" .. clk())
    local relY = sec.nextElemY
    local ox, oy = sec:elemOrigin(relY)
    local ew = sec:elemWidth()

    local el = {
        height = LAYOUT.rowH,
        relY = relY, sec = sec,
        flag = flag,
        value = opts.Default or false,
        callback = opts.Callback,
        drawings = {},
    }

    -- Checkbox outer (dark border)
    el.drawings.cbOuter = makeObj("Square", { Size = Vector2.new(10, 10), Position = Vector2.new(ox + 2, oy + 5), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 16 })
    -- Checkbox inner (fill)
    el.drawings.cbInner = makeObj("Square", { Size = Vector2.new(8, 8), Position = Vector2.new(ox + 3, oy + 6), Color = el.value and COLORS.accent or COLORS.inactive, Filled = true, Visible = false, ZIndex = 17 })
    -- Label
    el.drawings.txt = makeObj("Text", { Text = opts.Name or "Toggle", Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(ox + 16, oy + 3), Visible = false, ZIndex = 16 })

    function el:Set(val)
        self.value = val
        Lib.Flags[self.flag] = val
        setProp(self.drawings.cbInner, "Color", val and COLORS.accent or COLORS.inactive)
    end
    function el:Get() return self.value end

    function el:reposition()
        local ox, oy = self.sec:elemOrigin(self.relY)
        setProp(self.drawings.cbOuter, "Position", Vector2.new(ox + 2, oy + 5))
        setProp(self.drawings.cbInner, "Position", Vector2.new(ox + 3, oy + 6))
        setProp(self.drawings.txt, "Position", Vector2.new(ox + 16, oy + 3))
    end

    function el:update()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        -- Click on checkbox or label
        local cbHov = inRect(mouse.x, mouse.y, ox + 2, oy + 3, 10, 14)
        local txtHov = inRect(mouse.x, mouse.y, ox + 16, oy + 3, textWidth(opts.Name or "Toggle") + 6, 14)
        if (cbHov or txtHov) and justClicked() then
            self.value = not self.value
            Lib.Flags[self.flag] = self.value
            self:Set(self.value)
            safeCall(self.callback, self.value)
        end
    end

    function el:setVisible(v)
        bulkVisible(self.drawings, v)
    end

    Lib.Flags[flag] = el.value
    Lib.SetFlags[flag] = function(val) el:Set(val); safeCall(el.callback, val) end
    sec:addElement(el)
    return el
end

----------------------------------------------------------------
-- LABEL
----------------------------------------------------------------

function Lib:_makeLabel(sec, opts)
    local relY = sec.nextElemY
    local ox, oy = sec:elemOrigin(relY)

    local el = {
        height = LAYOUT.rowH,
        relY = relY, sec = sec,
        drawings = {},
    }

    el.drawings.txt = makeObj("Text", { Text = opts.Name or "", Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(ox + 6, oy + (LAYOUT.rowH - LAYOUT.fontSize) / 2), Visible = false, ZIndex = 14 })

    function el:reposition()
        local ox, oy = self.sec:elemOrigin(self.relY)
        setProp(self.drawings.txt, "Position", Vector2.new(ox + 6, oy + (LAYOUT.rowH - LAYOUT.fontSize) / 2))
    end
    function el:update() end
    function el:setVisible(v) bulkVisible(self.drawings, v) end

    sec:addElement(el)
    return el
end

----------------------------------------------------------------
-- DIVIDER
----------------------------------------------------------------

function Lib:_makeDivider(sec, opts)
    local relY = sec.nextElemY
    local ox, oy = sec:elemOrigin(relY)
    local ew = sec:elemWidth()

    local el = {
        height = 6,
        relY = relY, sec = sec,
        drawings = {},
    }

    el.drawings.line = makeObj("Square", { Size = Vector2.new(ew, 1), Position = Vector2.new(ox, oy + 3), Color = COLORS.dim, Filled = true, Visible = false, ZIndex = 14 })

    function el:reposition()
        local ox, oy = self.sec:elemOrigin(self.relY)
        setProp(self.drawings.line, "Position", Vector2.new(ox, oy + 3))
        setProp(self.drawings.line, "Size", Vector2.new(self.sec:elemWidth(), 1))
    end
    function el:update() end
    function el:setVisible(v) bulkVisible(self.drawings, v) end

    sec:addElement(el)
    return el
end

----------------------------------------------------------------
-- BUTTON (dark bordered rectangle, centered text)
----------------------------------------------------------------

function Lib:_makeButton(sec, opts)
    local relY = sec.nextElemY
    local ox, oy = sec:elemOrigin(relY)
    local ew = sec:elemWidth()

    local el = {
        height = 25,
        relY = relY, sec = sec,
        callback = opts.Callback,
        drawings = {},
    }

    -- Outer border
    el.drawings.outer = makeObj("Square", { Size = Vector2.new(ew, 18), Position = Vector2.new(ox, oy + 2), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 14 })
    -- Inner bg
    el.drawings.inner = makeObj("Square", { Size = Vector2.new(ew - 2, 16), Position = Vector2.new(ox + 1, oy + 3), Color = COLORS.bg, Filled = true, Visible = false, ZIndex = 15 })
    -- Text (Center = true, positioned at horizontal midpoint)
    el.drawings.txt = makeObj("Text", { Text = opts.Name or "Button", Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Center = true, Position = Vector2.new(ox + ew / 2, oy + 5), Visible = false, ZIndex = 16 })

    function el:reposition()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        setProp(self.drawings.outer, "Position", Vector2.new(ox, oy + 2))
        setProp(self.drawings.outer, "Size", Vector2.new(ew, 18))
        setProp(self.drawings.inner, "Position", Vector2.new(ox + 1, oy + 3))
        setProp(self.drawings.inner, "Size", Vector2.new(ew - 2, 16))
        setProp(self.drawings.txt, "Position", Vector2.new(ox + ew / 2, oy + 5))
    end

    function el:update()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        local hov = inRect(mouse.x, mouse.y, ox, oy + 2, ew, 18)

        if hov then
            setProp(self.drawings.inner, "Color", COLORS.surface)
        else
            setProp(self.drawings.inner, "Color", COLORS.bg)
        end

        if hov and justClicked() then
            safeCall(self.callback)
        end
    end

    function el:setVisible(v)
        bulkVisible(self.drawings, v)
    end

    sec:addElement(el)
    return el
end

----------------------------------------------------------------
-- SLIDER (minus/plus buttons, track with rect thumb, value below)
----------------------------------------------------------------

function Lib:_makeSlider(sec, opts)
    local flag = opts.Flag or ("s_" .. clk())
    local relY = sec.nextElemY
    local ox, oy = sec:elemOrigin(relY)
    local ew = sec:elemWidth()
    local sliderFullH = 40

    local el = {
        height = sliderFullH,
        relY = relY, sec = sec,
        flag = flag,
        min = opts.Min or 0,
        max = opts.Max or 100,
        decimals = opts.Decimals or 0,
        value = opts.Default or opts.Min or 0,
        suffix = opts.Suffix or "",
        callback = opts.Callback,
        sliding = false,
        drawings = {},
    }

    local valStr = round(el.value, el.decimals) .. el.suffix
    local trackX = ox + 20
    local trackW = ew - 40
    local trackY = oy + 18
    local frac = clamp((el.value - el.min) / (el.max - el.min), 0, 1)
    local fillW = max(0, trackW * frac)
    local thumbX = trackX + fillW - 2

    -- Title
    el.drawings.title = makeObj("Text", { Text = opts.Name or "Slider", Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(ox + 6, oy), Visible = false, ZIndex = 16 })
    -- Minus button (horizontal line)
    el.drawings.minusBg = makeObj("Square", { Size = Vector2.new(5, 1), Position = Vector2.new(ox + 2, trackY + 3), Color = COLORS.text, Filled = true, Visible = false, ZIndex = 16 })
    -- Plus button (cross)
    el.drawings.plusH = makeObj("Square", { Size = Vector2.new(5, 1), Position = Vector2.new(ox + ew - 7, trackY + 3), Color = COLORS.text, Filled = true, Visible = false, ZIndex = 16 })
    el.drawings.plusV = makeObj("Square", { Size = Vector2.new(1, 5), Position = Vector2.new(ox + ew - 5, trackY + 1), Color = COLORS.text, Filled = true, Visible = false, ZIndex = 16 })
    -- Track bg
    el.drawings.trackBg = makeObj("Square", { Size = Vector2.new(trackW, LAYOUT.sliderH), Position = Vector2.new(trackX, trackY), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 14 })
    -- Track inactive fill
    el.drawings.trackInactive = makeObj("Square", { Size = Vector2.new(trackW - 2, LAYOUT.sliderH - 2), Position = Vector2.new(trackX + 1, trackY + 1), Color = COLORS.inactive, Filled = true, Visible = false, ZIndex = 15 })
    -- Track active fill
    el.drawings.trackFill = makeObj("Square", { Size = Vector2.new(max(0, fillW), LAYOUT.sliderH - 2), Position = Vector2.new(trackX + 1, trackY + 1), Color = COLORS.accent, Filled = true, Visible = false, ZIndex = 16 })
    -- Thumb (rectangular, 4px wide, slightly taller than track)
    el.drawings.thumb = makeObj("Square", { Size = Vector2.new(4, LAYOUT.sliderH + 2), Position = Vector2.new(thumbX, trackY - 1), Color = COLORS.accent, Filled = true, Visible = false, ZIndex = 17 })
    -- Value text centered below
    el.drawings.valTx = makeObj("Text", { Text = valStr, Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Center = true, Position = Vector2.new(trackX + trackW / 2, oy + 26), Visible = false, ZIndex = 16 })

    function el:Set(val)
        val = clamp(round(val, self.decimals), self.min, self.max)
        self.value = val
        Lib.Flags[self.flag] = val
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        local trackX = ox + 20
        local trackW = ew - 40
        local trackY = oy + 18
        local frac = clamp((val - self.min) / (self.max - self.min), 0, 1)
        local fillW = max(0, trackW * frac)
        local thumbX = trackX + fillW - 2
        local valStr = round(val, self.decimals) .. self.suffix
        setProp(self.drawings.trackFill, "Size", Vector2.new(max(0, fillW), LAYOUT.sliderH - 2))
        setProp(self.drawings.thumb, "Position", Vector2.new(thumbX, trackY - 1))
        setProp(self.drawings.valTx, "Text", valStr)
        setProp(self.drawings.valTx, "Position", Vector2.new(trackX + trackW / 2, oy + 26))
    end
    function el:Get() return self.value end

    function el:reposition()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        local trackX = ox + 20
        local trackW = ew - 40
        local trackY = oy + 18
        local frac = clamp((self.value - self.min) / (self.max - self.min), 0, 1)
        local fillW = max(0, trackW * frac)
        local thumbX = trackX + fillW - 2
        local valStr = round(self.value, self.decimals) .. self.suffix
        setProp(self.drawings.title, "Position", Vector2.new(ox + 6, oy))
        setProp(self.drawings.minusBg, "Position", Vector2.new(ox + 2, trackY + 3))
        setProp(self.drawings.plusH, "Position", Vector2.new(ox + ew - 7, trackY + 3))
        setProp(self.drawings.plusV, "Position", Vector2.new(ox + ew - 5, trackY + 1))
        setProp(self.drawings.trackBg, "Position", Vector2.new(trackX, trackY))
        setProp(self.drawings.trackBg, "Size", Vector2.new(trackW, LAYOUT.sliderH))
        setProp(self.drawings.trackInactive, "Position", Vector2.new(trackX + 1, trackY + 1))
        setProp(self.drawings.trackInactive, "Size", Vector2.new(trackW - 2, LAYOUT.sliderH - 2))
        setProp(self.drawings.trackFill, "Position", Vector2.new(trackX + 1, trackY + 1))
        setProp(self.drawings.trackFill, "Size", Vector2.new(max(0, fillW), LAYOUT.sliderH - 2))
        setProp(self.drawings.thumb, "Position", Vector2.new(thumbX, trackY - 1))
        setProp(self.drawings.valTx, "Text", valStr)
        setProp(self.drawings.valTx, "Position", Vector2.new(trackX + trackW / 2, oy + 26))
    end

    function el:update()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        local trackX = ox + 20
        local trackW = ew - 40
        local trackY = oy + 18

        -- Minus button click
        if justClicked() and inRect(mouse.x, mouse.y, ox, trackY - 2, 14, 10) then
            self:Set(self.value - 1)
            safeCall(self.callback, self.value)
        end
        -- Plus button click
        if justClicked() and inRect(mouse.x, mouse.y, ox + ew - 14, trackY - 2, 14, 10) then
            self:Set(self.value + 1)
            safeCall(self.callback, self.value)
        end

        -- Track drag
        if justClicked() and inRect(mouse.x, mouse.y, trackX, trackY - 2, trackW, LAYOUT.sliderH + 4) then
            self.sliding = true
        end
        if self.sliding then
            if isHeld() then
                local frac = clamp((mouse.x - trackX) / trackW, 0, 1)
                local raw = self.min + frac * (self.max - self.min)
                local val = clamp(round(raw, self.decimals), self.min, self.max)
                if val ~= self.value then
                    self:Set(val)
                    safeCall(self.callback, val)
                end
            else
                self.sliding = false
            end
        end
    end

    function el:setVisible(v)
        bulkVisible(self.drawings, v)
    end

    Lib.Flags[flag] = el.value
    Lib.SetFlags[flag] = function(val) el:Set(val); safeCall(el.callback, val) end
    sec:addElement(el)
    return el
end

----------------------------------------------------------------
-- DROPDOWN (dark box with arrow, Thug Sense style)
----------------------------------------------------------------

function Lib:_makeDropdown(sec, opts)
    local flag = opts.Flag or ("d_" .. clk())
    local relY = sec.nextElemY
    local ox, oy = sec:elemOrigin(relY)
    local ew = sec:elemWidth()

    local el = {
        height = 32,
        relY = relY, sec = sec,
        flag = flag,
        options = opts.Options or {},
        selected = opts.Default or (opts.Options and opts.Options[1]) or "",
        callback = opts.Callback,
        expanded = false,
        optDrawings = {},
        drawings = {},
    }

    -- Label
    el.drawings.label = makeObj("Text", { Text = opts.Name or "Dropdown", Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(ox + 6, oy + 1), Visible = false, ZIndex = 16 })
    -- Dropdown box outer
    local boxY = oy + 14
    el.drawings.boxOuter = makeObj("Square", { Size = Vector2.new(ew, 18), Position = Vector2.new(ox, boxY), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 14 })
    -- Dropdown box inner
    el.drawings.boxInner = makeObj("Square", { Size = Vector2.new(ew - 2, 16), Position = Vector2.new(ox + 1, boxY + 1), Color = COLORS.bg, Filled = true, Visible = false, ZIndex = 15 })
    -- Selected text
    el.drawings.selTx = makeObj("Text", { Text = el.selected, Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(ox + 6, boxY + 3), Visible = false, ZIndex = 16 })
    -- Arrow indicator (small triangle made of lines)
    el.drawings.arrowH = makeObj("Square", { Size = Vector2.new(5, 1), Position = Vector2.new(ox + ew - 10, boxY + 9), Color = COLORS.text, Filled = true, Visible = false, ZIndex = 16 })

    -- Options (created as overlay) - lazily created on first expand
    el.optDrawingsCreated = false

    function el:Set(val)
        self.selected = val
        Lib.Flags[self.flag] = val
        setProp(self.drawings.selTx, "Text", val)
    end
    function el:Get() return self.selected end

    function el:showOptions(show)
        self.expanded = show

        -- Create option drawings on first show
        if show and not self.optDrawingsCreated then
            self.optDrawingsCreated = true
            local ox, oy = self.sec:elemOrigin(self.relY)
            local ew = self.sec:elemWidth()
            local boxY = oy + 14

            for i, opt in ipairs(self.options) do
                local optY = boxY + 18 + (i - 1) * 15
                local od = {
                    bg   = makeObj("Square", { Size = Vector2.new(ew, 15), Position = Vector2.new(ox, optY), Color = COLORS.bg, Filled = true, Visible = false, ZIndex = 150 }),
                    txt  = makeObj("Text", { Text = opt, Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(ox + 6, optY + 1), Visible = false, ZIndex = 152 }),
                }
                if i == 1 then
                    od.topBdr = makeObj("Square", { Size = Vector2.new(ew, 1), Position = Vector2.new(ox, optY - 1), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 151 })
                end
                self.optDrawings[i] = od
            end

            if #self.options > 0 then
                local lastY = boxY + 18 + #self.options * 15
                self.drawings.optBotBdr = makeObj("Square", { Size = Vector2.new(ew, 1), Position = Vector2.new(ox, lastY), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 151 })
            end
        end

        for _, od in ipairs(self.optDrawings) do
            setVisible(od.bg, show)
            setVisible(od.txt, show)
            if od.topBdr then setVisible(od.topBdr, show) end
        end
        if self.drawings.optBotBdr then setVisible(self.drawings.optBotBdr, show) end
        if show then
            Lib._openDropdown = self
        elseif Lib._openDropdown == self then
            Lib._openDropdown = nil
        end
    end

    function el:reposition()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        local boxY = oy + 14
        setProp(self.drawings.label, "Position", Vector2.new(ox + 6, oy + 1))
        setProp(self.drawings.boxOuter, "Position", Vector2.new(ox, boxY))
        setProp(self.drawings.boxOuter, "Size", Vector2.new(ew, 18))
        setProp(self.drawings.boxInner, "Position", Vector2.new(ox + 1, boxY + 1))
        setProp(self.drawings.boxInner, "Size", Vector2.new(ew - 2, 16))
        setProp(self.drawings.selTx, "Position", Vector2.new(ox + 6, boxY + 3))
        setProp(self.drawings.arrowH, "Position", Vector2.new(ox + ew - 10, boxY + 9))

        -- Only reposition option drawings if they've been created
        if self.optDrawingsCreated then
            for i, od in ipairs(self.optDrawings) do
                local optY = boxY + 18 + (i - 1) * 15
                setProp(od.bg, "Position", Vector2.new(ox, optY))
                setProp(od.bg, "Size", Vector2.new(ew, 15))
                setProp(od.txt, "Position", Vector2.new(ox + 6, optY + 1))
                if od.topBdr then
                    setProp(od.topBdr, "Position", Vector2.new(ox, optY - 1))
                    setProp(od.topBdr, "Size", Vector2.new(ew, 1))
                end
            end
            if self.drawings.optBotBdr and #self.options > 0 then
                local lastY = boxY + 18 + #self.options * 15
                setProp(self.drawings.optBotBdr, "Position", Vector2.new(ox, lastY))
                setProp(self.drawings.optBotBdr, "Size", Vector2.new(ew, 1))
            end
        end
    end

    function el:update()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        local boxY = oy + 14
        local hdrHov = inRect(mouse.x, mouse.y, ox, boxY, ew, 18)

        if hdrHov and justClicked() then
            if self.expanded then
                self:showOptions(false)
            else
                if Lib._openDropdown and Lib._openDropdown ~= self then
                    Lib._openDropdown:showOptions(false)
                end
                if Lib._openColorpicker then
                    Lib._openColorpicker:showPanel(false)
                end
                if Lib._openKeybindModeDropdown then
                    Lib._openKeybindModeDropdown:showModeDropdown(false)
                end
                self:showOptions(true)
            end
        end

        if self.expanded then
            local anyHov = false
            for i, od in ipairs(self.optDrawings) do
                local optY = boxY + 18 + (i - 1) * 15
                local optHov = inRect(mouse.x, mouse.y, ox, optY, ew, 15)
                if optHov then
                    anyHov = true
                    setProp(od.bg, "Color", COLORS.surface)
                    setProp(od.txt, "Color", COLORS.accent)
                    if justClicked() then
                        self:Set(self.options[i])
                        self:showOptions(false)
                        safeCall(self.callback, self.options[i])
                    end
                else
                    local isSel = self.selected == self.options[i]
                    setProp(od.bg, "Color", COLORS.bg)
                    setProp(od.txt, "Color", isSel and COLORS.accent or COLORS.text)
                end
            end

            if justClicked() and not hdrHov and not anyHov then
                self:showOptions(false)
            end
        end
    end

    function el:setVisible(v)
        bulkVisible(self.drawings, v)
        if not v and self.expanded then self:showOptions(false) end
    end

    Lib.Flags[flag] = el.selected
    Lib.SetFlags[flag] = function(val) el:Set(val); safeCall(el.callback, val) end
    sec:addElement(el)
    return el
end

----------------------------------------------------------------
-- COLORPICKER (square preview + panel)
----------------------------------------------------------------

function Lib:_makeColorpicker(sec, opts)
    local flag = opts.Flag or ("c_" .. clk())
    local relY = sec.nextElemY
    local ox, oy = sec:elemOrigin(relY)
    local ew = sec:elemWidth()

    local defaultColor = opts.Default or Color3.fromRGB(200, 140, 140)
    local h0, s0, v0 = c3ToHSV(defaultColor)

    local el = {
        height = LAYOUT.rowH,
        relY = relY, sec = sec,
        flag = flag,
        hue = h0, sat = s0, val = v0,
        color = defaultColor,
        callback = opts.Callback,
        open = false,
        draggingSV = false,
        draggingHue = false,
        drawings = {},
        svCells = {},
        hueCells = {},
    }

    -- Preview row
    el.drawings.label = makeObj("Text", { Text = opts.Name or "Color", Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(ox + 6, oy + (LAYOUT.rowH - LAYOUT.fontSize) / 2), Visible = false, ZIndex = 16 })
    -- Square color preview (right-aligned)
    local prevX = ox + ew - 18
    local prevY = oy + 3
    el.drawings.prevOuter = makeObj("Square", { Size = Vector2.new(14, 14), Position = Vector2.new(prevX, prevY), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 16 })
    el.drawings.prevInner = makeObj("Square", { Size = Vector2.new(12, 12), Position = Vector2.new(prevX + 1, prevY + 1), Color = defaultColor, Filled = true, Visible = false, ZIndex = 17 })

    -- Panel
    local SV_SZ = 150
    local HUE_W = 14
    local GRID = 18
    local cellSz = SV_SZ / GRID
    local panelW = SV_SZ + 20 + HUE_W
    local panelH = SV_SZ + 20
    local panelX = ox
    local panelY = oy + LAYOUT.rowH + 2

    el.drawings.panelBg  = makeObj("Square", { Size = Vector2.new(panelW, panelH), Position = Vector2.new(panelX, panelY), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 160 })
    el.drawings.panelInner = makeObj("Square", { Size = Vector2.new(panelW - 2, panelH - 2), Position = Vector2.new(panelX + 1, panelY + 1), Color = COLORS.bg, Filled = true, Visible = false, ZIndex = 161 })

    -- SV grid border
    local svX = panelX + 8
    local svY = panelY + 8
    el.drawings.svBdr = makeObj("Square", { Size = Vector2.new(SV_SZ + 2, SV_SZ + 2), Position = Vector2.new(svX - 1, svY - 1), Color = COLORS.dark, Filled = false, Thickness = 1, Visible = false, ZIndex = 161 })

    -- Hue bar border
    local hueX = svX + SV_SZ + 8
    local hueY = svY
    el.drawings.hueBdr = makeObj("Square", { Size = Vector2.new(HUE_W + 2, SV_SZ + 2), Position = Vector2.new(hueX - 1, hueY - 1), Color = COLORS.dark, Filled = false, Thickness = 1, Visible = false, ZIndex = 161 })

    -- SV cells (18x18)
    for row = 0, GRID - 1 do
        for col = 0, GRID - 1 do
            local s = col / (GRID - 1)
            local v = 1 - row / (GRID - 1)
            local c = hsvToC3(el.hue, s, v)
            local cell = makeObj("Square", { Size = Vector2.new(cellSz + 1, cellSz + 1), Position = Vector2.new(svX + col * cellSz, svY + row * cellSz), Color = c, Filled = true, Visible = false, ZIndex = 162 })
            el.svCells[#el.svCells + 1] = cell
        end
    end

    -- Hue cells (18 vertical)
    for i = 0, GRID - 1 do
        local hh = i / (GRID - 1)
        local cell = makeObj("Square", { Size = Vector2.new(HUE_W, cellSz + 1), Position = Vector2.new(hueX, hueY + i * cellSz), Color = hsvToC3(hh, 1, 1), Filled = true, Visible = false, ZIndex = 162 })
        el.hueCells[#el.hueCells + 1] = cell
    end

    -- SV cursor
    local curSX = svX + el.sat * SV_SZ
    local curSY = svY + (1 - el.val) * SV_SZ
    el.drawings.svCursor  = makeObj("Circle", { Radius = 4, Position = Vector2.new(curSX, curSY), Color = Color3.new(1, 1, 1), Filled = false, Thickness = 2, Visible = false, ZIndex = 165 })
    el.drawings.svCursorB = makeObj("Circle", { Radius = 5, Position = Vector2.new(curSX, curSY), Color = Color3.new(0, 0, 0), Filled = false, Thickness = 1, Visible = false, ZIndex = 164 })

    -- Hue arrow
    local hueArrowY = hueY + el.hue * SV_SZ
    el.drawings.hueArrow = makeObj("Square", { Size = Vector2.new(HUE_W + 4, 2), Position = Vector2.new(hueX - 2, hueArrowY), Color = Color3.new(1, 1, 1), Filled = true, Visible = false, ZIndex = 165 })

    function el:refreshSV()
        local idx = 1
        for row = 0, GRID - 1 do
            for col = 0, GRID - 1 do
                local s = col / (GRID - 1)
                local v = 1 - row / (GRID - 1)
                setProp(self.svCells[idx], "Color", hsvToC3(self.hue, s, v))
                idx = idx + 1
            end
        end
    end

    function el:updateColor()
        self.color = hsvToC3(self.hue, self.sat, self.val)
        setProp(self.drawings.prevInner, "Color", self.color)
        Lib.Flags[self.flag] = self.color

        local ox, oy = self.sec:elemOrigin(self.relY)
        local panelY = oy + LAYOUT.rowH + 2
        local svX = ox + 8
        local svY = panelY + 8
        local SV_SZ = 150

        local cx = svX + self.sat * SV_SZ
        local cy = svY + (1 - self.val) * SV_SZ
        setProp(self.drawings.svCursor, "Position", Vector2.new(cx, cy))
        setProp(self.drawings.svCursorB, "Position", Vector2.new(cx, cy))

        local hueY = svY
        setProp(self.drawings.hueArrow, "Position", Vector2.new(svX + SV_SZ + 8 - 2, hueY + self.hue * SV_SZ))
    end

    function el:Set(c3)
        self.hue, self.sat, self.val = c3ToHSV(c3)
        self:refreshSV()
        self:updateColor()
    end
    function el:Get() return self.color end

    function el:showPanel(show)
        self.open = show
        local panelKeys = {"panelBg", "panelInner", "svBdr", "hueBdr", "svCursor", "svCursorB", "hueArrow"}
        for _, k in ipairs(panelKeys) do setVisible(self.drawings[k], show) end
        for _, c in ipairs(self.svCells) do setVisible(c, show) end
        for _, c in ipairs(self.hueCells) do setVisible(c, show) end
        if show then
            Lib._openColorpicker = self
        elseif Lib._openColorpicker == self then
            Lib._openColorpicker = nil
        end
    end

    function el:reposition()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        setProp(self.drawings.label, "Position", Vector2.new(ox + 6, oy + (LAYOUT.rowH - LAYOUT.fontSize) / 2))
        local prevX = ox + ew - 18
        local prevY = oy + 3
        setProp(self.drawings.prevOuter, "Position", Vector2.new(prevX, prevY))
        setProp(self.drawings.prevInner, "Position", Vector2.new(prevX + 1, prevY + 1))

        local panelX = ox
        local panelY = oy + LAYOUT.rowH + 2
        local panelW = SV_SZ + 20 + HUE_W
        local panelH2 = SV_SZ + 20
        setProp(self.drawings.panelBg, "Position", Vector2.new(panelX, panelY))
        setProp(self.drawings.panelInner, "Position", Vector2.new(panelX + 1, panelY + 1))

        local svX = panelX + 8
        local svY = panelY + 8
        setProp(self.drawings.svBdr, "Position", Vector2.new(svX - 1, svY - 1))

        local hueX = svX + SV_SZ + 8
        setProp(self.drawings.hueBdr, "Position", Vector2.new(hueX - 1, svY - 1))

        local idx = 1
        for row = 0, GRID - 1 do
            for col = 0, GRID - 1 do
                setProp(self.svCells[idx], "Position", Vector2.new(svX + col * cellSz, svY + row * cellSz))
                idx = idx + 1
            end
        end
        for i = 0, GRID - 1 do
            setProp(self.hueCells[i + 1], "Position", Vector2.new(hueX, svY + i * cellSz))
        end
        self:updateColor()
    end

    function el:update()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        local prevX = ox + ew - 18
        local prevY = oy + 3
        local prevHov = inRect(mouse.x, mouse.y, prevX, prevY, 14, 14)

        if prevHov and justClicked() then
            if self.open then
                self:showPanel(false)
            else
                if Lib._openColorpicker and Lib._openColorpicker ~= self then
                    Lib._openColorpicker:showPanel(false)
                end
                if Lib._openDropdown then Lib._openDropdown:showOptions(false) end
                if Lib._openKeybindModeDropdown then
                    Lib._openKeybindModeDropdown:showModeDropdown(false)
                end
                self:showPanel(true)
            end
        end

        if self.open then
            local panelY = oy + LAYOUT.rowH + 2
            local svX = ox + 8
            local svY = panelY + 8
            local hueX = svX + SV_SZ + 8
            local panelW = SV_SZ + 20 + HUE_W
            local panelH2 = SV_SZ + 20

            local inSV = inRect(mouse.x, mouse.y, svX, svY, SV_SZ, SV_SZ)
            local inHue = inRect(mouse.x, mouse.y, hueX, svY, HUE_W, SV_SZ)
            local inPanel = inRect(mouse.x, mouse.y, ox, panelY, panelW, panelH2)

            if inSV and justClicked() then self.draggingSV = true end
            if inHue and justClicked() then self.draggingHue = true end

            if self.draggingSV then
                if isHeld() then
                    self.sat = clamp((mouse.x - svX) / SV_SZ, 0, 1)
                    self.val = 1 - clamp((mouse.y - svY) / SV_SZ, 0, 1)
                    self:updateColor()
                    safeCall(self.callback, self.color)
                else
                    self.draggingSV = false
                end
            end

            if self.draggingHue then
                if isHeld() then
                    self.hue = clamp((mouse.y - svY) / SV_SZ, 0, 1)
                    self:refreshSV()
                    self:updateColor()
                    safeCall(self.callback, self.color)
                else
                    self.draggingHue = false
                end
            end

            if justClicked() and not inPanel and not prevHov then
                self:showPanel(false)
            end
        end
    end

    function el:setVisible(v)
        setVisible(self.drawings.label, v)
        setVisible(self.drawings.prevOuter, v)
        setVisible(self.drawings.prevInner, v)
        if not v and self.open then self:showPanel(false) end
    end

    Lib.Flags[flag] = el.color
    Lib.SetFlags[flag] = function(c3) el:Set(c3) end
    sec:addElement(el)
    return el
end

----------------------------------------------------------------
-- KEYBIND ([KEY] pill style, Thug Sense)
----------------------------------------------------------------

function Lib:_makeKeybind(sec, opts)
    local flag = opts.Flag or ("k_" .. clk())
    local relY = sec.nextElemY
    local ox, oy = sec:elemOrigin(relY)
    local ew = sec:elemWidth()

    local initKeyName = opts.Default and keyToName(opts.Default) or nil

    local el = {
        height = LAYOUT.rowH,
        relY = relY, sec = sec,
        flag = flag,
        key = opts.Default,
        mode = opts.Mode or "Toggle",
        toggled = opts.DefaultToggled or false,
        callback = opts.Callback,
        phase = "idle",
        _mouseWait = false,
        _prevKeyState = false,
        _keyName = initKeyName,
        _label = opts.Name or "Keybind",
        _kbOverlayName = opts.Name or "Keybind",
        _hideFromOverlay = opts.HideFromOverlay or false,
        _hideModeSelector = opts.HideModeSelector or false,
        _modeDropdownOpen = false,
        drawings = {},
        modeDrawings = {},
    }

    local keyName = keyDisplayName(el.key)
    local keyStr = "[" .. keyName .. "]"

    -- Label
    el.drawings.label = makeObj("Text", { Text = opts.Name or "Keybind", Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(ox + 6, oy + (LAYOUT.rowH - LAYOUT.fontSize) / 2), Visible = false, ZIndex = 16 })
    -- Key pill bg
    local keyW = textWidth(keyStr) + 6
    local keyX = ox + ew - keyW - 8
    local keyY = oy + (LAYOUT.rowH - 12) / 2
    el.drawings.keyBgOuter = makeObj("Square", { Size = Vector2.new(keyW + 4, 12), Position = Vector2.new(keyX - 2, keyY), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 14 })
    el.drawings.keyBgInner = makeObj("Square", { Size = Vector2.new(keyW + 2, 10), Position = Vector2.new(keyX - 1, keyY + 1), Color = COLORS.bg, Filled = true, Visible = false, ZIndex = 15 })
    -- Key text
    el.drawings.keyTx = makeObj("Text", { Text = keyStr, Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(keyX + 1, keyY), Visible = false, ZIndex = 16 })

    -- Mode dropdown (right-click menu) - lazily created on first show
    el.modeOptions = {"Hold", "Toggle", "Always"}
    el.modeDropdownCreated = false

    function el:showModeDropdown(show)
        self._modeDropdownOpen = show

        if show then
            local ox, oy = self.sec:elemOrigin(self.relY)
            local ew = self.sec:elemWidth()
            local dname = keyDisplayName(self.key)
            local keyStr = "[" .. dname .. "]"
            local keyW = textWidth(keyStr) + 6
            local keyX = ox + ew - keyW - 8
            local dropW = 60
            local dropH = 15
            local dropStartY = oy + LAYOUT.rowH

            -- Create mode dropdown elements on first show
            if not self.modeDropdownCreated then
                self.modeDropdownCreated = true

                for i, modeName in ipairs(self.modeOptions) do
                    local dropY = dropStartY + (i - 1) * dropH
                    local md = {
                        bg  = makeObj("Square", { Size = Vector2.new(dropW, dropH), Position = Vector2.new(keyX, dropY), Color = COLORS.bg, Filled = true, Visible = false, ZIndex = 200 }),
                        txt = makeObj("Text", { Text = modeName, Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(keyX + 4, dropY + 1), Visible = false, ZIndex = 202 }),
                        leftBdr = makeObj("Square", { Size = Vector2.new(1, dropH), Position = Vector2.new(keyX - 1, dropY), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 201 }),
                        rightBdr = makeObj("Square", { Size = Vector2.new(1, dropH), Position = Vector2.new(keyX + dropW, dropY), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 201 }),
                    }
                    if i == 1 then
                        md.topBdr = makeObj("Square", { Size = Vector2.new(dropW, 1), Position = Vector2.new(keyX, dropY - 1), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 201 })
                    end
                    self.modeDrawings[i] = md
                end
                -- Bottom border
                local totalDropH = #self.modeOptions * dropH
                self.drawings.modeBotBdr = makeObj("Square", { Size = Vector2.new(dropW, 1), Position = Vector2.new(keyX, dropStartY + totalDropH), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 201 })
            else
                -- Update positions if already created
                for i, md in ipairs(self.modeDrawings) do
                    local dropY = dropStartY + (i - 1) * dropH
                    setProp(md.bg, "Position", Vector2.new(keyX, dropY))
                    setProp(md.txt, "Position", Vector2.new(keyX + 4, dropY + 1))
                    setProp(md.leftBdr, "Position", Vector2.new(keyX - 1, dropY))
                    setProp(md.rightBdr, "Position", Vector2.new(keyX + dropW, dropY))
                    if md.topBdr then
                        setProp(md.topBdr, "Position", Vector2.new(keyX, dropY - 1))
                    end
                end
                local totalDropH = #self.modeDrawings * dropH
                setProp(self.drawings.modeBotBdr, "Position", Vector2.new(keyX, dropStartY + totalDropH))
            end
        end

        for _, md in ipairs(self.modeDrawings) do
            setVisible(md.bg, show)
            setVisible(md.txt, show)
            setVisible(md.leftBdr, show)
            setVisible(md.rightBdr, show)
            if md.topBdr then setVisible(md.topBdr, show) end
        end
        if self.drawings.modeBotBdr then
            setVisible(self.drawings.modeBotBdr, show)
        end

        if show then
            Lib._openKeybindModeDropdown = self
        elseif Lib._openKeybindModeDropdown == self then
            Lib._openKeybindModeDropdown = nil
        end
    end

    function el:Set(code)
        self.key = code
        self._keyName = keyToName(code)
        Lib.Flags[self.flag] = code
        print("[SevereUI] Keybind", self._label, "set to:", keyDisplayName(code), "(code:", code, "name:", self._keyName, ")")
        -- Update visual
        local dname = keyDisplayName(code)
        local keyStr = "[" .. dname .. "]"
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        local keyW = textWidth(keyStr) + 6
        local keyX = ox + ew - keyW - 8
        local keyY = oy + (LAYOUT.rowH - 12) / 2
        setProp(self.drawings.keyTx, "Text", keyStr)
        setProp(self.drawings.keyTx, "Position", Vector2.new(keyX + 1, keyY))
        setProp(self.drawings.keyBgOuter, "Position", Vector2.new(keyX - 2, keyY))
        setProp(self.drawings.keyBgOuter, "Size", Vector2.new(keyW + 4, 12))
        setProp(self.drawings.keyBgInner, "Position", Vector2.new(keyX - 1, keyY + 1))
        setProp(self.drawings.keyBgInner, "Size", Vector2.new(keyW + 2, 10))
    end

    -- Reliable key held check using stored name
    function el:isBoundKeyHeld()
        if not self.key then return false end
        local boundName = self._keyName or keyToName(self.key)
        for _, k in ipairs(mouse.keys) do
            if k == self.key then
                -- print("[SevereUI]", self._label, "detected by code match:", k, "==", self.key)
                return true
            end
            if boundName then
                local kName = keyToName(k)
                if kName and kName == boundName then
                    -- print("[SevereUI]", self._label, "detected by name match:", kName, "==", boundName)
                    return true
                end
            end
        end
        return false
    end
    function el:Get() return self.key end

    function el:reposition()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        setProp(self.drawings.label, "Position", Vector2.new(ox + 6, oy + (LAYOUT.rowH - LAYOUT.fontSize) / 2))
        local dname = keyDisplayName(self.key)
        local keyStr = "[" .. dname .. "]"
        local keyW = textWidth(keyStr) + 6
        local keyX = ox + ew - keyW - 8
        local keyY = oy + (LAYOUT.rowH - 12) / 2
        setProp(self.drawings.keyTx, "Position", Vector2.new(keyX + 1, keyY))
        setProp(self.drawings.keyBgOuter, "Position", Vector2.new(keyX - 2, keyY))
        setProp(self.drawings.keyBgOuter, "Size", Vector2.new(keyW + 4, 12))
        setProp(self.drawings.keyBgInner, "Position", Vector2.new(keyX - 1, keyY + 1))
        setProp(self.drawings.keyBgInner, "Size", Vector2.new(keyW + 2, 10))
        -- Reposition mode dropdown (only if created)
        if self.modeDropdownCreated then
            local dropW = 60
            local dropH = 15
            local totalDropH = #self.modeDrawings * dropH
            local dropStartY = oy + LAYOUT.rowH

            for i, md in ipairs(self.modeDrawings) do
                local dropY = dropStartY + (i - 1) * dropH
                setProp(md.bg, "Position", Vector2.new(keyX, dropY))
                setProp(md.txt, "Position", Vector2.new(keyX + 4, dropY + 1))
                setProp(md.leftBdr, "Position", Vector2.new(keyX - 1, dropY))
                setProp(md.rightBdr, "Position", Vector2.new(keyX + dropW, dropY))
                if md.topBdr then
                    setProp(md.topBdr, "Position", Vector2.new(keyX, dropY - 1))
                end
            end

            -- Reposition bottom border
            if self.drawings.modeBotBdr then
                setProp(self.drawings.modeBotBdr, "Position", Vector2.new(keyX, dropStartY + totalDropH))
            end
        end
    end

    function el:update()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        local dname = keyDisplayName(self.key)
        local keyStr = self.phase == "picking" and "[...]" or ("[" .. dname .. "]")
        local keyW = textWidth(keyStr) + 6
        local keyX = ox + ew - keyW - 8
        local keyY = oy + (LAYOUT.rowH - 12) / 2
        local hov = inRect(mouse.x, mouse.y, keyX - 2, keyY, keyW + 4, 12)

        if self.phase == "picking" then
            local pulse = (math.sin(clk() * 8) + 1) / 2
            local pColor = lerpC3(COLORS.text, COLORS.accent, pulse)
            setProp(self.drawings.keyTx, "Color", pColor)
            setProp(self.drawings.keyTx, "Text", "[...]")
            -- Reposition for "..." text
            local dotW = textWidth("[...]") + 6
            local dotX = ox + ew - dotW - 8
            setProp(self.drawings.keyTx, "Position", Vector2.new(dotX + 1, keyY))
            setProp(self.drawings.keyBgOuter, "Position", Vector2.new(dotX - 2, keyY))
            setProp(self.drawings.keyBgOuter, "Size", Vector2.new(dotW + 4, 12))
            setProp(self.drawings.keyBgInner, "Position", Vector2.new(dotX - 1, keyY + 1))
            setProp(self.drawings.keyBgInner, "Size", Vector2.new(dotW + 2, 10))
        else
            setProp(self.drawings.keyTx, "Color", hov and COLORS.accent or COLORS.text)
            setProp(self.drawings.keyTx, "Text", keyStr)
            setProp(self.drawings.keyTx, "Position", Vector2.new(keyX + 1, keyY))
            setProp(self.drawings.keyBgOuter, "Position", Vector2.new(keyX - 2, keyY))
            setProp(self.drawings.keyBgOuter, "Size", Vector2.new(keyW + 4, 12))
            setProp(self.drawings.keyBgInner, "Position", Vector2.new(keyX - 1, keyY + 1))
            setProp(self.drawings.keyBgInner, "Size", Vector2.new(keyW + 2, 10))
        end

        if self.phase == "idle" then
            if hov and justClicked() then
                self.phase = "picking"
                self._mouseWait = true
            end

            -- Right-click to open mode dropdown (only if not hidden)
            if not self._hideModeSelector and hov and justRightClicked() then
                if self._modeDropdownOpen then
                    self:showModeDropdown(false)
                else
                    -- Close other open elements
                    if Lib._openDropdown then
                        Lib._openDropdown:showOptions(false)
                    end
                    if Lib._openColorpicker then
                        Lib._openColorpicker:showPanel(false)
                    end
                    if Lib._openKeybindModeDropdown and Lib._openKeybindModeDropdown ~= self then
                        Lib._openKeybindModeDropdown:showModeDropdown(false)
                    end
                    self:showModeDropdown(true)
                end
            end

            -- Handle mode dropdown interactions
            if self._modeDropdownOpen then
                local modeOptions = {"Hold", "Toggle", "Always"}
                local dropW = 60
                local dropH = 15
                local totalDropH = #modeOptions * dropH
                local dropStartY = oy + LAYOUT.rowH
                local clicked = false

                -- Update bottom border position
                setProp(self.drawings.modeBotBdr, "Position", Vector2.new(keyX, dropStartY + totalDropH))

                for i, modeName in ipairs(modeOptions) do
                    local dropY = dropStartY + (i - 1) * dropH
                    local dropHov = inRect(mouse.x, mouse.y, keyX, dropY, dropW, dropH)
                    local isSelected = (self.mode == modeName)

                    -- Update positions
                    setProp(self.modeDrawings[i].bg, "Position", Vector2.new(keyX, dropY))
                    setProp(self.modeDrawings[i].txt, "Position", Vector2.new(keyX + 4, dropY + 1))
                    setProp(self.modeDrawings[i].leftBdr, "Position", Vector2.new(keyX - 1, dropY))
                    setProp(self.modeDrawings[i].rightBdr, "Position", Vector2.new(keyX + dropW, dropY))
                    if self.modeDrawings[i].topBdr then
                        setProp(self.modeDrawings[i].topBdr, "Position", Vector2.new(keyX, dropY - 1))
                    end

                    -- Selected mode gets accent color text only
                    if isSelected or dropHov then
                        setProp(self.modeDrawings[i].txt, "Color", COLORS.accent)
                    else
                        setProp(self.modeDrawings[i].txt, "Color", COLORS.text)
                    end
                    -- Background stays same for all
                    setProp(self.modeDrawings[i].bg, "Color", COLORS.bg)

                    if dropHov and justClicked() then
                        self.mode = modeName
                        self:showModeDropdown(false)
                        clicked = true
                        break
                    end
                end
                -- Click outside to close
                if not clicked and justClicked() then
                    local dropdownArea = inRect(mouse.x, mouse.y, keyX, dropStartY, dropW, totalDropH)
                    if not dropdownArea then
                        self:showModeDropdown(false)
                    end
                end
            end

            -- Key polling is now handled globally in StartUpdateLoop, not here

        elseif self.phase == "picking" then
            if self._mouseWait then
                if not isHeld() then self._mouseWait = false end
                return
            end
            -- Skip mouse buttons and unknown keys
            local skipNames = {
                Unknown=true, MouseButton1=true, MouseButton2=true, MouseButton3=true,
                LeftMouse=true, RightMouse=true, MiddleMouse=true,
            }
            for _, code in ipairs(mouse.keys) do
                local name = keyToName(code)
                local skip = name and skipNames[name] == true
                if not skip and type(code) == "number" then
                    skip = (code == 0 or code == 1 or code == 2)
                end
                if not skip then
                    self:Set(code)
                    self.phase = "releasing"
                    return
                end
            end

        elseif self.phase == "releasing" then
            if not self:isBoundKeyHeld() then
                self.phase = "idle"
                self._prevKeyState = false
            end
        end
    end

    function el:pollKey()
        if self.phase == "idle" and self.key then
            local pressed = self:isBoundKeyHeld()
            if self.mode == "Toggle" then
                if pressed and not self._prevKeyState then
                    self.toggled = not self.toggled
                    print("[SevereUI] Toggle keybind", self._label, "toggled to:", self.toggled)
                    safeCall(self.callback, self.toggled)
                end
            elseif self.mode == "Hold" then
                if pressed ~= self._prevKeyState then
                    print("[SevereUI] Hold keybind", self._label, "state changed to:", pressed)
                    safeCall(self.callback, pressed)
                end
            elseif self.mode == "Always" then
                if pressed and not self._prevKeyState then
                    print("[SevereUI] Always keybind", self._label, "triggered")
                    safeCall(self.callback)
                end
            end
            self._prevKeyState = pressed
        elseif self.phase == "releasing" then
            if not self:isBoundKeyHeld() then
                self.phase = "idle"
                self._prevKeyState = false
            end
        end
    end

    function el:setVisible(v)
        bulkVisible(self.drawings, v)
        if not v and self._modeDropdownOpen then self:showModeDropdown(false) end
    end

    Lib.Flags[flag] = el.key
    Lib.SetFlags[flag] = function(k) el:Set(k) end
    table.insert(Lib._keybinds, el)
    sec:addElement(el)
    return el
end

----------------------------------------------------------------
-- TEXTBOX (dark box input, Thug Sense style)
----------------------------------------------------------------

function Lib:_makeTextbox(sec, opts)
    local flag = opts.Flag or ("x_" .. clk())
    local relY = sec.nextElemY
    local ox, oy = sec:elemOrigin(relY)
    local ew = sec:elemWidth()
    local boxH = LAYOUT.rowH + 10

    local titleW = textWidth(opts.Name or "Input") + 8
    local inputX = ox + titleW
    local inputW = ew - titleW

    local el = {
        height = boxH,
        relY = relY, sec = sec,
        flag = flag,
        val = opts.Default or "",
        placeholder = opts.Placeholder or "",
        callback = opts.Callback,
        active = false,
        cursorBlink = 0,
        cursorVisible = false,
        held = {},
        drawings = {},
        _titleW = titleW,
    }

    local displayText = el.val ~= "" and el.val or el.placeholder
    local textColor = el.val ~= "" and COLORS.text or COLORS.dim

    -- Title inline (left of input)
    el.drawings.title = makeObj("Text", { Text = opts.Name or "Input", Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.textSec, Position = Vector2.new(ox + 6, oy + (boxH - LAYOUT.fontSize) / 2), Visible = false, ZIndex = 15 })
    -- Input box outer
    el.drawings.boxOuter = makeObj("Square", { Size = Vector2.new(inputW, LAYOUT.rowH), Position = Vector2.new(inputX, oy + 5), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 14 })
    -- Input box inner
    el.drawings.boxInner = makeObj("Square", { Size = Vector2.new(inputW - 2, LAYOUT.rowH - 2), Position = Vector2.new(inputX + 1, oy + 6), Color = COLORS.bg, Filled = true, Visible = false, ZIndex = 15 })
    -- Text
    el.drawings.txt = makeObj("Text", { Text = displayText, Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = textColor, Position = Vector2.new(inputX + 6, oy + 5 + (LAYOUT.rowH - LAYOUT.fontSize) / 2), Visible = false, ZIndex = 16 })
    -- Cursor line
    local cursorX = inputX + 6 + textWidth(el.val)
    local cursorY = oy + 8
    el.drawings.cursor = makeObj("Square", { Size = Vector2.new(1, LAYOUT.fontSize), Position = Vector2.new(cursorX, cursorY), Color = COLORS.accent, Filled = true, Visible = false, ZIndex = 17 })

    function el:Set(val)
        self.val = val
        Lib.Flags[self.flag] = val
        local display = val ~= "" and val or self.placeholder
        local color = val ~= "" and COLORS.text or COLORS.dim
        setProp(self.drawings.txt, "Text", display)
        setProp(self.drawings.txt, "Color", color)
        local inputX = self.sec:elemOrigin(self.relY) + self._titleW
        local cursorX = inputX + 6 + textWidth(val)
        local oy = select(2, self.sec:elemOrigin(self.relY))
        setProp(self.drawings.cursor, "Position", Vector2.new(cursorX, oy + 8))
    end
    function el:Get() return self.val end

    function el:reposition()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        local inputX = ox + self._titleW
        local inputW = ew - self._titleW
        setProp(self.drawings.title, "Position", Vector2.new(ox + 6, oy + (self.height - LAYOUT.fontSize) / 2))
        setProp(self.drawings.boxOuter, "Position", Vector2.new(inputX, oy + 5))
        setProp(self.drawings.boxOuter, "Size", Vector2.new(inputW, LAYOUT.rowH))
        setProp(self.drawings.boxInner, "Position", Vector2.new(inputX + 1, oy + 6))
        setProp(self.drawings.boxInner, "Size", Vector2.new(inputW - 2, LAYOUT.rowH - 2))
        setProp(self.drawings.txt, "Position", Vector2.new(inputX + 6, oy + 5 + (LAYOUT.rowH - LAYOUT.fontSize) / 2))
        local cursorX = inputX + 6 + textWidth(self.val)
        setProp(self.drawings.cursor, "Position", Vector2.new(cursorX, oy + 8))
    end

    function el:update()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        local inputX = ox + self._titleW
        local inputW = ew - self._titleW
        local hov = inRect(mouse.x, mouse.y, inputX, oy + 5, inputW, LAYOUT.rowH)

        if justClicked() then
            local wasActive = self.active
            self.active = hov
            if self.active then
                setProp(self.drawings.boxOuter, "Color", COLORS.accent)
            else
                setProp(self.drawings.boxOuter, "Color", COLORS.dark)
            end
        end

        -- Cursor blink
        if self.active then
            if clk() - self.cursorBlink > 0.5 then
                self.cursorVisible = not self.cursorVisible
                self.cursorBlink = clk()
            end
            setVisible(self.drawings.cursor, self.cursorVisible)
        else
            setVisible(self.drawings.cursor, false)
        end

        -- Key input
        if self.active then
            local pressedNow = mouse.keys
            local shift = isShiftHeld()
            for _, code in ipairs(pressedNow) do
                local cid = tostring(code)
                if not self.held[cid] then
                    local r = resolveKey(code)
                    if r then
                        if r.isBackspace and #self.val > 0 then
                            self:Set(self.val:sub(1, -2))
                        elseif r.isEnter then
                            self.active = false
                            setProp(self.drawings.boxOuter, "Color", COLORS.dark)
                        elseif r.char and not r.isShift then
                            local ch = shift and r.upperChar or r.char
                            if ch then
                                self:Set(self.val .. ch)
                                self.cursorBlink = clk()
                                self.cursorVisible = true
                            end
                        end
                    end
                end
            end
            local newHeld = {}
            for _, code in ipairs(pressedNow) do newHeld[tostring(code)] = true end
            self.held = newHeld
        else
            self.held = {}
        end

        if self.active then
            safeCall(self.callback, self.val)
        end
    end

    function el:setVisible(v)
        bulkVisible(self.drawings, v)
        setVisible(self.drawings.cursor, false)
    end

    Lib.Flags[flag] = el.val
    Lib.SetFlags[flag] = function(val) el:Set(val) end
    sec:addElement(el)
    return el
end

----------------------------------------------------------------
-- LISTBOX (scrollable list with selectable items)
----------------------------------------------------------------

function Lib:_makeListbox(sec, opts)
    local flag = opts.Flag or ("lb_" .. clk())
    local relY = sec.nextElemY
    local ox, oy = sec:elemOrigin(relY)
    local ew = sec:elemWidth()
    local rows = opts.Rows or 8
    local lineH = 15
    local boxH = rows * lineH + 4
    local totalH = boxH

    local el = {
        height = totalH,
        relY = relY, sec = sec,
        flag = flag,
        items = opts.Items or {},
        selected = opts.Default or nil,
        callback = opts.Callback,
        scroll = 0,
        maxScroll = 0,
        rows = rows,
        lineH = lineH,
        boxH = boxH,
        drawings = {},
        itemDrawings = {},
    }

    -- Box border
    el.drawings.boxOuter = makeObj("Square", { Size = Vector2.new(ew, boxH), Position = Vector2.new(ox, oy), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 14 })
    el.drawings.boxInner = makeObj("Square", { Size = Vector2.new(ew - 2, boxH - 2), Position = Vector2.new(ox + 1, oy + 1), Color = COLORS.bg, Filled = true, Visible = false, ZIndex = 15 })

    -- Pre-create row drawings for visible rows
    for i = 1, rows do
        local ry = oy + 2 + (i - 1) * lineH
        local rd = {
            bg = makeObj("Square", { Size = Vector2.new(ew - 4, lineH), Position = Vector2.new(ox + 2, ry), Color = COLORS.bg, Filled = true, Visible = false, ZIndex = 16 }),
            txt = makeObj("Text", { Text = "", Size = LAYOUT.fontSize, Font = LAYOUT.font, Color = COLORS.text, Position = Vector2.new(ox + 6, ry + 1), Visible = false, ZIndex = 17 }),
        }
        el.itemDrawings[i] = rd
    end

    -- Scrollbar track
    el.drawings.scrollTrack = makeObj("Square", { Size = Vector2.new(3, boxH - 4), Position = Vector2.new(ox + ew - 6, oy + 2), Color = COLORS.dark, Filled = true, Visible = false, ZIndex = 16 })
    -- Scrollbar thumb
    el.drawings.scrollThumb = makeObj("Square", { Size = Vector2.new(3, 20), Position = Vector2.new(ox + ew - 6, oy + 2), Color = COLORS.accent, Filled = true, Visible = false, ZIndex = 17 })

    function el:SetItems(items)
        self.items = items
        self.maxScroll = max(0, #items - self.rows)
        self.scroll = clamp(self.scroll, 0, self.maxScroll)
        -- Clear selection if it no longer exists
        if self.selected then
            local found = false
            for _, it in ipairs(items) do
                if it == self.selected then found = true; break end
            end
            if not found then self.selected = nil end
        end
        Lib.Flags[self.flag] = self.selected
    end

    function el:Set(val)
        self.selected = val
        Lib.Flags[self.flag] = val
    end
    function el:Get() return self.selected end

    function el:reposition()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        setProp(self.drawings.boxOuter, "Position", Vector2.new(ox, oy))
        setProp(self.drawings.boxOuter, "Size", Vector2.new(ew, self.boxH))
        setProp(self.drawings.boxInner, "Position", Vector2.new(ox + 1, oy + 1))
        setProp(self.drawings.boxInner, "Size", Vector2.new(ew - 2, self.boxH - 2))
        setProp(self.drawings.scrollTrack, "Position", Vector2.new(ox + ew - 6, oy + 2))
        setProp(self.drawings.scrollTrack, "Size", Vector2.new(3, self.boxH - 4))
        for i = 1, self.rows do
            local ry = oy + 2 + (i - 1) * self.lineH
            setProp(self.itemDrawings[i].bg, "Position", Vector2.new(ox + 2, ry))
            setProp(self.itemDrawings[i].bg, "Size", Vector2.new(ew - 4, self.lineH))
            setProp(self.itemDrawings[i].txt, "Position", Vector2.new(ox + 6, ry + 1))
        end
    end

    function el:update()
        local ox, oy = self.sec:elemOrigin(self.relY)
        local ew = self.sec:elemWidth()
        self.maxScroll = max(0, #self.items - self.rows)
        self.scroll = clamp(self.scroll, 0, self.maxScroll)

        -- Update visible rows
        for i = 1, self.rows do
            local idx = self.scroll + i
            local rd = self.itemDrawings[i]
            local ry = oy + 2 + (i - 1) * self.lineH
            if idx <= #self.items then
                local item = self.items[idx]
                local isSel = (item == self.selected)
                local hov = inRect(mouse.x, mouse.y, ox + 2, ry, ew - 8, self.lineH)
                setProp(rd.txt, "Text", item)
                setProp(rd.bg, "Color", isSel and COLORS.surface or (hov and COLORS.surface2 or COLORS.bg))
                setProp(rd.txt, "Color", isSel and COLORS.accent or COLORS.text)
                setVisible(rd.bg, rd.bg.raw.Visible) -- keep current visibility
                setVisible(rd.txt, rd.txt.raw.Visible)

                if hov and justClicked() then
                    self.selected = item
                    Lib.Flags[self.flag] = item
                    safeCall(self.callback, item)
                end
            else
                setProp(rd.txt, "Text", "")
                setProp(rd.bg, "Color", COLORS.bg)
            end
        end

        -- Scrollbar
        if #self.items > self.rows then
            setVisible(self.drawings.scrollTrack, self.drawings.boxOuter.raw.Visible)
            local trackH = self.boxH - 4
            local thumbH = max(10, (self.rows / #self.items) * trackH)
            local thumbY = oy + 2 + (self.scroll / self.maxScroll) * (trackH - thumbH)
            setProp(self.drawings.scrollThumb, "Position", Vector2.new(ox + ew - 6, thumbY))
            setProp(self.drawings.scrollThumb, "Size", Vector2.new(3, thumbH))
            setVisible(self.drawings.scrollThumb, self.drawings.boxOuter.raw.Visible)
        else
            setVisible(self.drawings.scrollTrack, false)
            setVisible(self.drawings.scrollThumb, false)
        end

        -- Scroll with mouse clicks on track area
        if inRect(mouse.x, mouse.y, ox, oy, ew, self.boxH) then
            -- Simple scroll: right-click or use top/bottom halves
            if justClicked() and inRect(mouse.x, mouse.y, ox + ew - 8, oy, 8, self.boxH) then
                -- Click on scrollbar area
                local relY2 = mouse.y - oy
                if relY2 < self.boxH / 2 then
                    self.scroll = max(0, self.scroll - 1)
                else
                    self.scroll = min(self.maxScroll, self.scroll + 1)
                end
            end
        end
    end

    function el:setVisible(v)
        bulkVisible(self.drawings, v)
        for _, rd in ipairs(self.itemDrawings) do
            bulkVisible(rd, v)
        end
    end

    Lib.Flags[flag] = el.selected
    Lib.SetFlags[flag] = function(val) el:Set(val); safeCall(el.callback, val) end
    sec:addElement(el)
    return el
end

----------------------------------------------------------------
-- MAIN UPDATE LOOP
----------------------------------------------------------------

function Lib:StartUpdateLoop()
    if self._running then return end
    self._running = true

    createKeybindOverlay(self)

    self._renderConn = game:GetService("RunService").Render:Connect(function()
        pollInput()

        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                self._screenW = cam.ViewportSize.X
                self._screenH = cam.ViewportSize.Y
            end
        end)

        local homeNow = isKeyHeld(36) or isKeyHeld("Home") or isKeyHeld(Enum.KeyCode.Home)
        if homeNow and not self._prevHome then
            self._shown = not self._shown
            for _, w in ipairs(self.Windows) do w:SetVisible(self._shown) end
        end
        self._prevHome = homeNow

        tickAnims()

        for _, w in ipairs(self.Windows) do
            if w.visible then w:update() end
        end

        -- Poll all keybinds (always, regardless of window visibility)
        for _, kb in ipairs(self._keybinds) do
            kb:pollKey()
        end

        tickNotifications(self)
        tickKeybindOverlay(self)

        if self._watermark then self._watermark:update() end
    end)

    print("[SevereUI] Running - HOME key toggles menu")
end

function Lib:Unload()
    if self._renderConn then self._renderConn:Disconnect() end
    self._running = false
    for _, w in ipairs(self.Windows) do w:SetVisible(false) end
    if self._watermark then self._watermark:SetVisible(false) end
    for _, n in ipairs(self._notifList) do
        removeObj(n.bg); removeObj(n.bgInner); removeObj(n.titleTx); removeObj(n.msgTx); removeObj(n.barBg); removeObj(n.barFill)
    end
    if self._keybindOverlay then
        bulkVisible(self._keybindOverlay.drawings, false)
        for _, d in ipairs(self._keybindOverlay.entryDrawings) do removeObj(d) end
    end
    self._notifList = {}
    self._openDropdown = nil
    self._openColorpicker = nil
    print("[SevereUI] Unloaded")
end

return Lib
