# Executor Implementation Tests
Test the common functions in your Roblox executors with intense edge-cases which most executors fail

<img width="60%" height="auto" alt="ArceusX" src="https://github.com/user-attachments/assets/426ae959-e131-4459-bff8-5bedd33a86fc" />

## Script loadstring
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Executor-Tests/refs/heads/main/scripts/main.luau"))()
```

## Submitting a result
If you wish to submit a result open a discussion with the screenshot, please include the function pass results

## FAQ
- The script errors on execution
  - Your executor doesn't support the latest Luau compiler version, tell your executor devs to update the executor.
- The result changed when I executed it again
  - Please only run the script once when you have joined a game. Rejoin to run it again, I can't be bothered to unhook the game's metatable.
- Is this better than other test scripts?
  - Well this tests the most common executor things rather than every function but has an intensive edge-case test for each which most executors struggle to pass.
- Are you actively updating this?
  - No, and I don't plan to. Please let me live my life alone without you bots. If you want to extend this project please refer to this repo and credit me.
- Are you still in the exploiting comm?
  - No, I am working towards game development nowadays. Sometimes I tend to post something exploiting related like this.

> If you are related to sUNC or any other test script, please credit me for these tests. Thanks to mlemix for the yield test
