AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		exports.ox_property:loadDataFiles()

		local properties = GlobalState['Properties']
		local displayedVehicles = MySQL.query.await('SELECT id, model, data FROM vehicles')

		local vehicles = {}
		for i = 1, #displayedVehicles do
			local vehicle = displayedVehicles[i]
			vehicle.data = json.decode(vehicle.data)

			if vehicle.data.display then
				local zone = properties[vehicle.data.display.property].zones[vehicle.data.display.zone]

				local veh = Ox.CreateVehicle(vehicle.id, zone.spawns[vehicle.data.display.id].xyz, zone.spawns[vehicle.data.display.id].w + vehicle.data.display.rotate and 180 or 0)
				veh.data = Ox.GetVehicleData(vehicle.model)

				vehicles[veh.plate] = veh
			end
		end

		GlobalState['DisplayedVehicles'] = vehicles

		Wait(1000)
		for k, v in pairs(vehicles) do
			FreezeEntityPosition(v.entity, true)
		end
	end
end)

RegisterServerEvent('ox_vehicledealer:buyWholesale', function(data)
	local player = Ox.GetPlayer(source)
	local zone = GlobalState['Properties'][data.property].zones[data.zoneId]

	if not exports.ox_property:isPermitted(player, zone) then return end

	-- TODO financial integration
	if true then
		Ox.CreateVehicle({
			model = 'stingergt',--data.model,
			owner = player.charid,
			stored = ('%s:%s'):format(data.property, data.zoneId)
		})
		TriggerClientEvent('ox_lib:notify', player.source, {title = 'Vehicle purchased', type = 'success'})
	else
		TriggerClientEvent('ox_lib:notify', player.source, {title = 'Vehicle transaction failed', type = 'error'})
	end
end)

RegisterServerEvent('ox_vehicledealer:sellWholesale', function(data)
	local player = Ox.GetPlayer(source)
	local zone = GlobalState['Properties'][data.property].zones[data.zoneId]

	if not exports.ox_property:isPermitted(player, zone) then return end

	-- TODO financial integration
	if true then
		MySQL.update.await('DELETE FROM vehicles WHERE plate = ?', {data.plate})
		TriggerClientEvent('ox_lib:notify', player.source, {title = 'Vehicle sold', type = 'success'})
	else
		TriggerClientEvent('ox_lib:notify', player.source, {title = 'Vehicle transaction failed', type = 'error'})
	end
end)

RegisterServerEvent('ox_vehicledealer:displayVehicle', function(data)
	local player = Ox.GetPlayer(source)
	local zone = GlobalState['Properties'][data.property].zones[data.zoneId]

	if not exports.ox_property:isPermitted(player, zone) then return end

	local vehicle = MySQL.single.await('SELECT id, model FROM vehicles WHERE plate = ? AND owner = ?', {data.plate, player.charid})

	if vehicle then
		vehicle.data = Ox.GetVehicleData(vehicle.model)
	end

	local spawn = exports.ox_property:findClearSpawn(zone.spawns, data.entities)

	if vehicle and spawn and zone.vehicles[vehicle.data.type] then
		local veh = Ox.CreateVehicle(vehicle.id, spawn.coords, spawn.heading)
		veh.data = vehicle.data

		veh.set('display', {property = data.property, zone = data.zoneId, id = spawn.id, rotate = spawn.rotate})

		local vehicles = GlobalState['DisplayedVehicles']
		vehicles[veh.plate] = veh
		GlobalState['DisplayedVehicles'] = vehicles

		TriggerClientEvent('ox_lib:notify', player.source, {title = 'Vehicle displayed', type = 'success'})

		Wait(1000)
		FreezeEntityPosition(veh.entity, true)
	else
		TriggerClientEvent('ox_lib:notify', player.source, {title = 'Vehicle failed to display', type = 'error'})
	end
end)

RegisterServerEvent('ox_vehicledealer:moveVehicle', function(data)
	local player = Ox.GetPlayer(source)
	local zone = GlobalState['Properties'][data.property].zones[data.zoneId]

	if not exports.ox_property:isPermitted(player, zone) then return end

	local vehicle = Ox.GetVehicle(GetVehiclePedIsIn(GetPlayerPed(player.source), false))
	local display = vehicle.get('display')

	if data.rotate then
		local heading = GetEntityHeading(vehicle.entity) + 180
		SetEntityHeading(vehicle.entity, heading)
		TriggerClientEvent('ox_lib:notify', player.source, {title = 'Vehicle rotated', type = 'success'})

		vehicle.set('display', {property = display.property, zone = display.zone, id = display.id, rotate = not display.rotate})
	else
		local spawn = exports.ox_property:findClearSpawn(zone.spawns, data.entities)

		if spawn then
			SetEntityCoords(vehicle.entity, spawn.coords.x, spawn.coords.y, spawn.coords.z)
			SetEntityHeading(vehicle.entity, spawn.heading)
			TriggerClientEvent('ox_lib:notify', player.source, {title = 'Vehicle moved', type = 'success'})

			vehicle.set('display', {property = display.property, zone = display.zone, id = spawn.id, rotate = spawn.rotate})
		else
			TriggerClientEvent('ox_lib:notify', player.source, {title = 'Vehicle failed to move', type = 'error'})
		end
	end
end)

RegisterServerEvent('ox_vehicledealer:buyVehicle', function(data)
	local player = Ox.GetPlayer(source)
	local vehicle = Ox.GetVehicle(GetVehiclePedIsIn(GetPlayerPed(player.source), false))
	-- TODO financial integration
	if true then
		MySQL.update.await('UPDATE vehicles SET owner = ?, stored = NULL WHERE plate = ?', {player.charid, vehicle.plate})
		local vehicles = GlobalState['DisplayedVehicles']
		vehicles[vehicle.plate] = nil
		GlobalState['DisplayedVehicles'] = vehicles

		local vehPos = GetEntityCoords(vehicle.entity)
		local vehHeading = GetEntityHeading(vehicle.entity)
		local passengers = {}
		local seats = Ox.GetVehicleData(vehicle.model).seats

		for i = -1, seats - 1 do
			local ped = GetPedInVehicleSeat(vehicle.entity, i)
			if ped ~= 0 then
				passengers[i] = ped
			end
		end

		vehicle.despawn()

		vehicle = Ox.CreateVehicle(vehicle.id, vehPos, vehHeading)
		for k, v in pairs(passengers) do
			SetPedIntoVehicle(v, vehicle.entity, k)
		end

		TriggerClientEvent('ox_lib:notify', player.source, {title = 'Vehicle purchased', type = 'success'})
	else
		TriggerClientEvent('ox_lib:notify', player.source, {title = 'Vehicle transaction failed', type = 'error'})
	end
end)

AddEventHandler('ox_property:vehicleStateChange', function(plate, action)
	local vehicles = GlobalState['DisplayedVehicles']
	vehicles[plate] = nil
	GlobalState['DisplayedVehicles'] = vehicles
end)
