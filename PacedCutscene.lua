--[[

    PacedCutscene - Based on Enternity by Hypnotoad & atom0s
    stepdialog method by @atom0s (from balloon addon)

    Automatically advances NPC dialog and cutscenes at a configurable pace
    instead of instantly skipping everything. Gives you time to read text
    while still being hands-free.

]]

addon.name      = 'PacedCutscene';
addon.author    = 'Redbaren';
addon.version   = '1.1';
addon.desc      = 'Advances NPC dialog automatically at a slower, configurable pace.';

require('common');
local chat = require('chat');
local ffi = require('ffi');

--[[
* stepdialog - Calls FFXI's internal TkEventMsg2::OnKeyDown to advance dialog.
* This is the same proven method used by the balloon addon (by @atom0s).
--]]
ffi.cdef[[
    typedef void (__thiscall* TkEventMsg2_OnKeyDown_f)(int32_t, int16_t, int16_t);
]]

local stepdialog = T{
    ptrs = T{
        func = ashita.memory.find('FFXiMain.dll', 0, '538B5C240856578B7C24148BF15753E8????????8B0D????????3BF174', 0, 0),
        this = ashita.memory.find('FFXiMain.dll', 0, '8B0D????????85C90F??????????8B410885C00F', 2, 0),
    },
};

local function advance_dialog()
    if (stepdialog.ptrs.func == nil or stepdialog.ptrs.func == 0 or
        stepdialog.ptrs.this == nil or stepdialog.ptrs.this == 0) then
        return false;
    end

    local ptr = ashita.memory.read_uint32(stepdialog.ptrs.this);
    if (ptr == nil or ptr == 0) then
        return false;
    end
    ptr = ashita.memory.read_uint32(ptr);
    if (ptr == nil or ptr == 0) then
        return false;
    end

    local func = ffi.cast('TkEventMsg2_OnKeyDown_f', stepdialog.ptrs.func);
    if (func == nil or func == 0) then
        return false;
    end

    func(ptr, 5, 0xFFFF);
    return true;
end

local PacedCutscene = T{
    enabled = true,
    delay = 1.0,            -- seconds to wait before advancing dialog
    waiting = false,         -- true when dialog is paused and we're counting down
    timestamp = 0,           -- when the current dialog pause was detected
    ignored = T{
        -- Causes dialog freezes..
        'Geomantic Reservoir',

        -- Requires specific timing..
        'Paintbrush of Souls',
        'Stone Picture Frame',
    },
    skip = false,            -- when false, lines with item/key item prompts are NOT auto-advanced
};

--[[
* Prints the addon help information.
*
* @param {boolean} isError - Flag if this function was invoked due to an error.
--]]
local function print_help(isError)
    if (isError) then
        print(chat.header(addon.name):append(chat.error('Invalid command syntax for command: ')):append(chat.success('/pcs')));
    else
        print(chat.header(addon.name):append(chat.message('Available commands:')));
    end

    local cmds = T{
        { '/pcs help',            'Displays the addon help information.' },
        { '/pcs on',              'Enables auto-advancing dialog.' },
        { '/pcs off',             'Disables auto-advancing dialog.' },
        { '/pcs delay <seconds>', 'Sets the delay between advances (0.3 - 10.0).' },
        { '/pcs skip',            'Toggles auto-skipping lines with items.' },
    };

    cmds:ieach(function (v)
        print(chat.header(addon.name):append(chat.error('Usage: ')):append(chat.message(v[1]):append(' - ')):append(chat.color1(6, v[2])));
    end);

    print(chat.header(addon.name):append(chat.message('Current delay: ')):append(chat.success(string.format('%.1f seconds', PacedCutscene.delay))));
    print(chat.header(addon.name):append(chat.message('Status: ')):append(chat.success(PacedCutscene.enabled and 'Enabled' or 'Disabled')));

    if (not stepdialog.ptrs:all(function(v) return v ~= nil and v ~= 0; end)) then
        print(chat.header(addon.name):append(chat.error('WARNING: stepdialog pointers not found. Dialog advance will not work.')));
    end
end

--[[
* event: command
* desc : Event called when the addon is processing a command.
--]]
ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or args[1] ~= '/pcs') then
        return;
    end

    e.blocked = true;

    -- Handle: /pcs help
    if (#args == 2 and args[2]:any('help')) then
        print_help(false);
        return;
    end

    -- Handle: /pcs on
    if (#args == 2 and args[2]:any('on')) then
        PacedCutscene.enabled = true;
        PacedCutscene.waiting = false;
        print(chat.header(addon.name):append(chat.message('Auto-advance: ')):append(chat.success('Enabled')));
        return;
    end

    -- Handle: /pcs off
    if (#args == 2 and args[2]:any('off')) then
        PacedCutscene.enabled = false;
        PacedCutscene.waiting = false;
        print(chat.header(addon.name):append(chat.message('Auto-advance: ')):append(chat.success('Disabled')));
        return;
    end

    -- Handle: /pcs delay <seconds>
    if (#args == 3 and args[2]:any('delay')) then
        local val = tonumber(args[3]);
        if (val and val >= 0.3 and val <= 10.0) then
            PacedCutscene.delay = val;
            print(chat.header(addon.name):append(chat.message('Delay set to: ')):append(chat.success(string.format('%.1f seconds', PacedCutscene.delay))));
        else
            print(chat.header(addon.name):append(chat.error('Delay must be between 0.3 and 10.0 seconds.')));
        end
        return;
    end

    -- Handle: /pcs skip
    if (#args == 2 and args[2]:any('skip')) then
        PacedCutscene.skip = not PacedCutscene.skip;
        print(chat.header(addon.name):append(chat.message('Skip items: ')):append(chat.success(PacedCutscene.skip and 'Enabled' or 'Disabled')));
        return;
    end

    print_help(true);
end);

--[[
* event: text_in
* desc : Detects when NPC dialog is waiting for input and queues auto-advance.
--]]
ashita.events.register('text_in', 'text_in_cb', function (e)
    if (e.blocked or not PacedCutscene.enabled) then
        return;
    end

    local mid = bit.band(e.mode_modified, 0x000000FF);

    -- Only care about NPC dialog modes (150, 151)
    if (mid ~= 150 and mid ~= 151) then
        return;
    end

    -- If skip is off, don't auto-advance lines with item/key item text
    if (not PacedCutscene.skip and e.message_modified:match(string.char(0x1E, 0x02))) then
        return;
    end

    -- Check ignored NPCs
    local target = GetEntity(AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0));
    if (target ~= nil and PacedCutscene.ignored:hasval(target.Name)) then
        return;
    end

    -- If this message has a wait-for-input prompt, queue an auto-advance
    if (e.message_modified:find(string.char(0x7F, 0x31))) then
        PacedCutscene.waiting = true;
        PacedCutscene.timestamp = os.clock();
    end
end);

--[[
* event: d3d_present
* desc : Frame callback used as a timer to auto-advance dialog after the configured delay.
--]]
ashita.events.register('d3d_present', 'present_cb', function ()
    if (not PacedCutscene.enabled or not PacedCutscene.waiting) then
        return;
    end

    -- Check if enough time has passed
    if (os.clock() - PacedCutscene.timestamp >= PacedCutscene.delay) then
        PacedCutscene.waiting = false;
        advance_dialog();
    end
end);
