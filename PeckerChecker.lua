local PeckerChecker = LibStub("AceAddon-3.0"):NewAddon(
    "PeckerChecker",
    "AceConsole-3.0",
    "AceEvent-3.0",
    "AceComm-3.0"
)


local peckerMessages = {
    joined = {
        "%n just joined the guild with a size %p pecker!",
        "%n has joined the guild and has a size %p pecker!",
        "%n weclome to the guild you have a size %p pecker!",
        "Welcome %n to the guild with a size %p pecker!",
        "Everyone say hello to %n with a size %p measured pecker!",
    },

    levelUp = {
        "Gratz %n on level %l!",
        "%n just reached level %l!",
        "Congratulations to %n for reaching level %l!",
        "A warm applause for %n who just leveled up to %l!",
        "A small celebration for %n who just dinged %l!",
    },

    growUp = {
        "Congratulations %n your pecker has grown to %p!",
        "Congratulations %n your pecker enlarged to %p!",
        "Behold the pecker of %n just erected to %p!",
        "Amazingly the pecker of %n just grew to %p!",
        "The pecker of %n achieved a new size of %p!",
    },

    pecker = {
        "%n your pecker is a measured size of %p!",
        "%n your pecker is size %p!",
        "%n your pecker measured %p!",
        "%n has a pecker measured %p!",
        "%n you have a size %p pecker!",
    }
}


local peckerSecret = 420
local guildMembers = {}
local rosterInitialized = false


local defaults = {
    global = {
        zoneTemperature = {},
    },
}


local peckerPeers = {}


function PeckerChecker:OnInitialize()
    self:Print("OnInitialize")

    self.db = LibStub("AceDB-3.0"):New(
        "PeckerCheckerDB",
        defaults
    )

    self:RegisterEvent("PLAYER_LOGIN", "OnPlayerLogin")
end


function PeckerChecker:OnEnable()
    self:Print("OnEnable")

    self:RegisterComm("PC_REG", "OnRegisterPeckerChecker")
    self:RegisterComm("PC_ROLL", "OnRollPeckerChecker")

    self:SendCommMessage(
        "PC_REG",
        UnitGUID("player"),
        "GUILD"
    )
end


function PeckerChecker:OnCommReceived(...)
    self:Print("OnCommReceived")

    for i = 1, select("#", ...) do
        local value = select(i, ...)
        self:Print(i .. ": " .. tostring(value))
    end
end


function PeckerChecker:OnRegisterPeckerChecker(_, message)
    self:Print("OnRegisterPeckerChecker")
    self:Print("Registered: " .. message)

    peckerPeers[message] = self:GeneratePecker(message)
end


function PeckerChecker:OnRollPeckerChecker(_, message)
    self:Print("OnRollPeckerChecker")
end


function PeckerChecker:OnPlayerLogin()
    self:UnregisterEvent("PLAYER_LOGIN")

    if IsInGuild() then
        self:RegisterEvent("CHAT_MSG_GUILD", "OnChatMsgGuild")
        self:RegisterEvent("CHAT_MSG_WHISPER", "OnChatMsgWhisper")
        self:RegisterEvent("GUILD_ROSTER_UPDATE", "OnGuildRosterUpdate")

        C_GuildInfo.GuildRoster()
    end

    self:RegisterEvent("PLAYER_GUILD_UPDATE", "OnPlayerGuildUpdate")
end


function PeckerChecker:OnPlayerGuildUpdate()
    if IsInGuild() then
        self:RegisterEvent("CHAT_MSG_GUILD", "OnChatMsgGuild")
        self:RegisterEvent("CHAT_MSG_WHISPER", "OnChatMsgWhisper")
        self:RegisterEvent("GUILD_ROSTER_UPDATE", "OnGuildRosterUpdate")

        C_GuildInfo.GuildRoster()
    else
        self:UnregisterEvent("CHAT_MSG_GUILD")
        self:UnregisterEvent("CHAT_MSG_WHISPER")
        self:UnregisterEvent("GUILD_ROSTER_UPDATE")
    end
end


-- PeckerRNG creates a deterministic hash: the same GUID and secret produce the same result.
function PeckerChecker:GeneratePecker(guid)
    if not guid then
        return nil
    end

    local hash = peckerSecret
    local modulus = 2147483647

    -- Hash every byte of the GUID.
    for i = 1, #guid do
        hash = (hash * 31 + string.byte(guid, i)) % modulus
    end

    -- Base score: 1-15.
    return (hash % 15) + 1
end


function PeckerChecker:HandleZoneTemperature(zone)
    if not zone or zone == "" then
        return 0
    end

    local zoneTemperature = self.db.global.zoneTemperature

    if zoneTemperature[zone] == nil then
        zoneTemperature[zone] = 0
    end

    return zoneTemperature[zone]
end


function PeckerChecker:AugmentPecker(pecker, level, zone)
    local levelBonus = math.min(math.floor((level) / 10), 6)
    local temperature = self:HandleZoneTemperature(zone)

    return pecker + temperature + levelBonus
end


function PeckerChecker:CreateGuildMember(isOnline, name, level, zone, guid)
    return {
        online = isOnline,
        name = name,
        level = level,
        zone = zone,
        pecker = self:GeneratePecker(guid),
    }
end


function PeckerChecker:FormatMessage(template, values)
    return (template:gsub("%%([a-z])", function(key)
        return tostring(values[key] or "%" .. key)
    end))
end


