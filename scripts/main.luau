--[[
	@author depthso/depso
	@description Roblox Executor test for implimentations
]]

--// Config
const Delay = 0

--// Variables
local Total, Passed, Undefined = 0, 0, 0
const VENV = getfenv(0)

--// types
type Function = (...unknown) -> ... unknown
type Callback = () -> boolean|string

const function IsCFunction(Closure: Function): boolean
	if pcall(function()
			setfenv(Closure, getfenv(Closure))
		end) then
		return false
	end

	const L, S = debug.info(Closure, "ls")
	if L ~= -1 or S ~= "[C]" then return false end

	return true
end

const function BuildFunctionHash(Closure: Function): string
	local hash = ""
	for _, value in {debug.info(Closure, "snlaf")} do hash ..= tostring(value) end

	return hash
end

@native const function CompareFunctions(A: Function, B: Function): boolean
	return A == B or BuildFunctionHash(A) == BuildFunctionHash(B)
end

@native const function TestAliases(Aliases: {string}): {string}
	const MissingAliases = {}
	for _, Alias in next, Aliases do
		if not VENV[Alias] then
			Undefined += 1
			table.insert(MissingAliases, Alias)
		end
	end

	return MissingAliases
end

@native const function Test(Name: string, Callback: Callback)
	Total += 1

	--// Test delay
	if Total > 1 and Delay > 0 then
		task.wait(Delay)
	end

	const CallSuccess, Return = pcall(Callback)

	--// Unsuccessful
	if not CallSuccess or Return ~= true then
		warn("⛔",  Name, "failed:", Return)
		return
	end

	--// Passed
	Passed += 1
	print("✅", Name)

	return
end

@native const function TestGlobal(Global: string, Aliases: {string}, Callback: Callback)
	--// Has global
	if not VENV[Global] then 
		warn("⛔", Global)
		return 
	end

	--// Alias check
	const MissingAliases = TestAliases(Aliases)
	if #MissingAliases > 0 then
		warn("⚠️", table.concat(MissingAliases, ", "))
		return
	end

	return Test(Global, Callback)
end

@native const function PrintSummary()
	const SuccessRate = math.round(Passed / Total * 100)
	const Failed = Total - Passed

	print("Test Summary")
	print(string.rep("-", 50))
	print(`✅ Tested with a {SuccessRate}% success rate`)
	print(`⛔ {Failed} tests failed`)
	--print(`⚠️ {Undefined} globals are missing aliases`)
	return
end

@native const function PrinHeader()
	print([[
Shit Environment Check
✅ - Pass, ⛔ - Fail, ⏺️ - No test]])
	print("Executor:", identifyexecutor())
	print(string.rep("-", 50), "\n")
	task.wait(1)
	return
end

--// Header
PrinHeader()

--// Tests
Test("HttpGetAsync", function()
	--// Field test
	if pcall(function()
			return workspace:HttpGetAsync("https://google.com")
		end) then
		return "Terrible HttpGetAsync field/hook 😭"
	end

	--// C closure test
	if not IsCFunction(game.HttpGetAsync) then
		return "HttpGetAsync should be a valid C function"
	end

	--// Comparsion
	if CompareFunctions(game.HttpGetAsync, game.HttpGet) then
		return "HttpGetAsync should differ from HttpGet"
	end

	--// Return check
	const Return = game:HttpGetAsync("https://google.com")
	if typeof(Return) ~= "string" or #Return < 10 then
		return "https://google.com/ did not return anything"
	end

	return true
end)

Test("env.__newindex", function() -- Potassium used to fail this lmao
	const Previous = require
	getgenv().require = warn
	const New = getgenv().require
	getgenv().require = Previous

	--// Protected function swap
	if New == Previous then
		return "Value did not change for 'require'"
	end

	return true
end)

Test("env.script", function()
	return typeof(script) == "Instance" and script.Parent == nil and script.GetActor ~= nil and loadstring("return script")() == script and not game.IsDescendantOf(script, game)
end)

Test("getgenv", function()
    const Globals = getgenv()

    --// Metatable check
    if #Globals ~= 0 then
        return "Is a table"
    end

    --// Fallback check
    if typeof(getmetatable(Globals).__index) ~= "table" then
        return "Doesn't fallback to renv"
    end

    --// C function check
    for Name, Func in next, Globals do
        if typeof(Func) == "function" and islclosure(Func) then
            return `{Name} is not a C function`
        end
    end

    return true
end)

Test("Blocked function", function()
    const Thread = coroutine.create(function()
        game:GetService("MicroProfilerService"):DumpToFileAsync(0, 1)
    end)

    const Success, Error = coroutine.resume(Thread)
    if Success or not Error then
        return "Thread passed"
    end

    --// Yield check
    if coroutine.status(Thread) ~= "dead" then
        return "Thread is not dead"
    end

	return true
end)

TestGlobal("hookfunction", {}, function()
	--// Executor function hooking
	hookfunction(hookfunction, function()
		return "abc"
	end)

	const Success, Return = pcall(hookfunction)
    const FuncENVPass = getfenv(hookfunction) == getfenv()
    pcall(restorefunction, hookfunction)

    --// ENV check (Zenith fail)
    if not FuncENVPass then
        return "ENV on function was different"
    end

    --// Return check
	if not Success or Return ~= "abc" then
		return "hookfunction was not hooked"
	end

	--// Error check
	local Previous; Previous = hookfunction(writefile, newcclosure(function()
		return error("Jit")
	end))

    const Success, Return = pcall(writefile)
    pcall(restorefunction, writefile)

	if Success or not typeof(Return) == "string" or not Return:find("Jit") then
		return `Error is incorrect: {Jit}`
	end

    --// C function test
    const CFunc = newcclosure(function() end)
    hookfunction(CFunc, function()
        return error("saar")
    end)

    if select(2, pcall(CFunc)):find("%:") then
        return "Traceback is incorrect"
    end

	return true
end)

TestGlobal("hookmetamethod", {}, function()
	const Timeout = 5
	local Return, IsRunning = false, false

	--// WaitForChild test
	const Thread = task.spawn(function()
		IsRunning = true
		Return = workspace:WaitForChild("SkibidiDepso", Timeout)
	end)

	--// Wait for thread
	repeat task.wait() until IsRunning

	--// Hook
	local Previous; Previous = hookmetamethod(game, "__namecall", function(...)
		return Previous(...)
	end)
	task.wait(Timeout+1)

	--// Return check
	if Return then
		return "Yield should have not returned anything"
	end

	--// Thread state check
	if Return ~= nil or coroutine.status(Thread) ~= "dead" then
		return "Yield never completed when hooked"
	end

    --// Table test
    const Saar = setmetatable({}, {
        __index = loadfile
    })
    const Success, Error = pcall(hookmetamethod, Saar, "__index", function()
        return "na"
    end)

    --// Errored when hooking the table, Instance only :sob:
    if not Success then
        return `hookmetamethod errored when hooking a metatable: {Error}`
    end

    restorefunction(loadfile)
	return Saar.pls == "na"
end)

--// Done
PrintSummary()
