-- Prosody IM
-- Copyright (C) 2015 Periphery

-- unknown
local st = require "util.stanza";
-- unknown
local jid, datamanager = require "util.jid", require "util.datamanager";
-- unknown
local jid_prep = jid.prep;
-- retrieve current host
local module_host = module:get_host();
-- all hosts on the server
local hosts = prosody.hosts;
-- retrieve the module manager
local modulemanager = require"core.modulemanager";
-- depends on the groups module
module:depends("groups");
-- variable for all groups on host
local groups = module:shared("groups/groups");

-- Sends a message
function send_to_group(from, to, message)
	-- amount of people the message was sent to
	local c = 0;
	-- regex
	-- set message from variable to the sender of the message
	message.attr.from = from;
	-- loop all groups
	for groupName, members in pairs(groups) do
		-- find
		local s, e = groupName:find("/All");
		-- local groupname
		local gn = groupName:lower();
		-- if s != nil
		if s then
			gn = gn:sub(0, s - 1);
		end;
		-- is same group name?
		if gn == to:lower() then
			-- loop all users of the group
			for username in pairs(members) do
				-- set message to variable
				message.attr.to = username;
				-- send
				module:send(message);
			end;
		end;
	end;
	-- return receiver count
	return c;
end

-- called when the module is loaded on the server
function module.load()
end

-- called when the module is unloaded from the server
function module.unload()
end

-- Ad-hoc command (XEP-0133)
--	Create the message input form for users
local dataforms_new = require "util.dataforms".new;
local message_layout = dataforms_new{
	title = "Send Annoucement to Group";
	instructions = "Fill out this form to send a message all\nmembers of a specific group.";

	{ name = "FORM_TYPE", type = "hidden", value = "http://jabber.org/protocol/admin" };
	{ name = "subject", type = "text-single", label = "Subject" };
	{ name = "group", type = "text-single", required = true, label = "Group Name" };
	{ name = "message", type = "text-multi", required = true, label = "Message" };
};

-- function that gets called by adhoc
function message_command_handler(self, data, state)
	if not state then
		-- Make the message pop-up box appear for user
		return { status = "executing", actions = {"next", "complete", default = "complete"}, form = message_layout }, "executing";
	else
		-- check if user cancelled the interaction
		if data.action == "cancel" then
			return { status = "canceled" };
		end
		-- retrieve all form fields
		local fields = message_layout:data(data.form);
		-- create the message WITH subject and message
		local message = st.message({type = "headline"}, fields.message):up()
			:tag("subject"):text(fields.subject or "Message");
		-- send message
		send_to_group(data.from, fields.group, message)
		-- return that function completed  
		return { status = "completed", info = ("Message sent to group (%s)!"):format(fields.group or "All") };
	end;
	return true;
end

-- load adhoc lib
local adhoc_new = module:require "adhoc".new;
-- create description of function
local descriptor = adhoc_new("Send Message to Group", "http://jabber.org/protocol/admin#group_announce", message_command_handler);
-- add to options list
module:provides("adhoc", descriptor);