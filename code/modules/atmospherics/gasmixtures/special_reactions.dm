/proc/init_rad_gas_reactions()
	. = list()

	for(var/r in subtypesof(/datum/gas_reaction/radiation))
		var/datum/gas_reaction/reaction = r
		reaction = new r
		var/datum/gas/reaction_key
		for (var/req in reaction.min_requirements)
			if (ispath(req))
				var/datum/gas/req_gas = req
				if (!reaction_key || initial(reaction_key.rarity) > initial(req_gas.rarity))
					reaction_key = req_gas
		reaction.major_gas = reaction_key
		. += reaction
	sortTim(., /proc/cmp_gas_reaction)

/proc/init_nuke_ball_gas_reactions()
	. = list()
	for(var/r in subtypesof(/datum/gas_reaction/nuclear_particle))
		var/datum/gas_reaction/reaction = r
		reaction = new r
		var/datum/gas/reaction_key
		for (var/req in reaction.min_requirements)
			if (ispath(req))
				var/datum/gas/req_gas = req
				if (!reaction_key || initial(reaction_key.rarity) > initial(req_gas.rarity))
					reaction_key = req_gas
		reaction.major_gas = reaction_key
		. += reaction
	sortTim(., /proc/cmp_gas_reaction)

/datum/gas_reaction/radiation
	exclude = TRUE //These reactions are excluded so they aren't added to the normal list of reactions

/datum/gas_reaction/radiation/pluoxium_formation
	priority = 10
	name = "Pluoxium Formation"
	id = "pluox_formation"

/datum/gas_reaction/radiation/pluoxium_formation/init_reqs()
	min_requirements = list(
		"ENER" = 10000,
		/datum/gas/carbon_dioxide = 4,
		/datum/gas/oxygen = 2
	)

/datum/gas_reaction/radiation/pluoxium_formation/react(datum/gas_mixture/air, datum/holder)
	var/old_thermal_energy = air.thermal_energy()
	var/list/cached_gases = air.gases
	var/pluox_produced = min(old_thermal_energy/10000,4*cached_gases[/datum/gas/carbon_dioxide][MOLES],2*air.gases[/datum/gas/oxygen][MOLES],0)
	cached_gases[/datum/gas/oxygen][MOLES] -= 2*pluox_produced
	cached_gases[/datum/gas/carbon_dioxide][MOLES] -= 4*pluox_produced
	air.assert_gas(/datum/gas/pluoxium)
	air.gases[/datum/gas/pluoxium][MOLES]+=(pluox_produced)
	var/new_heat_capacity = air.heat_capacity()
	if(pluox_produced)
		air.temperature = CLAMP(old_thermal_energy/new_heat_capacity, TCMB, INFINITY)
		return REACTING


/datum/gas_reaction/nuclear_particle
	exclude = TRUE

/datum/gas_reaction/nuclear_particle/bluespace_shift
	priority = 5
	name = "Strangelet Catalyzed Bluespace Shift"
	id = "strange_collision"

/datum/gas_reaction/nuclear_particle/bluespace_shift/init_reqs()
	min_requirements = list(
		/datum/gas/strangelet_vapour = 200,
		/datum/gas/bz = 50
	)

/datum/gas_reaction/nuclear_particle/bluespace_shift/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/turf/open/location = get_turf(holder)
	var/old_thermal_energy = air.thermal_energy()

	air.assert_gases(/datum/gas/plasma,/datum/gas/carbon_dioxide,/datum/gas/nitrous_oxide,/datum/gas/nitryl)
	var/x_distance = 2*cached_gases[/datum/gas/plasma][MOLES] + -1*cached_gases[/datum/gas/carbon_dioxide][MOLES] + 3*cached_gases[/datum/gas/nitrous_oxide][MOLES] + -4*cached_gases[/datum/gas/nitryl][MOLES]
	var/y_distance = -1*cached_gases[/datum/gas/plasma][MOLES] + 5*cached_gases[/datum/gas/carbon_dioxide][MOLES] + 3*cached_gases[/datum/gas/nitrous_oxide][MOLES] + 4*cached_gases[/datum/gas/nitryl][MOLES]

	for(var/turf/open/T in view(cached_gases[/datum/gas/bz][MOLES]/50,location))
		if(T.air && T.air.gases[/datum/gas/strangelet_vapour] && T.air.gases[/datum/gas/strangelet_vapour][MOLES] > 200) //Only turfs with the required amount of strange gas have their contents teleported
			var/turf/open/teleported_turf = T
			var/turf/destination = get_offset_target_turf(teleported_turf, x_distance, y_distance)
			for(var/atom/movable/A in teleported_turf.contents)
				if(A.anchored)
					continue
				do_teleport(A,destination)
			teleported_turf.air.gases[/datum/gas/strangelet_vapour][MOLES] -= 200
	cached_gases[/datum/gas/bz][MOLES] = 0
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.temperature = CLAMP(old_thermal_energy/new_heat_capacity, TCMB, INFINITY)
	return REACTING

