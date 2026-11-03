local menu = { open = false, cam = nil, list = {}, coords = {}, isNew = false }
local C = Config.camera

local function nui(action, data) SendNUIMessage({ action = action, data = data }) end

--- aerial camera looking down at a point, flying from the current one
local function flyTo(c)
    local pos = vec3(c.x, c.y - C.back, c.z + C.height)
    local new = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, C.fov, false, 0)
    PointCamAtCoord(new, c.x, c.y, c.z)
    SetFocusPosAndVel(c.x, c.y, c.z, 0.0, 0.0, 0.0)
    if menu.cam then
        SetCamActiveWithInterp(new, menu.cam, C.moveMs, 1, 1)
        local old = menu.cam
        SetTimeout(C.moveMs + 100, function() DestroyCam(old, false) end)
    else
        SetCamActive(new, true)
        RenderScriptCams(true, false, 0, true, true)
    end
    menu.cam = new
end

local function stopCam()
    if not menu.cam then return end
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(menu.cam, false)
    menu.cam = nil
    ClearFocus()
end

local function add(id, label, sub, coords)
    menu.list[#menu.list + 1] = { id = id, label = label, sub = sub }
    if coords then menu.coords[id] = vec3(coords.x, coords.y, coords.z) end
end

local function ShowMenu(isNew)
    if menu.open then return end
    local info = lib.callback.await('p07fspawn:open', false, isNew == true)
    if not info then return end
    menu.open, menu.isNew, menu.list, menu.coords = true, isNew == true, {}, {}

    if #info.apartments > 0 then
        -- new character with qbx_properties: only the starting apartments
        for _, a in ipairs(info.apartments) do add(a.id, a.label, a.sub, a.coords) end
    else
        if info.last then add('last', 'Last location', 'Where you left off', info.last) end
        for _, p in ipairs(info.properties) do add(p.id, p.label, p.sub, p.coords) end
        for _, l in ipairs(Config.locations) do add(l.id, l.label, l.sub, l.coords) end
    end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    DisplayRadar(false)
    local first = menu.list[1] and menu.coords[menu.list[1].id] or Config.locations[1].coords
    flyTo(first)
    SetNuiFocus(true, true)
    nui('open', { locations = menu.list })
    DoScreenFadeIn(800)
end

exports('ShowMenu', ShowMenu)
exports('IsMenuOpen', function() return menu.open end)

RegisterNUICallback('hover', function(d, cb)
    cb(1)
    if not menu.open then return end
    local c = menu.coords[d.id]
    if c then flyTo(c) end
end)

--- the character is in the world: loaded events, clothing creator for new characters
local function finish(createLook)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    DisplayRadar(true)
    P7H.Framework.TriggerPlayerLoaded()
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    if menu.isNew and createLook then
        Wait(600)
        P7H.Appearance.OpenCreator()
    end
end

RegisterNUICallback('spawn', function(d, cb)
    if not menu.open then return cb({ ok = false }) end
    local ok, r = lib.callback.await('p07fspawn:pick', false, d.id)
    if not ok then return cb({ ok = false }) end
    cb({ ok = true })
    menu.open = false
    SetNuiFocus(false, false)
    nui('close')
    DoScreenFadeOut(600)
    Wait(650)
    stopCam()
    local ped = PlayerPedId()

    if r.apartment then
        -- qbx_properties creates the apartment, puts the player inside and opens the clothing creator
        SetEntityVisible(ped, true, false)
        P7H.Housing.SelectApartment({ index = r.apartment })
        local limit = GetGameTimer() + 6000
        while not lib.callback.await('p07fspawn:hasApartment', false) and GetGameTimer() < limit do Wait(300) end
        finish(false)
        Wait(500)
        DoScreenFadeIn(900)
        return
    end

    if r.house then
        P7H.Housing.Enter({ house = r.house })
        finish(true)
        DoScreenFadeIn(900)
        return
    end

    RequestCollisionAtCoord(r.x, r.y, r.z)
    SetEntityCoordsNoOffset(ped, r.x, r.y, r.z, false, false, false)
    SetEntityHeading(ped, r.w or 0.0)
    local t = GetGameTimer() + 4000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < t do Wait(0) end
    finish(true)
    DoScreenFadeIn(1000)
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= cache.resource or not menu.open then return end
    stopCam()
    SetNuiFocus(false, false)
    SetEntityVisible(PlayerPedId(), true, false)
    FreezeEntityPosition(PlayerPedId(), false)
end)
