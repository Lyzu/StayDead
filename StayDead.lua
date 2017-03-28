-- initialize addon
local addon_prefix = "StayDead"
RegisterAddonMessagePrefix(addon_prefix)

-- create frame
local events = CreateFrame("Frame", "StayDead_events")
local sync = CreateFrame("Frame", "StayDead_sync")

-- register events
events:RegisterEvent("GROUP_JOINED")
events:RegisterEvent("GROUP_LEFT")
events:RegisterEvent("PLAYER_DEAD")
sync:RegisterEvent("CHAT_MSG_ADDON")

-- initialize mod and disable by default
if StayDeadDB == nil then
    StayDeadDB = { 
        mod = "off",
        personal = "off"
    }
end

-- functions to check or set mod
function setMod (mod)
    if (mod == "on") or (mod == "off") then
        StayDeadDB['mod'] = mod
        StayDeadDB['personal'] = mod
        isMod()
    end
end

function setPersonal (mod)
    if (mod == "on") or (mod == "off") then
        if mod ~= StayDeadDB['personal'] then
            StayDeadDB['personal'] = mod
            isMod()
        end
    end
end

function isMod (...)
    local mod = select(1, ...)
    local leader = StayDeadDB['mod']
    local personal = StayDeadDB['personal']
    local state = nil

    if (leader == "on") then
        state = leader
    else
        state = personal
    end
    
    if mod ~= nil then
        if (mod == state) then
            return true;
        else
            return false;
        end
    else
        if (state == "on") then
            print("|cFF8753ef" .. addon_prefix .. "|r enabled")
        elseif (state == "off") then
            print("|cFF8753ef" .. addon_prefix .. "|r disabled")
        end
    end
end

-- button function
function StayDead_button()
    -- always show button if Soulstone or Reincarnation is available
    if HasSoulstone() then
        StaticPopup1Button1:Show();

    -- hide button if addon is enabled
    else
        if isMod("on") then
            StaticPopup1Button1:Hide();
        else
            StaticPopup1Button1:Show();
        end
    end
end

-- fetch mod of leader
function StayDead_fetch()
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        prefix = "raid"
    else
        prefix = "party"
    end
    
    for i=1,GetNumGroupMembers(),1 do
        if (UnitIsGroupLeader(prefix .. i)) and (UnitName(prefix .. i) ~= UnitName("player")) then
            SendAddonMessage(addon_prefix, "fetch:" .. UnitName("player"), "WHISPER", UnitName(prefix .. i));
        end
    end
end

-- event handling
events:SetScript("OnEvent", function(self, event, arg1)
    if (event == "PLAYER_DEAD") then
        StayDead_button();
    elseif (event == "GROUP_JOINED") then
        StayDead_fetch()
    elseif (event == "GROUP_LEFT") and isMod("on") then
        setMod("off")
    end
end)

-- sync handling
sync:SetScript("OnEvent", function(self, event, prefix, message, channel, fullsender)
    if (prefix == addon_prefix) then
        local sender = string.match(fullsender, "(.*)-.*")
        local action, message = string.match(message, "(%a*):(.*)")
        -- receiving
        if (action == "sync") then
            if (UnitIsGroupLeader(sender)) then
                -- updating mod
                if (message == "StayDead_on") and isMod("off") then
                    setMod("on");
                elseif (message == "StayDead_off") and isMod("on") then
                    setMod("off");
                end
            end
        -- fetching
        elseif (action == "fetch") then
            if (sender ~= nil) and (UnitInParty(sender))then
                SendAddonMessage(addon_prefix, "sync:" .. addon_prefix .. "_" .. StayDeadDB['mod'], "WHISPER", sender);
            end
        -- releasing
        elseif (action == "release") then
            if (UnitIsGroupLeader(sender)) then
                RepopMe();
            end
        end
    end
end)

-- slash handler
local function handler(msg, editbox)
    if (msg == "status") then
        isMod()
    else
        -- leader
        if (UnitIsGroupLeader("player")) then
            if (msg == "on") or (msg == "off") then
                SendAddonMessage(addon_prefix, "sync:" .. addon_prefix .. "_" .. msg, "RAID");
            elseif (msg == "release") then
                SendAddonMessage(addon_prefix, "release:all", "RAID");
            end

        -- personal
        elseif GetNumGroupMembers() > 0 then
            if (msg == "on") or (msg == "off") then
                setPersonal(msg)
            elseif (msg == "release") then
                RepopMe();
            end
        
        -- without group
        else
            print("|cFF8753ef" .. addon_prefix .. "|r only works in a group.")
        end
    end
end

-- slash commands
SLASH_STAYDEAD1 = '/sd';
SlashCmdList["STAYDEAD"] = handler;
