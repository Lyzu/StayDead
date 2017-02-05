-- initialize addon
local addon_prefix = "StayDead"
RegisterAddonMessagePrefix(addon_prefix)

-- create frame
local events = CreateFrame("Frame", "StayDead_events")
local sync = CreateFrame("Frame", "StayDead_sync")

-- register events
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("GROUP_JOINED")
events:RegisterEvent("GROUP_LEFT")
events:RegisterEvent("PLAYER_DEAD")
sync:RegisterEvent("CHAT_MSG_ADDON")

-- disable addon by default
local status = "off";

-- hide function
function StayDead_Status()
    if (status == "on") then
        StaticPopup1Button1:Hide();
    end
    if  (status == "off") then
        StaticPopup1Button1:Show();
    end
end

-- fetch status of leader
function StayDead_fetch()
    -- raid
    if (IsInRaid(LE_PARTY_CATEGORY_HOME)) then
        for i=1,GetNumGroupMembers(),1 do
            name, rank = GetRaidRosterInfo(i);
            if (rank == 2) then
                SendAddonMessage(addon_prefix, "fetch:" .. UnitName("player"), "WHISPER", name);
            end
        end
    -- party
    elseif (IsInGroup(LE_PARTY_CATEGORY_HOME)) then
        for i=1,GetNumGroupMembers(),1 do
            if (UnitIsGroupLeader("party" .. i)) then
                SendAddonMessage(addon_prefix, "fetch:" .. UnitName("player"), "WHISPER", UnitName("party" .. i));
            end
        end    
    end
end

-- event handling
events:SetScript("OnEvent", function(self, event, arg1)
    -- fire on death
    if (event == "PLAYER_DEAD") then
        StayDead_Status();
    elseif (event == "GROUP_JOINED") then
        StayDead_fetch()
    elseif (event == "GROUP_LEFT") and (status == "on") then
        print("|cFF8753efStayDead|r disabled");
        status = "off"
    elseif (event == "PLAYER_LOGIN") then
        StayDead_fetch()
    end
end)

-- sync handling
sync:SetScript("OnEvent", function(self, event, prefix, message, channel, fullsender)
    if (event == "CHAT_MSG_ADDON") and (prefix == addon_prefix) then
        local sender = string.match(fullsender, "(%a*)-.*")
        local action, message = string.match(message, "(%a*):(.*)")

        -- receiving
        if (action == "sync") then
            if (UnitIsGroupLeader(sender)) then
                -- updating status
                if (message == "StayDead_on") and (status == "off") then
                    print("|cFF8753efStayDead|r enabled");
                    status = "on";
                elseif (message == "StayDead_off") and (status == "on") then
                    print("|cFF8753efStayDead|r disabled");
                    status = "off";
                end
            end
        -- fetching
        elseif (action == "fetch") then
            if (sender ~= nil) and (UnitInParty(sender))then
                SendAddonMessage(addon_prefix, "sync:" .. addon_prefix .. "_" .. status, "WHISPER", sender);
            end
        elseif (action == "res") then
            if (UnitIsGroupLeader(sender)) then
                RepopMe();
            end
        end
    end
end)

-- slash handler
local function handler(msg, editbox)
    if (msg == "status") then
        if (status == "on") then
            print("|cFF8753efStayDead|r is enabled");
        elseif (status == "off") then
            print("|cFF8753efStayDead|r is disabled");
        end
    else
        -- sync to others
        if (UnitIsGroupLeader("player")) then
            if (msg == "on") or (msg == "off") then
                SendAddonMessage(addon_prefix, "sync:" .. addon_prefix .. "_" .. msg, "RAID");
            elseif (msg == "res") then
                SendAddonMessage(addon_prefix, "res:all", "RAID");
            end
        -- restricted
        else
            print("You need to be leader to use this function.")
        end
    end
end

-- slash commands
SLASH_STAYDEAD1 = '/sd';
SlashCmdList["STAYDEAD"] = handler;
