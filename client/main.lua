local menu = { open = false, cam = nil, list = {} }
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

local function ShowMenu(isNew)
    if menu.open then return end
    local info = lib.callback.await('p07fspawn:open', false)
    if not info then return end
    menu.open = true
    menu.list = {}
    menu.last = info.last and not isNew and vec3(info.last.x, info.last.y, info.last.z) or nil
    if info.last and not isNew then menu.list[#menu.list + 1] = { id = 'last', label = 'Last location', sub = 'Where you left off' } end
    for _, l in ipairs(Config.locations) do menu.list[#menu.list + 1] = { id = l.id, label = l.label, sub = l.sub } end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    DisplayRadar(false)
    flyTo(menu.last or Config.locations[1].coords)
    SetNuiFocus(true, true)
    nui('open', { locations = menu.list })
    DoScreenFadeIn(800)
end

exports('ShowMenu', ShowMenu)
exports('IsMenuOpen', function() return menu.open end)

RegisterNUICallback('hover', function(d, cb)
    cb(1)
    if not menu.open then return end
    for _, l in ipairs(Config.locations) do
        if l.id == d.id then return flyTo(l.coords) end
    end
    if d.id == 'last' and menu.last then flyTo(menu.last) end
end)

RegisterNUICallback('spawn', function(d, cb)
    if not menu.open then return cb({ ok = false }) end
    local ok, c = lib.callback.await('p07fspawn:pick', false, d.id)
    if not ok then return cb({ ok = false }) end
    cb({ ok = true })
    menu.open = false
    SetNuiFocus(false, false)
    nui('close')
    DoScreenFadeOut(600)
    Wait(650)
    stopCam()
    local ped = PlayerPedId()
    RequestCollisionAtCoord(c.x, c.y, c.z)
    SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
    SetEntityHeading(ped, c.w or 0.0)
    local t = GetGameTimer() + 4000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < t do Wait(0) end
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    DisplayRadar(true)
    P7H.Framework.TriggerPlayerLoaded()
    DoScreenFadeIn(1000)
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= cache.resource or not menu.open then return end
    stopCam()
    SetNuiFocus(false, false)
    SetEntityVisible(PlayerPedId(), true, false)
    FreezeEntityPosition(PlayerPedId(), false)
end)
