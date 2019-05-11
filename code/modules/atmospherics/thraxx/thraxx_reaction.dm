




/datum/gas_reaction/thraxx_reaction/
	exclude = TRUE //Thraxx reactions shouldn't be happening through normal react() stuff

/datum/gas_reaction/thraxx_reaction/react(datum/gas_mixture/air, obj/item/thraxx_crystal/thraxx_crystal)
	return NO_REACTION

//Internal Reactions

/datum/gas_reaction/thraxx_reaction/carbon_conversion/ //Oxygen Agent B is back baby
	name = "Carbon Conversion"
	id = "thraxx_carbcon"
/datum/gas_reaction/thraxx_reaction/carbon_conversion/init_reqs()
	min_requirements = list(
		"TEMP" = 900,
		/datum/gas/carbon_dioxide = MINIMUM_MOLE_COUNT,
		/datum/gas/plasma = MINIMUM_MOLE_COUNT,
		/datum/gas/bz = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/thraxx_reaction/carbon_conversion/react(datum/gas_mixture/air, obj/item/thraxx_crystal/thraxx_crystal)
	var/list/cached_gases = air.gases
	var/reaction_rate = min(cached_gases[/datum/gas/carbon_dioxide][MOLES]*0.75, cached_gases[/datum/gas/plasma][MOLES]*0.25, cached_gases[/datum/gas/bz][MOLES]*0.05)
	cached_gases[/datum/gas/carbon_dioxide][MOLES] -= reaction_rate
	cached_gases[/datum/gas/bz][MOLES] -= reaction_rate*0.05
	ASSERT_GAS(/datum/gas/oxygen, air)
	cached_gases[/datum/gas/oxygen][MOLES] += reaction_rate
	air.temperature = min(air.temperature -((reaction_rate*20000)/air.heat_capacity()),TCMB)
	return REACTING


/datum/gas_reaction/thraxx_reaction/energy_store //Storing thermal energy
	name = "Lattice Energy Storage"
	id = "thraxx_enerstore"
/datum/gas_reaction/thraxx_reaction/energy_store/init_reqs()
	min_requirements = list(
		"TEMP" = 1000,
		/datum/gas/nitryl = 10)

/datum/gas_reaction/thraxx_reaction/energy_store/react(datum/gas_mixture/air, obj/item/thraxx_crystal/thraxx_crystal)
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/heat_stored = air.temperature*cached_gases[/datum/gas/nitryl][MOLES]*2000
	if(heat_stored > air.thermal_energy())
		return NO_REACTION
	cached_gases[/datum/gas/nitryl][MOLES] = 0
	thraxx_crystal.stored_energy+=heat_stored
	if(heat_stored > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = min((air.temperature*old_heat_capacity - heat_stored)/new_heat_capacity,TCMB)
		return REACTING

/datum/gas_reaction/thraxx_reaction/energy_release //Releasing stored thermal energy
	name = "Lattice Energy Release"
	id = "thraxx_enerstore"
/datum/gas_reaction/thraxx_reaction/energy_release/init_reqs()
	min_requirements = list(
		"STATE" = 10000,
		/datum/gas/nitrous_oxide = 10)

/datum/gas_reaction/thraxx_reaction/energy_release/react(datum/gas_mixture/air, obj/item/thraxx_crystal/thraxx_crystal)
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/heat_released = thraxx_crystal.stored_energy
	ASSERT_GAS(/datum/gas/nitryl,air)
	cached_gases[/datum/gas/nitryl][MOLES] += heat_released/2000
	thraxx_crystal.stored_energy-=heat_released
	if(heat_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = CLAMP((air.temperature*old_heat_capacity + heat_released)/new_heat_capacity,TCMB,INFINITY)
		return REACTING

/datum/gas_reaction/thraxx_reaction/fire //Mostly like normal plasma fire, but simpler.
	name = "Thraxx Crystal Internal Fire"
	id = "thraxx_fire"

/datum/gas_reaction/thraxx_reaction/fire/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST,
		/datum/gas/oxygen= MINIMUM_MOLE_COUNT,
		/datum/gas/plasma = MINIMUM_MOLE_COUNT,
	)

/datum/gas_reaction/thraxx_reaction/fire/react(datum/gas_mixture/air, obj/item/thraxx_crystal/thraxx_crystal)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/plasma_burned = 0.1*cached_gases[/datum/gas/plasma][MOLES]
	var/oxygen_burned = 0.04*cached_gases[/datum/gas/oxygen][MOLES]
	energy_released += FIRE_PLASMA_ENERGY_RELEASED*plasma_burned
	cached_gases[/datum/gas/plasma][MOLES]-=plasma_burned
	cached_gases[/datum/gas/oxygen][MOLES]-=oxygen_burned
	ASSERT_GAS(/datum/gas/carbon_dioxide,air)
	cached_gases[/datum/gas/carbon_dioxide][MOLES] += plasma_burned
	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = CLAMP((air.temperature*old_heat_capacity + energy_released)/new_heat_capacity,TCMB,INFINITY)
		return REACTING

//BZ and Tritium react endothermically and produce very small amounts of stimulum.
/datum/gas_reaction/thraxx_reaction/tritburn
	name = "Tritium+BZ Combustion"
	id = "thraxx_tritburn"
/datum/gas_reaction/thraxx_reaction/tritburn/init_reqs()
	min_requirements = list(
		/datum/gas/tritium = 30,
		/datum/gas/bz = 20,
		"TEMP" = 1000,
		"STATE" = 40000)

/datum/gas_reaction/thraxx_reaction/tritburn/react(datum/gas_mixture/air, obj/item/thraxx_crystal/thraxx_crystal)
	var/old_heat_capacity = air.heat_capacity()
	var/list/cached_gases = air.gases
	var/burn_ratio = cached_gases[/datum/gas/tritium][MOLES]/cached_gases[/datum/gas/bz][MOLES]
	var/tritium_burned
	if(burn_ratio > 1)
		tritium_burned = min(burn_ratio,cached_gases[/datum/gas/tritium][MOLES],thraxx_crystal.get_state()/500)
	else
		tritium_burned = min(cached_gases[/datum/gas/tritium][MOLES],(air.return_temperature()/10000)*burn_ratio)
	var/energy_released = FIRE_HYDROGEN_ENERGY_RELEASED*tritium_burned
	cached_gases[/datum/gas/tritium][MOLES] -= tritium_burned
	cached_gases[/datum/gas/bz][MOLES] -= tritium_burned*0.5
	ASSERT_GAS(/datum/gas/stimulum,air)
	cached_gases[/datum/gas/stimulum][MOLES] += tritium_burned/30
	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = CLAMP((air.temperature*old_heat_capacity + energy_released)/new_heat_capacity,TCMB,INFINITY)
		return REACTING


//The stimulum and pluoxium react to slightly open the lattice structure of the crystal, letting some gases, but not all, escape.
/datum/gas_reaction/thraxx_reaction/distill
	name = "Crystal Lattice Distillation"
	id = "thraxx_nobdistill"
/datum/gas_reaction/thraxx_reaction/distill/init_reqs()
	min_requirements = list(
		/datum/gas/stimulum = 10,
		/datum/gas/pluoxium = 10,
		"TEMP" = 20000,
		"STATE" = 5000)

/datum/gas_reaction/thraxx_reaction/distill/react(datum/gas_mixture/air, obj/item/thraxx_crystal/thraxx_crystal)
	var/list/cached_gases = air.gases
	var/turf/open/location = get_turf(thraxx_crystal)
	if(location)
		air.assert_gases(/datum/gas/nitrogen,/datum/gas/nitryl,/datum/gas/nitrous_oxide,/datum/gas/oxygen,/datum/gas/hypernoblium) //Gases containing Nitrogen, some of it gets caught in the lattice and turned into Noblium
		var/nitrogen_retained = (cached_gases[/datum/gas/nitrogen][MOLES]*2)+(cached_gases[/datum/gas/nitrous_oxide][MOLES]*2)+(cached_gases[/datum/gas/nitryl][MOLES])
		var/oxygen_released = (cached_gases[/datum/gas/nitrous_oxide][MOLES])+(cached_gases[/datum/gas/nitryl][MOLES]*2)
		cached_gases[/datum/gas/nitrogen][MOLES] = 0
		cached_gases[/datum/gas/nitrous_oxide][MOLES] = 0
		cached_gases[/datum/gas/nitryl][MOLES] = 0
		cached_gases[/datum/gas/oxygen][MOLES] += oxygen_released*0.5//Only half the amount because oxygen gas is diatomic
		location.assume_air(air.remove_ratio(1))//Release everything into the open air
		location.air_update_turf()
		cached_gases[/datum/gas/hypernoblium][MOLES] += nitrogen_retained*0.05 //All that's left is a little cold noblium
		air.temperature = TCMB
		return REACTING
	return NO_REACTION




//Effect Reactions
/datum/gas_reaction/thraxx_reaction/force_field //Creates unenterable square field Consumes N2 and energy as long as it exists
	name = "Crystal Force Field Projection"
	id = "thraxx_forcefield"
/datum/gas_reaction/thraxx_reaction/force_field/init_reqs()
	min_requirements = list(
		/datum/gas/nitrogen = 16,
		"ENER"= 160000,
		"STATE"=10000
	)
/datum/gas_reaction/thraxx_reaction/force_field/react(datum/gas_mixture/air, obj/item/thraxx_crystal/thraxx_crystal)
	var/list/cached_gases = air.gases
	var/turf/open/location = get_turf(thraxx_crystal)
	var/old_heat_capacity = air.heat_capacity()
	var/shields_created = 0
	var/range = 2
	if(location)
		//Very sketchy code for getting the edges of a square, stolen from fields.
		var/list/turf/field_turfs = list()
		for(var/turf/T in block(locate(location.x-range,location.y-range,location.z),locate(location.x+range, location.y+range,location.z)))
			field_turfs += T
		var/list/turf/edge_turfs = field_turfs.Copy()
		for(var/turf/T in block(locate(location.x-range+1,location.y-range+1,location.z),locate(location.x+range-1, location.y+range-1,location.z)))
			edge_turfs -= T

		for(var/T in edge_turfs)
			var/turf/turf = T
			if(locate(/obj/effect/forcefield/thraxxium) in turf)
				flick("purplesparkles", T)
			else
				new /obj/effect/forcefield/thraxxium(turf)
				shields_created++


		cached_gases[/datum/gas/nitrogen][MOLES] -= shields_created
		var/energy_used = 10000*shields_created
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = min((air.temperature*old_heat_capacity - energy_used)/new_heat_capacity,TCMB)
		return REACTING
	return NO_REACTION

/datum/gas_reaction/thraxx_reaction/psy_burst //Hallucinations, BZ consumed. State corresponds to range, consumes thermal energy
	name = "Psychic Field Burst"
	id = "thraxx_hallucinations"

/datum/gas_reaction/thraxx_reaction/psy_burst/init_reqs()
	min_requirements = list(
		/datum/gas/bz = 6
		"STATE" = 20000
	)
/datum/gas_reaction/thraxx_reaction/psy_burst/react(datum/gas_mixure/air, obj/item/thraxx_crystal/thraxx_crystal)
	var/list/cached_gases = air.gases
	var/turf/open/location = get_turf(thraxx_crystal)
	var/old_heat_capacity = air.heat_capacity()
	var/effect_range = 0.0001*thraxx_crystal.get_state()
	var/energy_used = thraxx_crystal.get_state();
	if(energy_used > air.thermal_energy())
		return NO_REACTION
	for(var/mob/carbon/C in orange(effect_range))
		if(cached_gases[/datum/gas/bz][MOLES] >= 1)
			C.hallucination += air.temperature/100
			cached_gases[/datum/gas/bz][MOLES]--
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.temperature = min((air.temperature*old_heat_capacity - energy_used)/new_heat_capacity,TCMB)
	return REACTING



/datum/gas_reaction/thraxx_reaction/lightning //Lightning, Stimulum consumed. State corresponds to range, consumes thermal energy
	name = "Static Energy Burst"
	id = "thraxx_lightning"
/datum/gas_reaction/thraxx_reaction/lightning/init_reqs()
	min_requirements = list(
		/datum/gas/stimulum = 2,
		"ENER" = 100000,
		"STATE" = 10000
	)
/datum/gas_reaction/thraxx_reaction/lightning/react(datum/gas_mixure/air, obj/item/thraxx_crystal/thraxx_crystal)
	var/list/cached_gases = air.gases
	var/turf/open/location = get_turf(thraxx_crystal)
	var/old_heat_capacity = air.heat_capacity()
	var/energy_consumed = 0.1 * air.thermal_energy()
	var/stimulum_consumed = thraxx_crystal.get_state()*0.0001
	if(stimulum_consumed > cached_gases[/datum/gas/stimulum][MOLES]
		return NO_REACTION
	tesla_zap(src,stimulum_consumed,energy_consumed*0.5)
	cached_gases[/datum/gas/stimulum][MOLES] -= stimulum_consumed
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.temperature = (air.temperature*old_heat_capacity - energy_consumed)/new_heat_capacity
	return REACTING
/*
/datum/gas_reaction/thraxx_reaction/emp //EMPs, Plasma catalyst. State corresponds to range/intensity, consumes thermal energy

/datum/gas_reaction/thraxx_reaction/glow //Glowing, CO2 catalyst. State corresponds to brightness, consumes small amount of thermal energy.

/datum/gas_reaction/thraxx_reaction/life_drain //Drain human life into thermal energy, consumes N2O+Miasma

/datum/gas_reaction/thraxx_reaction/chill_out //Freeze local area, Consumes Noblium and thermal energy,state corresponds to range

/datum/gas_reaction/thraxx_reaction/rad_burst //Release radiation, Tritium catalyst. State corresponds to intensity, consumes thermal energy

/datum/gas_reaction/thraxx_reaction/life_gain //Weak healing effect, Miasma+Pluoxium

/datum/gas_reaction/thraxx_reaction/ //Cheese?

//State weight modification reaction
/datum/gas_reaction/thraxx_reaction/modify_weights //Requires thraxxium

*/