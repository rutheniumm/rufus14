NLS([[local tweenservice = game:GetService("TweenService")
local runservice = game:GetService("RunService")
local players = game:GetService("Players")
local horizon = Vector3.new(1,0,1)
local tool = script.Parent
local owner
local character
local charroot
local charhum
local charhead
local mouse 
local rayholder
local remote = tool:WaitForChild("fistremote")
local currentwelds = {} --dont repeat names
local ignoretable = {}
local currentattachments = {}
local horriblestates = {Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.FallingDown}
local trackmouseY = true
local trackmouselook = true
local holdinglmb = false

_G.fistvis = false --raycast hitbox visualizer (warning can lag)

parentfindfirstchildofclass = function(cname, search)
	local par = search
	local foundinstance
	while par ~= workspace and not foundinstance do
		foundinstance = par:FindFirstChildOfClass(cname)
		par = par.Parent
	end
	return foundinstance
end

starthitbox = function(attachmenttable, duration, multihit)
	if rayholder then
		rayholder:Disconnect()
	end
	local savetick = tick()
	local rayparams = RaycastParams.new()
	rayparams.FilterType = Enum.RaycastFilterType.Blacklist
	rayparams.FilterDescendantsInstances = ignoretable
	local lastattachpos = {}
	local hitpeople = {}
	for i,v in pairs(attachmenttable) do
		table.insert(lastattachpos, {v, v.WorldPosition})
	end
	rayholder = runservice.RenderStepped:Connect(function()
		--print("scanning "..attachmenttable[1].Parent.Name)
		if tick() >= savetick + duration or tool.Parent ~= character then
			rayholder:Disconnect()
		end
		for i,v in pairs(lastattachpos) do
			local subt = v[2] - v[1].WorldPosition
			local ray = workspace:Raycast(v[2], -subt.Unit*subt.Magnitude, rayparams)
			if ray then
				local findhum = parentfindfirstchildofclass("Humanoid", ray.Instance) or ray.Instance
				if multihit then
					if not table.find(hitpeople, findhum) then
						table.insert(hitpeople, findhum)
						remote:FireServer("part", ray.Instance, ray.Position, ray.Normal)
						--print("boom:")
					end
				else
					remote:FireServer("part", ray.Instance, ray.Position, ray.Normal)
					rayholder:Disconnect()
				end
			end
			if _G.fistvis then
				local raypos = v[2] + (-subt.Unit*subt.Magnitude)
				local p = Instance.new("Part", character)
				p.Anchored = true
				p.CanCollide = false
				p.Transparency = 0.8
				p.BrickColor = BrickColor.new("Lime green")
				p.Material = "Neon"
				p.Size = Vector3.new(0.1,0.1,(v[2]-raypos).Magnitude)
				p.CFrame = CFrame.new(v[2] , raypos) * CFrame.new(0,0,-(v[2]-raypos).Magnitude/2)
				game.Debris:AddItem(p, duration+0.25)
			end
			lastattachpos[i] = nil
		end
		for i,v in pairs(attachmenttable) do
			table.insert(lastattachpos, {v, v.WorldPosition})
		end
	end)
end

local keybehavior = {
	["f"] = function()
		remote:FireServer("keypress", "f")
	end,
	["q"] = function()
		remote:FireServer("keypress", "q")
	end,
	["r"] = function()
		remote:FireServer("keypress", "r")
	end,
	["e"] = function()
		remote:FireServer("keypress", "e")
	end
}
local serverresponse = {
	["startray"] = function(limbname, duration, multihit)
		starthitbox(currentattachments[limbname], duration, multihit)
	end,
	["trackbool"] = function(firstbool, secondbool)
		trackmouseY, trackmouselook = firstbool, secondbool
	end,
	["isholding"] = function()
		if holdinglmb then
			remote:FireServer("lmb")
		end
	end,
	["suddenraystop"] = function()
		if rayholder then
			rayholder:Disconnect()
		end
	end,
}

local keyholder
local m1holder
local m1upholder
local m2holder
local lookpart
local wasautorotated
local renderfunc

keyfunc = function(key)
	key = key:lower()
	if keybehavior[key] then
		keybehavior[key]()
	end
end

m1func = function()
	holdinglmb = true
	remote:FireServer("lmb")
end
m1upfunc = function()
	holdinglmb = false
end
m2func = function()
	remote:FireServer("rmb")
end

remote.OnClientEvent:Connect(function(strin, ...)
	if serverresponse[strin] then
		serverresponse[strin](...)
	end
end)

tool.Equipped:Connect(function()
	owner = players.LocalPlayer
	character = owner.Character
	charroot = character.HumanoidRootPart
	charhead = character.Head
	charhum = character:FindFirstChildOfClass("Humanoid")
	table.insert(ignoretable, character)
	wasautorotated = charhum.AutoRotate
	charhum.AutoRotate = false
	mouse = owner:GetMouse()
	keyholder = mouse.KeyDown:Connect(keyfunc)
	m1holder = mouse.Button1Down:Connect(m1func)
	m1upholder = mouse.Button1Up:Connect(m1upfunc)
	m2holder = mouse.Button2Down:Connect(m2func)
	renderfunc = runservice.RenderStepped:Connect(function(delta)
		if lookpart ~= nil then
			if trackmouselook then
				local headtorsodif = (charhead.Position.y - charroot.Position.y)
				local probheadpos = charroot.CFrame.p + Vector3.new(0,headtorsodif,0)
				lookpart.CFrame = CFrame.new(probheadpos - (probheadpos - mouse.Hit.p).unit)
			else
				lookpart.CFrame = CFrame.new((charhead.Position + charroot.CFrame.LookVector*2), charhead.Position)
			end
			if trackmouseY and not charhum.PlatformStand and not table.find(horriblestates, charhum:GetState()) and not charroot:FindFirstChild("parrid") then
				charroot.CFrame = charroot.CFrame:lerp(CFrame.new(charroot.Position, Vector3.new(mouse.Hit.p.x,charroot.Position.y,mouse.Hit.p.z)), delta*15)
			end
		end	
	end)
	lookpart = character:WaitForChild("aimpartfist")
	local lpvel = Instance.new("BodyVelocity", lookpart)
	lpvel.MaxForce = Vector3.new(1/0,1/0,1/0)
	lpvel.Velocity = Vector3.new()
	--
	character["Right Arm"]:WaitForChild("ro bIox")
	character["Left Arm"]:WaitForChild("ro bIox")
	local occupied = false
	for i,v in pairs(currentattachments) do occupied = true break end --janky way to detect if a table has stuff inside (#table doesnt work on strings)
	if not occupied then --check if the table is empty at first and then stop adding
		for i,v in pairs(character:GetDescendants()) do
			if v:IsA("Attachment") and v.Name == "ro bIox" then
				if not currentattachments[v.Parent.Name] then
					currentattachments[v.Parent.Name] = {}
				end
				table.insert(currentattachments[v.Parent.Name], v)
			end
		end
	end
	--table.foreach(ignoretable, print)
end)

tool.Unequipped:Connect(function()
	keyholder:Disconnect()
	m1holder:Disconnect()
	m2holder:Disconnect()
	m1upholder:Disconnect()
	renderfunc:Disconnect()
	table.remove(ignoretable, table.find(ignoretable, character))
	charhum.AutoRotate = wasautorotated
	if lookpart then
		lookpart:Destroy()
		lookpart = nil
	end
end)

workspace.DescendantAdded:Connect(function(WHAT)
	if WHAT.Name == "Handle" and WHAT:IsA("BasePart") then --wrote handle first so it doesnt have to go through 2 checks everytime a part gets made
		--print(WHAT.Name)
		table.insert(ignoretable, WHAT)
	end
end)
workspace.DescendantRemoving:Connect(function(WHAT)
	local didfind = table.find(ignoretable, WHAT)
	if didfind then
		table.remove(ignoretable, didfind)
	end
end)

for i,v in pairs(workspace:GetDescendants()) do
	if v.Name == "Handle" and v:IsA("BasePart") then
		table.insert(ignoretable, v)
	end
end]], owner.Backpack:FindFirstChild("Fists"));

return script;
