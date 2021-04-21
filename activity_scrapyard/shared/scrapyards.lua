scrapYards = {}

scrapYards.elBurro = {
	id = "el_burro",
	name = "El Burro Scrapyard",
	active = true,
	pos = vector3(1536.55, -2124.29, 76.89),
	activeRange = 5000.00,
	maxWorkers = 3,
	workers = {},
	foreman = { x = 1519.04, y = -2133.14, z = 76.66, heading = 358.77, model = "s_m_m_cntrybar_01" },
	liftSpawns = {
		{x = 1567.81, y = -2135.82, z = 77.04, heading = 108.07},
		{x = 1567.33, y = -2139.21, z = 77.1, heading = 79.82},
		{x = 1567.29, y = -2142.40, z = 77.1, heading = 96.09},
		{x = 1559.65, y = -2132.80, z = 76.92, heading = 199.16},
		{x = 1555.79, y = -2151.03, z = 76.97, heading = 171.67},
	},
	carSpawns = {
		{x = 1535.97, y = -2111.70, z = 76.93, heading = 360.00},
		{x = 1555.26, y = -2177.83, z = 77.33, heading = 344.27},
		{x = 1559.53, y = -2195.52, z = 77.66, heading = 196.33},
		{x = 1559.53, y = -2195.52, z = 77.66, heading = 196.33},
		{x = 1542.53, y = -2187.10, z = 77.34, heading = 171.35},
		{x = 1523.65, y = -2077.79, z = 77.22, heading = 160.31},
	},
	scrapZone = {x = 1558.29, y = -2194.44, z = 77.67, radius = 120.00},
	destroyZone = {x = 1507.30, y = -2138.38, z = 76.59, radius = 160.00},
	forkliftReturnZone = {x = 1560.05, y = -2140.72, z = 77.03, radius = 30.00},
}

scrapYards.rogers = {
	id = "rogers",
	name = "Rogers Salvage and Scrap",
	active = true,
	pos = vector3(-442.15, -1704.79, 18.88),
	activeRange = 5000.0,
	maxWorkers = 4,
	workers = {},
	foreman = { x = -425.17, y = -1698.52, z = 19.07, heading = 97.2, model = "s_m_m_cntrybar_01" },
	liftSpawns = {
		{ x = -449.74, y = -1717.48, z = 18.76, heading = 78.2 },
		{ x = -450.45, y = -1721.53, z = 18.65, heading = 49.9 },
		{ x = -453.05, y = -1723.93, z = 18.69, heading = 21.66 },
		{ x = -457.25, y = -1724.67, z = 18.69, heading = 96.64 },
	},
	carSpawns = {
		{ x = -469.21, y = -1669.62, z = 19.0, heading = 285.47 },
		{ x = -509.07, y = -1735.44, z = 19.09, heading = 351.77 },
		{ x = -500.36, y = -1700.5, z = 19.32, heading = 226.49 },
		{ x = -525.25, y = -1678.36, z = 19.24, heading = 272.26 },
		{ x = -542.51, y = -1681.27, z = 19.4, heading = 206.76 },
	},
	scrapZone = {x = -474.35, y = -1708.74, z = 18.72, radius = 150.00},
	destroyZone = {x = -524.03, y = -1720.54, z = 19.21, radius = 120.00},
	forkliftReturnZone = {x = -455.9, y = -1720.95, z = 18.68, radius = 50.00},
}