_addon.name = 'actionlock'
_addon.version = '0.2'
_addon.author = 'yyoshisaur'
_addon.commands = {'actionlock', 'alock'}

require('logger')
local texts = require('texts')
local box = texts.new(
    '${count}',
    {
        text = {
            font = 'ＭＳ ゴシック',
            size = 12
        },
        pos = {
            x = 50,
            y = 125
        }
    }
)

local current_action = {
    time = os.clock(),
    lock_time = 0,  
}

local category_lock_time = {
    [2] = {time = 1, name = 'range'},
    [3] = {time = 3, name = 'ws'},
    [4] = {time = 3, name = 'spell'},
    [6] = {time = 1, name = 'ja'},
    [14] = {time = 1, name = 'dnc'},
    [15] = {time = 1, name = 'run'},
}

windower.register_event('action', function(act)
    local me = windower.ffxi.get_mob_by_target('me')
    if me and act.actor_id == me.id and category_lock_time[act.category] then
        current_action.time = os.clock()
        current_action.lock_time = category_lock_time[act.category].time
    end
end)

windower.register_event('prerender', function()
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

local help_text = [[* set countdown *
//actionlock spell/ws/ja/range time
//alock spell 2.5]]
windower.register_event('addon command', function(...)
    local args = {...}
    if args[1] and S{'range', 'ws', 'spell', 'ja'}:contains(args[1]) and args[2] then
        local cat = args[1]
        local time = tonumber(args[2])
        set_lock_time(cat, time)
    else
        log(help_text)
        log('* now settings *')
        local now_settings_text = L{}
        now_settings_text:append('spell:'..category_lock_time[4].time..'s')
        now_settings_text:append('ws:'..category_lock_time[3].time..'s')
        now_settings_text:append('ja:'..category_lock_time[6].time..'s')
        now_settings_text:append('range:'..category_lock_time[2].time..'s')
        log(now_settings_text:concat(' '))
    end
end)