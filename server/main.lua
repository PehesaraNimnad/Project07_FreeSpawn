--[[ Free spawn selector: the client sends an entry id, the server answers with where to go.
     Entries: 'last', a Config.locations id, 'prop:<id>' (owned property), 'apt:<index>' (starting apartment, new characters). ]]

local pending = {}   -- src -> { isNew, owned = { [id] = property } } while this player may pick

local function log(title, text, color)
    if SvConfig.webhook == '' then return end
    PerformHttpRequest(SvConfig.webhook, function() end, 'POST', json.encode({
        username = SvConfig.botName,
        embeds = { { title = title, description = text, color = color, timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ') } },
    }), { ['Content-Type'] = 'application/json' })
end

local byId = {}
for _, l in ipairs(Config.locations) do byId[l.id] = l end

local function housingOn()
    return Config.housing and P7H.Housing and P7H.Housing.Name() ~= 'none'
end

lib.callback.register('p07fspawn:open', function(src, isNew)
    if not P7H.Framework.IsLoaded(src) then return false end
    local citizenid = P7H.Framework.GetUniqueId(src)
    local state = { isNew = isNew == true, owned = {} }
    local out = { last = (Config.lastLocation and not state.isNew) and P7H.Framework.GetPosition(src) or false, properties = {}, apartments = {} }

    if housingOn() then
        -- qbx_properties: a new character must pick a starting apartment (else it opens its own picker)
        if state.isNew and P7H.Housing.Name() == 'qbx_properties' and not P7H.Housing.HasApartment(citizenid) then
            for _, a in ipairs(P7H.Housing.GetApartments({})) do
                out.apartments[#out.apartments + 1] = { id = 'apt:' .. a.index, label = a.label, sub = a.description or 'Starting apartment', coords = a.coords }
            end
        elseif not state.isNew and Config.properties then
            for _, p in ipairs(P7H.Housing.GetOwned(citizenid) or {}) do
                state.owned['prop:' .. p.id] = p
                out.properties[#out.properties + 1] = { id = 'prop:' .. p.id, label = p.label or 'Property', sub = 'Your property', coords = p.coords }
            end
        end
    end
    state.apartments = #out.apartments > 0
    pending[src] = state
    return out
end)

lib.callback.register('p07fspawn:pick', function(src, id)
    local state = pending[src]
    if not state or not P7H.Framework.IsLoaded(src) or type(id) ~= 'string' then return false end

    -- starting apartment: qbx_properties puts the player in it and opens the clothing creator
    local index = tonumber(id:match('^apt:(%d+)$'))
    if index then
        if not state.isNew or not state.apartments then return false end
        pending[src] = nil
        log('Spawned', ('**%s** picked starting apartment #%d'):format(GetPlayerName(src), index), 3447003)
        return true, { apartment = index }
    end
    -- a new character with apartments to pick may not skip them
    if state.apartments then return false end

    local coords, label
    if id == 'last' and Config.lastLocation and not state.isNew then
        local p = P7H.Framework.GetPosition(src)
        coords, label = p and vec4(p.x, p.y, p.z, p.w or 0.0), 'last location'
    elseif state.owned[id] then
        local p = state.owned[id]
        if p.house then
            pending[src] = nil
            return true, { house = p.house }
        end
        coords, label = p.coords and vec4(p.coords.x, p.coords.y, p.coords.z, p.coords.w or 0.0), p.label
    elseif byId[id] then
        coords, label = byId[id].coords, byId[id].label
    end
    if not coords then return false end
    pending[src] = nil
    log('Spawned', ('**%s** spawned at **%s**'):format(GetPlayerName(src), label or id), 3447003)
    return true, { x = coords.x, y = coords.y, z = coords.z, w = coords.w }
end)

lib.callback.register('p07fspawn:hasApartment', function(src)
    local citizenid = P7H.Framework.GetUniqueId(src)
    return citizenid ~= nil and P7H.Housing.HasApartment(citizenid)
end)

AddEventHandler('playerDropped', function() pending[source] = nil end)
