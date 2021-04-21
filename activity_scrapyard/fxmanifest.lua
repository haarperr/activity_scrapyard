fx_version 'cerulean'
games { 'rdr3', 'gta5' }

version '1.0.0'

client_scripts {
	'config/config.lua',
	'config/cars.lua',
    	'shared/scrapyards.lua',
    	'client/main.lua',
	'client/util.lua',
	'client/yard.lua',
    	'client/car.lua',
    	'client/forklift.lua'
}

server_scripts {
	'shared/scrapyards.lua',
	'config/config.lua',
	'server/main.lua',
}
