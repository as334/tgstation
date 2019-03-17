




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
	air.temperature -= (reaction_rate*20000)/air.heat_capacity()
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
			air.temperature = (air.temperature*old_heat_capacity - heat_stored)/new_heat_capacity
		return REACTING

/datum/gas_reaction/thraxx_reaction/energy_release //Releasing stored thermal energy
	name = "Lattice Energy Release"
	id = "thraxx_enerstore"
/datum/gas_reaction/thraxx_reaction/energy_release/init_reqs()
	min_requirements = list(
		"STATE" = 1000,
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
			air.temperature = (air.temperature*old_heat_capacity + heat_released)/new_heat_capacity
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
			air.temperature = (air.temperature*old_heat_capacity + energy_released)/new_heat_capacity
		return REACTING

//BZ and Tritium react endothermically and produce very small amounts of stimulum.
/datum/gas_reaction/thraxx_reaction/tritburn
	name = "Tritium+BZ Combustion"
	id = "thraxx_tritburn"
/datum/gas_reaction/thraxx_reaction/tritburn/init_reqs()
	min_requirements = list(
		/datum/gas/tritium = 30,
		/datum/gas/bz = 20,
		"TEMP" = 10000,
		"STATE" = 1000)

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
			air.temperature = (air.temperature*old_heat_capacity + energy_released)/new_heat_capacity
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
		"STATE" = 1000)

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
/datum/gas_reaction/thraxx_reaction/force_field //Creates unenterable square field, the edges are the curtains from twin peaks. Consumes N2 and energy as long as it exists

/datum/gas_reaction/thraxx_reaction/ //Hallucinations, BZ consumed. State corresponds to range, consumes thermal energy

/datum/gas_reaction/thraxx_reaction/ //Lightning, Stimulum consumed. State corresponds to range, consumes thermal energy

/datum/gas_reaction/thraxx_reaction/ //EMPs, Plasma catalyst. State corresponds to range/intensity, consumes thermal energy

/datum/gas_reaction/thraxx_reaction/ //Glowing, CO2 catalyst. State corresponds to brightness, consumes small amount of thermal energy.

/datum/gas_reaction/thraxx_reaction/ //Drain human life into thermal energy, consumes N2O+Miasma

/datum/gas_reaction/thraxx_reaction/ //Freeze local area, Consumes Noblium and thermal energy,state corresponds to range

/datum/gas_reaction/thraxx_reaction/ //Release radiation, Tritium catalyst. State corresponds to intensity, consumes thermal energy

/datum/gas_reaction/thraxx_reaction/ //Weak healing effect, Miasma+Pluoxium

/datum/gas_reaction/thraxx_reaction/ //Cheese?

//State weight modification reaction
/datum/gas_reaction/thraxx_reaction/modify_weights //Requires thraxxium