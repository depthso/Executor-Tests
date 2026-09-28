-- depso
-- Why not use the luau version? Because I can't be bothered to parse it 🫩

--// Standard luau
local LuauChunk = loadstring("export type T = { x: number, y: number }")
if not LuauChunk then
	warn("Your executor does not support Luau")
	return
end

--// New Luau version
local NewLuauChunk = loadstring("@native const function Test() end") 
if not NewLuauChunk then
	warn("Luau version is out of date")
	return
end

print("Luau is up to date!")
