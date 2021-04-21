# activity_scrapyard

# Description
Upon accepting a scrapyard job, the player is randomly assigned a scrapyard. After arriving at the scrapyard and requesting a forklift, the player will begin picking up cars around the scrapyard, scrapping them for materials, and taking the scrapped cars to a drop-off to be destroyed. The flow of the job is as follows:
1. Go to the scrapyard
2. Ask for a forklift
3. Scrap cars
  * Pick up car with forklift
  * Take car to the yard's scrap zone
  * Scrap the car's windows, doors, tires, and its engine
  * Take the car to the destroy zone
4. Return the forklift

## [Demo](https://streamable.com/w7f7r3)

## Config
**shared/scrapyards.lua** - Each scrapyard has many variables which can be changed, including where the cars can spawn, where the scrap/destroy zones are, how many workers can be active at a time, and more.

**config/cars.lua** - Cars are also configurable. The percentage of missing parts, likliness of impacts, which models can spawn, and how often each model can spawn can be changed.

**config/config.lua** - The activity's name, description, task info, and the number of cars to scrap per job can all be altered here.

# Performance
Performance was kept in mind during every step of creating this resource. The job itself operates on one linear thread, halting in between steps. Every car spawned during the job with also operates on a single thread which is used to let the player interact with it by picking it up, moving it around, and scrapping it. In my testing, I have not seen the script go above 0.09ms in the resource monitor while the job is active.

# Implementation
Implementation into NoPixel's activity framework should be relatively effortless. The activity uses the appropriate np-activities exports to ensure the activity begins and ends correctly, with each task updating in between. The main job and car threads' linear structure makes it really easy to change up the individual systems/steps or override portions of code with NoPixel's library functions.

# Exports
**startAcitivty** - This randomly assigns the given player to an available yard and begins the activity

**setActivityStatus** - This enables/disables the activity completely

**setLocationStatus** - This enables/disables a certain scrapyard, allowing/disallowing new players from being able to be assigned a job there

# Changes
There are some changes I would make if this were to be added to NoPixel. First, I am using a very basic way of checking player inputs by detecting when a player presses 'E' and using their current task to determine an appropriate action. The only times when a player needs to give input during the activity is when asking the foreman for a forklift (similar to a delivery or garbage job) and when scrapping cars. The foreman, the car the player is currently scrapping, the task they are currently on, and whether they have the ability to scrap a car can all be accessed as variables, which would make third-eye implementation very easy.

To scrap a car, the player only needs to press 'E' near a vehicle and wait out the duration of the animation. NoPixel's Quick Time Event system could easily be implemented, both to add a sense of actually taking time to scrap a part, and to determine the success of scrapping a part, if desired.

I soon plan to implement the gaining of materials after scrapping car parts. I left cars enterable to leave room for random items to be added to the glovebox/trunk of each car. This would allow players to search each car for money, random items, or even rare items such as NOS or flashdrives. 

# Notes
This was a very fun project to work on. Before taking on this task I had never made scripts for FiveM and was only limited to my knowledge from working on RedM for a few months. I haven't worked on RedM in a while, as my first freshman semester of college and other projects have been taking up most of my time. I plan to add to this project in between exams, refining it and ensuring it will work seamlessly with NoPixel's current system should you choose to add it. I wanted to go ahead and put the project out now to show that I have been putting a lot of effort into it when I can and that I am eager to be able to contribute more.
