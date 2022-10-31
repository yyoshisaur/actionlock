_addon.name = 'actionlock'
_addon.version = '0.1'
_addon.author = 'yyoshisaur'

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
    [2] = {time = 1, name = 'RANG'},
    [3] = {time = 3, name = 'WS'},
    [4] = {time = 3, name = 'SPELL'},
    [6] = {time = 1, name = 'JA'},
    [14] = {time = 1, name = 'DNC'},
    [15] = {time = 1, name = 'RUN'},
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