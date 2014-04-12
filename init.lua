if not http then error("http api is not enabled") end

--path names
local path = "requirecc"
local name_repos = "repos"
local name_local = "local"

local files = {
  require = "require.lua",
  requirecc = "requirecc.lua",
}

--urls
local git_url = "https://raw.github.com/besuikerd/requirecc/master"

--initialize paths
if not fs.exists(path) then fs.makeDir(path) end
if not fs.exists(path.."/"..name_repos) then fs.makeDir(path.."/"..name_repos) end
if not fs.exists(path.."/"..name_local) then fs.makeDir(path.."/"..name_local) end

for name, path in pairs(files) do
  io.write(string.format("loading %s... ", name))
  local request = http.request(git_url.."/"..path)
  local response
  while response == nil do
    http.request(git_url.."/"..path)
    local event, url, handle = os.pullEvent()
    if event == "http_success" or event == "http_failure" then
      response = handle
      if not response then 
        io.write(string.format("%s not found on remote repository\n", name)) 
        response = {}
      end
    end
  end
  if response.getResponseCode then
    if response.getResponseCode() == 200 then
      local handle = fs.open(name, "w")
      if handle then
        handle.write(response.readAll())
        handle.close()
        io.write("success!\n")
      else
        io.write(string.format("could not write %s to %s\n", path, name))
      end
    else
      io.write(string.format("server returned response code %d\n", response.getResponseCode()))
    end
  end
end
