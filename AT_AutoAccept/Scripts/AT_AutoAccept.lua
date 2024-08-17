--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local settings = {}

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function LoadSettings()
    -- Try to load config. Default values if no config exists
    local temp = userMods.GetGlobalConfigSection( "AT_AutoAccept" )
    if temp then
        settings = temp
    else
        settings.invitePhrase = "++"
    end
    LogToChatColor( "AT_AutoAccept: Settings loaded. Current invite phrase is '" .. settings.invitePhrase .. "'. Change it with '/aa set <word>'", "log_yellow" )
end

function SaveSettings()
    -- Save current config
    userMods.SetGlobalConfigSection( "AT_AutoAccept", settings )
    LogToChatColor( "AT_AutoAccept: Settings saved. Current phrase is " .. settings.invitePhrase, "log_yellow" )
end


-- Log to the ingame chat
--@return nil
function LogToChatColor(text, color)
	local widgetChat = nil
	local valuedText = common.CreateValuedText()
	if not widgetChat then 
		widgetChat = stateMainForm:GetChildUnchecked("ChatLog", false)
		widgetChat = widgetChat:GetChildUnchecked("Container", true)
		local formatVT = "<html fontsize='18' fontname='AllodsSystem' outline='1'><rs class='color'><r name='addon'/><r name='text'/></rs></html>"
		valuedText:SetFormat(userMods.ToWString(formatVT))
	end
	if widgetChat and widgetChat.PushFrontValuedText then
		if not common.IsWString(text) then text = userMods.ToWString(text) end
		valuedText:ClearValues()
		valuedText:SetClassVal( "color", color)
		valuedText:SetVal( "text", text )
		widgetChat:PushFrontValuedText( valuedText )
	end
end

-- Check if playerName is member of the avatar's guild
--@params playerName string
function isInGuildList( playerName )
    local guildMembers = guild.GetMembers()
    for key, value in pairs( guildMembers ) do
        local memberInfo = guild.GetMemberInfo( value )
        if not memberInfo then
            goto continue
        end

        if ( memberInfo.name == playerName ) then
            return true
        end

        ::continue::
    end
    return false
end

-- Check if playerName is on the avatar's friend list
function isInFriendList( playerName )
    local friendList = social.GetFriendList()
    for key, value in pairs( friendList ) do
        local friendInfo = social.GetFriendInfo( value )
        if not friendInfo then
            goto continue
        end

        if ( friendInfo.name == playerName ) then
            return true
        end
        ::continue::
    end
    return false
end

function isFriendOrGuild( playerName )
    if ( isInGuildList( playerName ) ) then
        return true
    end
    
    if ( isInFriendList( playerName ) ) then
        return true
    end

    return false
end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

function OnEventChatMessage( params )
    -- Exclude message that are not whisper or guild chat
    local chatType = params.chatType -- number
    -- Whisper = 0, Guild = 9
    -- Filter out messages that are not guild or whisper chat
    if ( chatType ~= 0 and chatType ~= 9 ) then
        return
    end

    -- Filter out all messages from the avatar
    local sender = params.sender -- WString
    local avatarId = avatar.GetId() -- Number
    local avatarName = object.GetName( avatarId ) -- WString
    if ( sender == avatarName ) then
        return
    end

    -- Filter out all messages not containing the invitePhrase
    local message = params.msg --WString
    if ( userMods.FromWString( message ) ~= settings.invitePhrase ) then
        return
    end

    -- Groups and raids are handled identically
    if group.IsExist() then
        -- is group
        -- Check if we are allowed to invite players (i.e. group/raid leader or raid assistant)
        if not group.CanInvite() then
            return
        end

        -- Check if sender is in guild or on friend list and invite
        if isFriendOrGuild( sender ) then
            group.InviteByName( sender )
        end
    else
        -- is raid
        -- Check if we are allowed to invite players (i.e. group/raid leader or raid assistant)
        if not raid.CanInvite() then
            return
        end

        -- Check if sender is in guild or on friend list and invite
        if isFriendOrGuild( sender ) then
            raid.InviteByName( sender )
        end
    end
end

function OnEventGroupInvite( params )
    local inviter = params.inviterName

    if ( isFriendOrGuild( inviter ) ) then
        group.Accept()
    end
end

function OnEventRaidInvite( params )
    local inviter = params.inviterName

    if ( isFriendOrGuild( inviter ) ) then
        raid.Accept()
    end
end

function OnEventUnknownSlashCommand( params )
    -- Convert text to string
    local command = userMods.FromWString( params.text )
    if not command then
        return
    end

    -- Check if the command is for this addon
    if not string.starts( command, "/aa" ) then
        return
    end

    -- Split string at spaces in words
    local words = {}
    for word in command:gmatch("%S+") do
        table.insert( words, word)
    end

    -- Check if a command is specified
    if not words[2] then
        goto commandNotDefined
    end

    -- Check if command is "set"
    if words[2] ~= "set" then
        goto commandNotDefined
    end

    -- Check if an invitePhrase was specified
    if not words[3] then
        goto commandNotDefined
    end

    -- Update settings and save config
    settings.invitePhrase = words[3]
    SaveSettings()
    LogToChatColor( "AT_AutoAccept: New invite command: " .. words[3], "log_yellow" )
    goto done
    
    ::commandNotDefined::
    LogToChatColor( "AT_AutoAccept: Command not defined. Use '/aa set <word>' to set the invite command.", "log_yellow" )
    
    ::done::
    return
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function Init()
    common.RegisterEventHandler( OnEventChatMessage, "EVENT_CHAT_MESSAGE" )
    common.RegisterEventHandler( OnEventGroupInvite, "EVENT_GROUP_INVITE" )
    common.RegisterEventHandler( OnEventRaidInvite, "EVENT_RAID_INVITE" )
    common.RegisterEventHandler( OnEventUnknownSlashCommand, "EVENT_UNKNOWN_SLASH_COMMAND" )
    LoadSettings()
end

if avatar.IsExist() then
	Init()
else
	common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
end