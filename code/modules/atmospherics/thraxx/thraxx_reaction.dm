




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
	var/reaction_rate = min(cached_gases[/datum/gas/carbon_dioxide][MOLES]*0.75, cached_gases[/datum/gas/plasma][MOLES]*0.25, cached_gases[/datum/gas/oxygen_agent_b][MOLES]*0.05)
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
	var/heat_stored = air.temperature*cached_gases[/datum/gas/nitryl][MOLES]
	cached_gases[/datum/gas/nitryl][MOLES] = 0
	thraxx_crystal.stored_energy+=heat_stored
	if(heat_stored > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = (temperature*old_heat_capacity - heat_stored)/new_heat_capacity

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
			air.temperature = (temperature*old_heat_capacity + energy_released)/new_heat_capacity

/datum/gas_reaction/thraxx_reaction/fusion
	name = "Thraxx Crystal Internal Fusion"
	id = "thraxx_fusion"

/datum/gas_reaction/thraxx_reaction/fusion/init_reqs()
	min_requirements = list(
		"TEMP" = FUSION_TEMPERATURE_THRESHOLD,
		/datum/gas/tritium = FUSION_TRITIUM_MOLES_USED,
		/datum/gas/plasma = FUSION_MOLE_THRESHOLD,
		/datum/gas/carbon_dioxide = FUSION_MOLE_THRESHOLD)

/datum/gas_reaction/thraxx_reaction/fusion/react(/datum/gas_mixture/air,obj/item/thraxx_crystal/thraxx_crystal)
	SSair.gas_reactions
//Effect Reactions
/datum/gas_reaction/thraxx_reaction/ //Barriers

/datum/gas_reaction/thraxx_reaction/ //Hallucinations

/datum/gas_reaction/thraxx_reaction/ //Lightning

/datum/gas_reaction/thraxx_reaction/ //EMPs

/datum/gas_reaction/thraxx_reaction/ //Glowing


/datum/gas_reaction/thraxx_reaction/ //Drain human life into thermal energy

