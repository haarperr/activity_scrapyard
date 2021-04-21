Config = {}

Config.activity_name = "scrapyard_worker"
Config.activity_description = "Use a forklift to move wrecked cars around a scrapyard, salvage them for materials, and prepare them to be destroyed."

Config.default_cars_to_scrap = 7
Config.min_cars_to_scrap = 4
Config.max_cars_to_scrap = 9

Config.default_foreman_model = "s_m_m_cntrybar_01"

Config.minTime = 900000
Config.maxTime = 1800000
Config.random = true

Config.scrap_attempt_cooldown = 5000 -- Used to keep player from spamming part detection and creating lag

Config.yard_assign_fail_message = "The job fell through."
Config.car_spawn_fail_message = "There isn't enough room around the scrapyard for cars. Make sure it's clear of vehicles and come back later."
Config.forklift_spawn_fail_message = "There isn't enough room around the scrapyard for forklifts. Make sure it's clear of vehicles and come back later."
Config.activity_abandonded_message = "You abandonded the job."

Config.tasks = {}

Config.tasks[1] = { name = "go_to_yard", description = "Go to the scrapyard." }
Config.tasks[2] = { name = "ask_for_forklift", description = "Ask the foreman for a forklift." }
Config.tasks[3] = { name = "get_in_forklift", description = "Get in the forklift." }
Config.tasks[4] = { name = "pick_up_car", description = "Pick up the car." }
Config.tasks[5] = { name = "take_car_to_scrap", description = "Bring the car to the marked zone for scrapping." }
Config.tasks[6] = { name = "scrap_car", description = "Scrap the car of its tires, windows, doors, and engine." }
Config.tasks[7] = { name = "take_car_to_drop_off", description = "Take the car to the drop-off for destruction." }
Config.tasks[8] = { name = "return_forklift", description = "Return your forklift to the marked area." }