function PeckerChecker:RandomMessage(category, values)
    local options = peckerMessages[category]

    if not options or #options == 0 then
        return nil
    end

    return self:FormatMessage(options[math.random(#options)], values)
end


function PeckerChecker:GetKeyword(keyword, text)
    if text ~= nil then
        if not (text:lower():match("^%s*!" .. keyword .. "%s*$") == nil) then
            return true
        end
    end

    return nil
end


function PeckerChecker:HandleGuildMessage(text, playerName)
    if not self:GetKeyword("pecker", text) then
        return
    end

    for guid, member in pairs(guildMembers) do
        if member.name == playerName then
            local pecker = self:AugmentPecker(member.pecker, member.level, member.zone)

            if guid == UnitGUID("player") then
                C_ChatInfo.SendChatMessage("My pecker is size " .. pecker .. "!", "GUILD")
            else
                C_ChatInfo.SendChatMessage(self:RandomMessage("pecker", {n = member.name, p = pecker}), "GUILD")
            end

            return
        end
    end
end


function PeckerChecker:CheckPecker()
    local numMembers = GetNumGuildMembers()

    for i = 1, numMembers do
        local name, _, _, level, _, zone, _, _, isOnline, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)

        -- TODO: this just collects zone names for now.
        if zone then
            self:HandleZoneTemperature(zone)
        end

        if guid then
            if rosterInitialized then
                if not guildMembers[guid] then
                    guildMembers[guid] = self:CreateGuildMember(isOnline, name, level, zone, guid)

                    local pecker = self:AugmentPecker(guildMembers[guid].pecker, level, "")

                    if guid == UnitGUID("player") then
                        C_ChatInfo.SendChatMessage("I have joined the guild with a size " .. pecker .. " pecker!", "GUILD")
                    else
                        C_ChatInfo.SendChatMessage(self:RandomMessage("joined", {n = name, p = pecker}), "GUILD")
                    end
                else
                    if guildMembers[guid].name ~= name then
                        guildMembers[guid].name = name
                    end

                    if guildMembers[guid].zone ~= zone then
                        guildMembers[guid].zone = zone
                    end

                    if guildMembers[guid].online ~= isOnline then
                        guildMembers[guid].online = isOnline

                        if peckerPeers[guid] and not isOnline then
                            peckerPeers[guid] = nil
                        end
                    end
                end
            else
                guildMembers[guid] = self:CreateGuildMember(isOnline, name, level, zone, guid)
            end
        end
    end

    if not rosterInitialized then
        rosterInitialized = true
    end
end


function PeckerChecker:CheckLevelUp()
    local numMembers = GetNumGuildMembers()

    for i = 1, numMembers do
        local name, _, _, level, _, _, _, _, isOnline, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)
        local previousLevel = guildMembers[guid].level

        if guid then
            if isOnline then
                if level > previousLevel then
                    local oldScore = self:AugmentPecker(guildMembers[guid].pecker, previousLevel, "")
                    local newScore = self:AugmentPecker(guildMembers[guid].pecker, level, "")

                    guildMembers[guid].level = level

                    if oldScore < newScore then
                        if guid == UnitGUID("player") then
                            C_ChatInfo.SendChatMessage("My pecker grew to " .. newScore .. "!", "GUILD")
                        else
                            C_ChatInfo.SendChatMessage(self:RandomMessage("growUp", {n = name, p = newScore}), "GUILD")
                        end
                    else
                        if guid == UnitGUID("player") then
                            C_ChatInfo.SendChatMessage("Ding, level " .. level .. "!", "GUILD")
                        else
                            C_ChatInfo.SendChatMessage(self:RandomMessage("levelUp", {n = name, l = level}), "GUILD")
                        end
                    end
                end
            end
        end
    end
end


function IsRestrictedZone()
    local inInstance, instanceType = IsInInstance()
    local isPvP = inInstance and instanceType == "pvp"

    return isPvP
end


function PeckerChecker:OnChatMsgGuild(_, text, playerName)
    if issecretvalue(text) or issecretvalue(playerName) or IsRestrictedZone() then
        return
    else
        self:HandleGuildMessage(text, playerName)
    end
end


function PeckerChecker:OnChatMsgWhisper(_, text, playerName, _, _, _, _, _, _, _, _, _, guid)
    if issecretvalue(text) or issecretvalue(playerName) or IsRestrictedZone() then
        return
    else
        if self:GetKeyword("pecker", text) then
            C_ChatInfo.SendChatMessage("Your pecker is a size " .. self:GeneratePecker(guid), "WHISPER", nil, playerName)

            return
        end
    end
end


function PeckerChecker:OnGuildRosterUpdate()
    if IsRestrictedZone() then
        return
    end

    self:CheckPecker()

    if rosterInitialized then
        self:CheckLevelUp()
    end
end


function PeckerChecker:GetPeckerByName(playerName)
    for _, member in pairs(guildMembers) do
        if member.name == playerName then
            return member.pecker
        end
    end

    return nil
end


function PeckerChecker:GetTargetPecker()
    if UnitGUID("target") ~= nil then
        self:Print(self:GeneratePecker(UnitGUID("target")))
    end
end


function PeckerChecker:GetPlayerPecker()
    self:Print(self:GeneratePecker(UnitGUID("player")))
end


function PeckerChecker:PeckerDebug()
    for k, v in pairs(peckerPeers) do
        self:Print(k .. ": " .. v)
    end
end


PeckerChecker:RegisterChatCommand("pt", "GetTargetPecker")
PeckerChecker:RegisterChatCommand("pp", "GetPlayerPecker")
PeckerChecker:RegisterChatCommand("pd", "PeckerDebug")
