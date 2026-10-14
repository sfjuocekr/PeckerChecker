PeckerChecker = LibStub("AceAddon-3.0"):NewAddon(
    "PeckerChecker",
    "AceConsole-3.0",
    "AceEvent-3.0"
)


local peckerMessages = {
    joined = {
        "%n just joined the guild with a %p sized pecker!",
        "%n has joined the guild and has a %p sized pecker!",
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
local guildMessages = {}
local rosterInitialized = false


function PeckerChecker:OnInitialize()
    self:RegisterEvent("PLAYER_LOGIN", "OnPlayerLogin")
end


function PeckerChecker:OnPlayerLogin()
    self:UnregisterEvent("PLAYER_LOGIN")

    if IsInGuild() then
        self:RegisterEvent("CHAT_MSG_GUILD", "OnChatMsgGuild")
        self:RegisterEvent("GUILD_ROSTER_UPDATE", "OnGuildRosterUpdate")

        C_GuildInfo.GuildRoster()
    end

    self:RegisterEvent("PLAYER_GUILD_UPDATE", "OnPlayerGuildUpdate")
end


function PeckerChecker:OnPlayerGuildUpdate()
    if IsInGuild() then
        self:RegisterEvent("CHAT_MSG_GUILD", "OnChatMsgGuild")
        self:RegisterEvent("GUILD_ROSTER_UPDATE", "OnGuildRosterUpdate")

        C_GuildInfo.GuildRoster()
    else
        self:UnregisterEvent("CHAT_MSG_GUILD")
        self:UnregisterEvent("GUILD_ROSTER_UPDATE")
    end
end


-- Deterministic hash: the same GUID and secret produce the same result.
function PeckerChecker:GeneratePecker(guid, level)
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
    local baseScore = (hash % 15) + 1

    -- Level bonus: 0-6, capped at level 60.
    local levelBonus = math.min(6, math.floor((level or 0) / 10))

    return baseScore + levelBonus
end


function PeckerChecker:CreateGuildMember(name, level, guid)
    return {
        name = name,
        level = level,
        pecker = self:GeneratePecker(guid, level),
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


function PeckerChecker:HandleGuildMessage(text, playerName)
    if not text or text:lower():match("^%s*!pecker%s*$") == nil then
        return
    end

    for guid, member in pairs(guildMembers) do
        if member.name == playerName then
            if member.pecker then
                if guid == UnitGUID("player") then
                    SendChatMessage("My pecker is size " .. member.pecker .. "!", "GUILD")
                else
                    --SendChatMessage(playerName .. " your pecker is size " .. member.pecker .. "!", "GUILD")
                    SendChatMessage(self:RandomMessage("pecker", {n = member.name, p = member.pecker}), "GUILD")
                end
            end

            return
        end
    end
end


function PeckerChecker:OnPlayerRegenEnabled()
    self:Print("COMBAT LOCKDOWN: " .. tostring(IsEncounterInProgress()))

    self:UnregisterEvent("PLAYER_REGEN_ENABLED")

    for index, value in ipairs(guildMessages) do
        self:Print(tostring(index))
        self:Print(tostring(value))
        self:Print(tostring(issecretvalue(value[1])))
        self:Print(tostring(issecretvalue(value[2])))

        --self:HandleGuildMessage(value.text, value.playerName)
    end

    --guildMessages = {}
end


function PeckerChecker:OnChatMsgGuild(_, text, playerName)
    if issecretvalue(text) or issecretvalue(playerName) then
        return
    else
        self:HandleGuildMessage(text, playerName)
    end

    --[[if InCombatLockdown() then
        self:Print("COMBAT LOCKDOWN: " .. tostring(IsEncounterInProgress()))

        if not IsEncounterInProgress() then
            self:HandleGuildMessage(text, playerName)
        else
            self:Print("text" .. tostring(issecretvalue(text)))
            self:Print("playerName" .. tostring(issecretvalue(playerName)))

            table.insert(guildMessages, {text, playerName})

            self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayerRegenEnabled")
        end
    else
        self:Print("NO COMBAT LOCKDOWN")

        self:HandleGuildMessage(text, playerName)
    end]]
end


function PeckerChecker:OnGuildRosterUpdate()
    self:CheckPecker()

    if rosterInitialized then
        self:CheckLevelUp()
    end
end


function PeckerChecker:CheckPecker()
    local numMembers = GetNumGuildMembers()

    for i = 1, numMembers do
        local name, _, _, level, _, _, _, _, _, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)

        if guid then
            if rosterInitialized then
                if not guildMembers[guid] then
                    local pecker = self:GeneratePecker(guid, level)

                    guildMembers[guid] = self:CreateGuildMember(name, level, guid)

                    if guid == UnitGUID("player") then
                        SendChatMessage("I have joined the guild with a " .. pecker .. " sized pecker!", "GUILD")
                    else
                        --SendChatMessage(name .. " has joined the guild with a " .. pecker .. " sized pecker!", "GUILD")
                        SendChatMessage(self:RandomMessage("levelUp", {n = name, p = pecker}), "GUILD")
                    end
                end
            else
                local pecker = self:GeneratePecker(guid, level)

                guildMembers[guid] = {
                    name = name,
                    level = level,
                    pecker = pecker,
                }
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

        if not guid then
            return
        end

        local previousLevel = guildMembers[guid].level

        if isOnline then
            if level > previousLevel then
                --self:Print("Dinged: " .. name .. " " .. previousLevel .. " " .. level .. " " .. tostring(isOnline))

                local oldScore = guildMembers[guid].pecker
                local newScore = self:GeneratePecker(guid, level)

                if oldScore < newScore then
                    guildMembers[guid].pecker = newScore
                    guildMembers[guid].level = level

                    if guid == UnitGUID("player") then
                        C_ChatInfo.SendChatMessage("My pecker grew to " .. newScore .. "!", "GUILD")
                    else
                        --C_ChatInfo.SendChatMessage("Congratulations " .. name .. " your pecker grew to " .. newScore .. "!", "GUILD")
                        C_ChatInfo.SendChatMessage(self:RandomMessage("growUp", {n = name, p = newScore}), "GUILD")
                    end
                else
                    guildMembers[guid].level = level

                    if guid == UnitGUID("player") then
                        C_ChatInfo.SendChatMessage("Ding, level " .. level .. "!", "GUILD")
                    else
                        --C_ChatInfo.SendChatMessage("Gratz " .. name .. "!", "GUILD")
                        C_ChatInfo.SendChatMessage(self:RandomMessage("levelUp", {n = name, l = level}), "GUILD")
                    end
                end
            end
        end
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
