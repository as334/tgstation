
/obj/item/thraxx_crystal
	name = "thraxxium crystal"
	//Needs icons and a whole lot of other shit
	var/size = 1
	var/stored_energy = 0
	var/datum/gas_mixture/air_contents = null
	var/list/thraxx_reactions
	var/list/state_weights_internal = list(
		"temperature"=5,
		"pressure" = 3,
		"gas_power" = 2,
		"moles" = 3,
		"stored_energy"=0.1)

	var/list/state_weights_external = list(
		 //Temperature and moles are the actionable ones for changing external state. Temperature is weighted significantly higher because transferring heat isn't as big a deal as transfering gas.
		"temperature"=0.5,
		"moles" = 0.1,
		//These are external state properties that the crystal can't directly change.
		"pressure"= 0.5,
		"area" = 0.3,
		"lighting" = 100,
		"ectoplasm" = 10)

/obj/item/thraxx_crystal/Initialize()
	. = ..()

	air_contents = new(size*100)
	thraxx_reactions = init_reactions()
	START_PROCESSING(SSobj, src)

/obj/item/thraxx_crystal/process()
	thraxx_react()
	state_equalize()

/obj/item/thraxx_crystal/proc/init_reactions()
	var/list/reaction_types = list()
	for(var/r in subtypesof(/datum/gas_reaction/thraxx_reaction))
		var/datum/gas_reaction/thraxx_reaction/reaction = r
		reaction_types += reaction
	reaction_types = sortTim(reaction_types, /proc/cmp_gas_reactions, TRUE)

	. = list()
	for(var/path in reaction_types)
		. += new path

/obj/item/thraxx_crystal/proc/thraxx_react() //This is basically a simpler version of how normal gas mixtures proccess reactions, which we can get away with due to the significant relative rarity of thraxx crystals
	for(var/datum/gas_reaction/thraxx_reaction/reaction in thraxx_reactions)
		if(check_requirements(reaction))
			reaction.react(air_contents,src)




/obj/item/thraxx_crystal/proc/check_requirements(datum/gas_reaction/thraxx_reaction/reaction)
	var/list/min_reqs = reaction.min_requirements
	var/cached_gases = air_contents.gases
	if((min_reqs["TEMP"] && air_contents.temperature < min_reqs["TEMP"]) \
		|| (min_reqs["ENER"] && air_contents.thermal_energy() < min_reqs["ENER"]) \
		|| (min_reqs["STATE"] && get_state() < min_reqs["STATE"]))
		return FALSE
	for(var/id in min_reqs)
		if (id == "TEMP" || id == "ENER" || id == "STATE")
			continue
		if(!cached_gases[id] || cached_gases[id][MOLES] < min_reqs[id])
			return FALSE
	return TRUE

/obj/item/thraxx_crystal/proc/state_equalize()
	for(var/obj/item/thraxx_crystal/other_crystal in orange(get_state()/1000))
		var/state_delta = get_state() - other_crystal.get_state()
		if(state_delta > 1000)
			state_balance(other_crystal)
	if(get_state() > 4000)//If the state potential is still quite high and we can't distribute it to other crystals, we distribute to our surroundings.
		state_balance_external()


/obj/item/thraxx_crystal/proc/state_balance(obj/item/thraxx_crystal/other_crystal)
	var/datum/gas_mixture/other_air = other_crystal.air_contents
	//Try to balance internal states of the crystals
	var/state_delta = get_state() - other_crystal.get_state()

	var/temperature_delta = air_contents.return_temperature() - other_air.return_temperature()
	if(temperature_delta > 100)
		other_air.temperature_share(air_contents,0.5) //Try doing some temperature exchanging to reduce our difference
	state_delta = get_state() - other_crystal.get_state() //Recalibrate our state difference
	if(state_delta < 1000) //Equal enough, job done.
		return

	var/mole_delta = air_contents.total_moles() - other_air.total_moles()
	if(mole_delta > 10)
		other_air.merge(air_contents.remove_ratio(min(mole_delta/50,1)))
	air_contents.garbage_collect()
	state_delta = get_state() - other_crystal.get_state() //Recalibrate our state difference
	if(state_delta < 1000) //Equal enough, job done.
		return

	var/gas_power_delta = air_contents.gas_power() - other_air.gas_power()
	if(gas_power_delta > 100)
		//For this one we actually try and lower our own internal gas power by forming oxygen into pluoxium
		if(air_contents.gases[/datum/gas/oxygen] && air_contents.gases[/datum/gas/oxygen][MOLES] > 8)
			ASSERT_GAS(/datum/gas/pluoxium,air_contents)
			air_contents.gases[/datum/gas/pluoxium][MOLES] += air_contents.gases[/datum/gas/oxygen][MOLES]/4
			air_contents.gases[/datum/gas/oxygen][MOLES] = 0
			air_contents.garbage_collect()

	state_delta = get_state() - other_crystal.get_state() //Recalibrate our state difference
	if(state_delta > 4000) //If after all that it's still too large a difference, we'll have to reconcile our external differences, by teleporting to the same place.
		var/precision = 16000/state_delta //Higher difference means it's more imporant we end up in the same spot.
		do_teleport(src,other_crystal,precision)

/obj/item/thraxx_crystal/proc/state_balance_external()
	var/turf/open/location = get_turf(src)
	if(!location)
		return
	var/datum/gas_mixture/tile_air = location.return_air()
	if(!tile_air)
		return
	var/temperature_delta = abs(air_contents.return_temperature() - tile_air.return_temperature())
	if(temperature_delta > 1000)
		tile_air.temperature_share(air_contents,0.5)
	if(get_state() < 4000)
		return
	var/mole_delta = air_contents.total_moles() - tile_air.total_moles()
	if (mole_delta > 10)
		location.assume_air(air_contents.remove_ratio(min(mole_delta/50,1)))
	location.air_update_turf()
	air_contents.garbage_collect()
	if(get_state() > 10000)
		var/range = (get_state()/10000)
		explosion(get_turf(src), round(range), round(range*2), round(range*4), round(range*5))//If it's still too high, somethings fucked and might as well just end it all.

/obj/item/thraxx_crystal/proc/get_state()
	. = 0
	if(air_contents) //Internal state calculation
		. += air_contents.return_temperature() * state_weights_internal["temperature"]
		. += air_contents.return_pressure() * state_weights_internal["pressure"]
		. += air_contents.gas_power() * state_weights_internal["gas_power"]
		. += air_contents.total_moles() * state_weights_internal["moles"]
	var/turf/open/location = get_turf(src)
	if(location) //External state calculation
		var/datum/gas_mixture/tile_air = location.return_air()
		if(!tile_air || !tile_air.total_moles())
			return
		var/delta_temperature = abs(tile_air.return_temperature() - air_contents.return_temperature())
		var/delta_moles = abs(tile_air.total_moles() - air_contents.return_temperature())
		var/delta_pressure = abs(tile_air.return_pressure() - air_contents.return_pressure())
		. += delta_temperature * state_weights_external["temperature"]
		. += delta_moles * state_weights_external["moles"]
		. += delta_pressure * state_weights_external["pressure"]
		if(location.loc)
			var/area/crystal_area = location.loc
			. += crystal_area.thraxxium_crystal_state_change * state_weights_external["area"]
		. += location.get_lumcount() * state_weights_external["lighting"]
		. += GLOB.dead_mob_list.len * state_weights_external["ectoplasm"]


