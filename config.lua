Config = {}

Config.lastLocation = true    -- first entry: where the character logged out

-- housing (qbx_properties, ps-housing, qb-houses through Project7H_Lib)
Config.housing = true         -- new characters pick a starting apartment (qbx_properties)
Config.properties = true      -- owned properties are listed as spawn points

-- label, small line under it, where you appear
Config.locations = {
    { id = 'legion', label = 'Legion Square', sub = 'City centre', coords = vec4(195.17, -933.77, 30.69, 144.5) },
    { id = 'airport', label = 'Los Santos Airport', sub = 'Arrivals', coords = vec4(-1037.7, -2737.6, 20.17, 330.0) },
    { id = 'pier', label = 'Del Perro Pier', sub = 'Beach front', coords = vec4(-1604.6, -1050.1, 13.02, 50.0) },
    { id = 'sandy', label = 'Sandy Shores', sub = 'Blaine County', coords = vec4(1836.5, 3672.9, 34.28, 210.0) },
    { id = 'paleto', label = 'Paleto Bay', sub = 'North coast', coords = vec4(-160.5, 6390.4, 31.47, 45.0) },
}

-- the aerial camera over a location while it is picked
Config.camera = { height = 140.0, back = 120.0, fov = 45.0, moveMs = 1400 }
