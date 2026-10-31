--[[ Free spawn selector: the client sends a location id, the server answers with the coords. ]]

local pending = {}   -- src -> true while this player may pick a spawn (set when the menu opens for a loaded character)

local function log(title, text, color)
    if SvConfig.webhook == '' then return end
    PerformHttpRequest(SvConfig.webhook, function() end, 'POST', json.encode({
        username = SvConfig.botName,
        embeds = { { title = title, description = text, color = color, timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ') } },
    }), { ['Content-Type'] = 'application/json' })
end

local byId = {}
for _, l in ipairs(Config.locations) do byId[l.id] = l end

lib.callback.register('p07fspawn:open', function(src)
    if not P7H.Framework.IsLoaded(src) then return false end
    pending[src] = true
    return { last = Config.lastLocation and P7H.Framework.GetPosition(src) or false }
end)

lib.callback.register('p07fspawn:pick', function(src, id)
    if not pending[src] or not P7H.Framework.IsLoaded(src) then return false end
    local coords
    if id == 'last' and Config.lastLocation then
        local p = P7H.Framework.GetPosition(src)
        coords = p and vec4(p.x, p.y, p.z, p.w or 0.0)
    elseif type(id) == 'string' and byId[id] then
        coords = byId[id].coords
    end
    if not coords then return false end
    pending[src] = nil
    log('Spawned', ('**%s** spawned at **%s**'):format(GetPlayerName(src), id == 'last' and 'last location' or byId[id].label), 3447003)
    return true, { x = coords.x, y = coords.y, z = coords.z, w = coords.w }
end)

AddEventHandler('playerDropped', function() pending[source] = nil end)