/datum/gas_reaction/nuclear_particle/particle_multiplication
	priority = -10 //Happens last so other reactions have a chance to exhaust the stranglet supply
	name = "Stranglet Nuclear Particle Chain Reaction"
	id = "strange_nuke_ball"

/datum/gas_reaction/nuclear_particle/particle_multiplication/init_reqs()
	min_requirements = list(
		/datum/gas/strangelet_vapour = 200
	)

/datum/gas_reaction/nuclear_particle/particle_multiplication/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/turf/open/location = get_turf(holder)
	var/old_heat_capacity = air.heat_capacity()

	var/ball_angle = (MODULUS(cached_gases[/datum/gas/strangelet_vapour][MOLES],200)/200)*360
	var/balls_fired = round(cached_gases[/datum/gas/strangelet_vapour][MOLES]/200)
	for(var/i in 1 to balls_fired)
		location.fire_nuclear_particle(ball_angle)
		ball_angle -= 45
	var/energy_released = 1000*balls_fired
	var/rad_power = energy_released/2000
	radiation_pulse(location,rad_power)
	cached_gases[/datum/gas/strangelet_vapour][MOLES] -= 200*balls_fired
	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = CLAMP((air.temperature*old_heat_capacity - energy_released)/new_heat_capacity,TCMB,INFINITY)
		return REACTING


/datum/gas_reaction/nuclear_particle/stimulum_tesla_burst
	priority = 4
	name = "Activated Stimulum Energy Burst"
	id = "stimtesla"

/datum/gas_reaction/nuclear_particle/stimulum_tesla_burst/init_reqs()
	min_requirements = list(
		/datum/gas/stimulum = 20,
		"TEMP" = 1000
	)

/datum/gas_reaction/nuclear_particle/stimulum_tesla_burst/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/turf/open/location = get_turf(holder)
	var/old_heat_capacity = air.heat_capacity()

	var/stimulum_used = min(air.temperature/50,cached_gases[/datum/gas/stimulum][MOLES])
	var/energy_released = stimulum_used*50
	tesla_zap(location, 0.1*stimulum_used, energy_released)
	cached_gases[/datum/gas/stimulum][MOLES] -= stimulum_used
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = CLAMP((air.temperature*old_heat_capacity - energy_released)/new_heat_capacity,TCMB,INFINITY)
	 	return REACTING

/datum/gas_reaction/nuclear_particle/light_burst
	priority = 5
	name = "Particle Catalyzed Photon Condensation"
	id = "lightburst"

/datum/gas_reaction/nuclear_particle/light_burst/init_reqs()
	min_requirements = list(
		/datum/gas/tritium = 50,
		/datum/gas/strangelet_vapour = 100,
		"ENER" = 30000
	)

/datum/gas_reaction/nuclear_particle/light_burst/react(datum/gas_mixture/air, datum/holder)
	var/list/cached_gases = air.gases
	var/turf/open/location = get_turf(holder)
	var/old_heat_capacity = air.heat_capacity()

	var/objects_glowed = round(cached_gases[/datum/gas/tritium][MOLES]/50)
	var/flash_range = round(cached_gases[/datum/gas/strangelet_vapour][MOLES]/20)

	var/energy_consumed = min(20000*objects_glowed + 2000*flash_range,air.thermal_energy())
	cached_gases[/datum/gas/tritium][MOLES] -= objects_glowed*50
	cached_gases[/datum/gas/strangelet_vapour][MOLES] -= flash_range*50

	location.flash_lighting_fx(flash_range,FLASH_LIGHT_POWER*objects_glowed,LIGHT_COLOR_GREEN)
	for(var/mob/living/C in view(flash_range, location))
		if(C.flash_act(affect_silicon = TRUE))
			C.Stun(60)
	for(var/atom/movable/A in location.contents)
		if(objects_glowed == 0)
			break
		A.set_light(5,8,LIGHT_COLOR_GREEN)

	if(energy_consumed)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.temperature = CLAMP((air.temperature*old_heat_capacity - energy_consumed)/new_heat_capacity,TCMB,INFINITY)
		return REACTING