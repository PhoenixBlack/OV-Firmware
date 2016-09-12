local index = 1
while true do
	local mads = io.open("data"..index..".mds", "r")
	if not mads then return end
	print("\nReading MADS data block "..index)
	
	-- Start parsing out data
	Defined = {}
	Name = {}
	Data = {}
	CurrentRow = {}
	LastTime = nil
	NumItems = 0
	while true do
		local cmd = mads:read(1)
		if not cmd then break end
		
		-- Data ID
		if cmd == "!" then
			local ItemID = mads:read("*n") or 0
			local ItemName = mads:read(8) or ""
			if ItemID+1 > NumItems then NumItems = ItemID+1 end
			if ItemID >= 0 then
				Name[ItemID] = ItemName
			end
			
			if not Defined[ItemID] then
				print("Item found: "..ItemID.." ("..ItemName..")")
				Defined[ItemID] = true
			end
		else
			local ItemID = string.byte(cmd)-58
			local ItemValue = mads:read("*n") or 0
			-- 0 1 .. 10 12 13 14 .. 42 44 45 46
			-- 0 1    10 11 12 13 .. 41 42 43 44
			if ItemID >= 44 then
				ItemID = ItemID-2
			elseif ItemID >= 12 then
				ItemID = ItemID-1
			end			
			if ItemID+1 > NumItems then NumItems = ItemID+1 end
			
			if (ItemID == 0) or (CurrentRow[ItemID]) then -- Time data, add a new row
				LastTime = ItemValue

				table.insert(Data, CurrentRow)
				CurrentRow = {}
				CurrentRow[0] = LastTime
			end
			CurrentRow[ItemID] = ItemValue
			
			if not Defined[ItemID] then
				print("Item found: "..ItemID.." (unknown)")
				Defined[ItemID] = true
			end
		end		
	end
	
	-- Add last row to CSV
	table.insert(Data, CurrentRow)
	
	-- Generate CSV file
	local csv = io.open("data"..index..".csv","w+")
	for n=0,NumItems-1 do
		csv:write((Name[n] or ("ITEM"..n))..",")
	end
	csv:write("\n")
	
	for i=1,#Data do
		for n=0,NumItems-1 do
			csv:write((Data[i][n] or "")..",")
		end
		csv:write("\n")
	end
	csv:close()
	
	
	mads:close()
	index = index + 1
end

