_addon.name = 'actionlock'
_addon.version = '0.4'
_addon.author = 'yyoshisaur'
_addon.commands = {'actionlock', 'alock'}

require('logger')
require("pack")

config = require('config')
local defaults = {
    enabled = true,
    timers = false,
    locktime = {
        range = 1,
        ws = 3,
        spell = 3,
        ja = 1,
        interruption = 3,
    },
    text = {
        pos = {
            x = 50,
            y = 125,
        },
        font = 'ＭＳ ゴシック',
        size = 12,
    }
}
local settings = config.load(defaults)

local texts = require('texts')
local box = texts.new(
    '${count}',
    {
        text = {
            font = settings.text.font,
            size = settings.text.size,
        },
        pos = {
            x = settings.text.pos.x,
            y = settings.text.pos.y,
        }
    }
)

local current_action = {
    time = os.clock(),
    lock_time = 0,  
}

local category_lock_time = {
    [2] = {time = settings.locktime.range, name = 'range'},
    [3] = {time = settings.locktime.ws, name = 'ws'},
    [4] = {time = settings.locktime.spell, name = 'spell'},
    [6] = {time = settings.locktime.ja, name = 'ja'},
    [8] = {time = settings.locktime.interruption, name = 'interruption'},
    [14] = {time = settings.locktime.ja, name = 'dnc'},
    [15] = {time = settings.locktime.ja, name = 'run'},
}

local me = nil
local spell_interruption = 28787

windower.register_event('load','login',function()
    me = windower.ffxi.get_player()
end)

windower.register_event('incoming chunk', function(id, original)
    if id == 0x28 then
        if not settings.enabled then return end
        local actor_id, target_count, action_category, param =  original:unpack('Ib10b4b16', 0x06)
        if me and actor_id == me.id and category_lock_time[action_category] then
            if action_category == 8 and param ~= spell_interruption then return end
            if settings.timers then
                local action_name = category_lock_time[action_category].name
                if action_category == 14 or action_category == 15 then
                    action_name = category_lock_time[6].name
                end
                local lock_time = category_lock_time[action_category].time
                local timers_commnad = '@timers c "'..action_name..'" '..lock_time..' down abilities/00088.png'
                windower.send_command(timers_commnad)
            else
                current_action.time = os.clock()
                current_action.lock_time = category_lock_time[action_category].time
            end
        end
    end
end)

windower.register_event('prerender', function()
    if not settings.enabled and settings.timers then 
        box:hide()
        return
    end 
    local timer_count = os.clock() - current_action.time
    local lock_time = current_action.lock_time
    if lock_time > timer_count then
        box.count = '%.2f':format(lock_time - timer_count)
        box:show()
    else
        box:hide()
    end
end)

function set_lock_time(cat, time)
    for k, v in pairs(category_lock_time) do
        if v.name == cat then
            category_lock_time[k].time = time
            if cat == 'ja' then
                category_lock_time[14].time = time
                category_lock_time[15].time = time
            end
            log('set '..cat..' = '..time)
        end
    end
end

function display_settings()
    local now_settings_text = L{}
    now_settings_text:append('spell:'..settings.locktime.spell..'s')
    now_settings_text:append('ws:'..settings.locktime.ws..'s')
    now_settings_text:append('ja:'..settings.locktime.ja..'s')
    now_settings_text:append('range:'..settings.locktime.range..'s')
    now_settings_text:append('spell interruption:'..settings.locktime.interruption..'s')
    log('* now settings *')
    log('enabled: '..tostring(settings.enabled))
    log('show timers: '..tostring(settings.timers))
    log(now_settings_text:concat(' '))
end

local help_text = [[* set countdown *
//actionlock spell/ws/ja/range time
//alock spell 2.5
* show/hide countdown *
//alock on/off
* show timers plugin *
//alock timers on/off
* save settings *
//alock save]]
windower.register_event('addon command', function(...)
    local args = {...}
    if S{'range', 'ws', 'spell', 'ja', 'interruption'}:contains(args[1]) and args[2] then
        local cat = args[1]
        local time = tonumber(args[2])
        if time then
            settings.locktime[cat] = time
            set_lock_time(cat, time)
        else
            error('invalid time.')
        end
    elseif S{'on', 'enable'}:contains(args[1]) then
        settings.enabled = true
        log('on')
    elseif S{'off', 'disable'}:contains(args[1]) then
        settings.enabled = false
        log('off')
    elseif args[1] == 'timers' then
        if S{'on', 'enable'}:contains(args[2]) then
            settings.timers = true
        elseif S{'off', 'disable'}:contains(args[2]) then
            settings.timers = false
        end
        log('timers: '..tostring(settings.timers))
    elseif args[1] == 'save' then
        settings:save()
        log('save settings.')
        display_settings()
    else
        log(help_text)
        display_settings()
    end
end)