#define PUMP_OUT 1//Pump gas out of the crystal into the tank
#define PUMP_IN 0 //Pump gas into the crystal out of the tank
/obj/machinery/computer/thraxxcrystal
	name = "crystal analysis computer"
	desc = "A computer with inbuilt gas and thraxxium crystal lattice manipulation systems."
	icon_screen = "scannercomp"
	icon_keyboard = "tech_key"
	var/pump_direction = PUMP_IN
	var/pump_on = FALSE
	var/max_pressure = 10*ONE_ATMOSPHERE
	var/obj/item/thraxx_crystal/crystal
	var/obj/item/tank/tank
	var/obj/machinery/atmospherics/components/binary/pump/internal_pump

/obj/machinery/computer/thraxxcrystal/attackby(obj/O, mob/user, params)
	if(istype(O, /obj/item/thraxx_crystal))
		var/obj/item/thraxx_crystal/insert_crystal = O
		if (!user.transferItemToLoc(insert_crystal,src))
			return
		crystal = insert_crystal
		updateUsrDialog()
	else if(istype(O, /obj/item/tank))
		var/obj/item/tank/insert_tank = O
		if (!user.transferItemToLoc(insert_tank,src))
			return
		tank = insert_tank
		updateUsrDialog()
	return ..()

obj/machinery/computer/thraxxcrystal/Initialize()
	. = ..()
	internal_pump = new(src, FALSE)
	internal_pump.on = pump_on
	internal_pump.stat = 0
	internal_pump.build_network()
/obj/machinery/computer/thraxxcrystal/proc/process_pump()
	if(!tank || !crystal)
		return
	// Hook up the internal pump.
	internal_pump.airs[1] = (pump_direction) ? crystal.air_contents : tank.air_contents
	internal_pump.airs[2] = (pump_direction) ? tank.air_contents : crystal.air_contents

	internal_pump.process_atmos() // Pump gas.

/obj/machinery/computer/thraxxcrystal/process()
	if(pump_on)
		process_pump()
	. = ..()


/obj/machinery/computer/thraxxcrystal/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = 0, datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state) // Remember to use the appropriate state.
  ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
  if(!ui)
    ui = new(user, src, ui_key, "thraxxcomputer", name, 400, 925, master_ui, state)
    ui.open()

/obj/machinery/computer/thraxxcrystal/ui_data(mob/user)
	var/list/data = list()
	data["on"] = pump_on
	data["pumpPressure"] = internal_pump.target_pressure
	data["max_pumpPressure"] = max_pressure
	data["hasCrystal"] = crystal ? TRUE : FALSE
	data["hasTank"] = tank ? TRUE : FALSE
	if(data["hasCrystal"])
		var/datum/gas_mixture/crystal_air = crystal.air_contents
		data["pressure"] = crystal_air.return_pressure()
		data["temperature"] = crystal_air.return_temperature()
		data["state"] = crystal.get_state()
		data["stored_energy"] = crystal.stored_energy
		data["gas_data"] = list()
		for(var/gas_id in crystal_air.gases)
			data["gas_data"] += list(
				"name" = crystal_air.gases[gas_id][GAS_META][META_GAS_NAME],
				"amount" = crystal_air.gases[gas_id][MOLES])
	if(data["hasTank"])
		data["tank"] = list()
		data["tank"]["name"] = tank.name
		data["tank"]["tankPressure"] = tank.air_contents.return_pressure()

	return data

/obj/machinery/computer/thraxxcrystal/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("eject")
			if(params["eject"] == "tank" && tank)
				tank.forceMove(drop_location())
				tank = null
				. = TRUE
			else if(params["eject"] == "crystal" && crystal)
				crystal.forceMove(drop_location())
				crystal = null
				. = TRUE
		if("power")
			pump_on = !pump_on
			internal_pump.on = pump_on
			. = TRUE
		if("pressure")
			var/pressure = params["pressure"]
			if(pressure == "max")
				pressure = max_pressure
				. = TRUE
			else if(pressure == "input")
				pressure = input("New output pressure (0-[max_pressure] kPa):", name, internal_pump.target_pressure) as num|null
				if(!isnull(pressure) && !..())
					. = TRUE
			else if(text2num(pressure) != null)
				pressure = text2num(pressure)
				. = TRUE
			if(.)
				internal_pump.target_pressure = CLAMP(pressure, 0, max_pressure)
	update_icon()
#undef PUMP_OUT
#undef PUMP_IN