#define	ENHANCE_REACTIONS	 "Enhance"
#define SUPRESS_REACTIONS	 "Supress"
#define SUMMON_FLAMES		 "Immolate"
#define CREATE_DESTROYER	 "Avenge"
#define SOW_MADNESS			 "Derange"
#define REWARD_FOLLOWERS	 "Reward"
#define SUMMON_WIND			 "Blow"
#define CHOKE				 "Suffocate"

SUBSYSTEM_DEF(plasmanimus)
	name = "Plasmanimus"
	init_order = INIT_ORDER_PLASMANIMUS
	priority = FIRE_PRIORITY_AIR
	wait = 2400 //Only needs to fire every four minutes

	var/moles = 0
	var/satiation = 0
	var/old_satiation = 0
	var/last_action = ENHANCE_REACTIONS
	var/list/actions = list(ENHANCE_REACTIONS = rand(0,40),SUPRESS_REACTIONS = rand(0,40),SUMMON_WIND = rand(0,40),SOW_MADNESS = rand(0,40), SUMMON_FLAMES = 0,CREATE_DESTROYER = 0,REWARD_FOLLOWERS = 0,CHOKE = 0)

/datum/controller/subsystem/plasmanimus/fire()
	actions[last_action] += satiation-old_satiation //Learn from the results of our last action, adjust our likely hood of action accordingly
	choose_action()


/datum/controller/subsystem/plasmanimus/proc/choose_action()
	old_satiation = satiation //Store how happy we are now before we do our next action
	var/action = pick(actions) //Weighted pick from the list of possible actions
	last_action = action
	switch(action)
		if(ENHANCE_REACTIONS) enhance_reactions()
		if(SUPRESS_REACTIONS) supress_reactions()
		if(SUMMON_FLAMES)	  summon_flames()
		if(CREATE_DESTROYER)  create_destroyer()
		if(SOW_MADNESS)		  sow_madness()
		if(REWARD_FOLLOWERS)  reward_followers()
		if(SUMMON_WIND)		  summon_wind()
		if(CHOKE)			  choke()

/datum/controller/subsystem/plasmanimus/proc/enhance_reactions()//Increase the energy output and efficiency of gas reactions. Generally positive

/datum/controller/subsystem/plasmanimus/proc/supress_reactions()//Decrease the energy output and efficiency of gas reactions. Generally negative

/datum/controller/subsystem/plasmanimus/proc/summon_flames() //Randomly create fires ranging from small to VERY LARGE. Negative

/datum/controller/subsystem/plasmanimus/proc/create_destroyer() //Give an individual objectives to destroy atmospherics and atmospherics technicians. Negative(Or positive if they're really fucking up)

/datum/controller/subsystem/plasmanimus/proc/sow_madness() //Create hallucinations,whispers, etc. to interact with the crew. Neutral

/datum/controller/subsystem/plasmanimus/proc/reward_followers() //Buff our followers(atmos techs, plasmamen, those who've breathed enough plasmanimus) Positive.

/datum/controller/subsystem/plasmanimus/proc/summon_wind() //Create random areas of extremely high pressure. Generally negative

/datum/controller/subsystem/plasmanimus/proc/choke() //Make people across the station unable to breath normal oxygen percentages

