--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

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


--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

function OnEventChatMessage( params )
    LogToChatColor( "AT_AutoAccept: OnEventChatMessage" )
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function Init()
    common.RegisterEventHandler( OnEventChatMessage, "EVENT_CHAT_MESSAGE" )
    LogToChatColor( "AT_AutoAccept: Initalized", "log_yellow" )
end

if avatar.IsExist() then
	Init()
else
	common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
end