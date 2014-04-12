if not http then error("http api is not enabled") end

--path names
local path = "require_cc"
local name_repos = "repos"
local name_local = "local"

local files = {
  require = "require.lua",
  requirecc = "requirecc.lua",
}

local postcommands = {
  "requirecc repo clear f",
  "requirecc repo add ccrepo git://besuikerd/ccrepo/master"
}

--urls
local git_url = "https://raw.github.com/besuikerd/requirecc/master"
--local git_url = "http://localhost/requirecc"


--initialize paths
if not fs.exists(path) then fs.makeDir(path) end
if not fs.exists(path.."/"..name_repos) then fs.makeDir(path.."/"..name_repos) end
if not fs.exists(path.."/"..name_local) then fs.makeDir(path.."/"..name_local) end

local function fetch(url)
  local request = http.request(url)
  local response
  http.request(url)
  while response == nil do
    local event, u, handle = os.pullEvent()
    if url == u and event == "http_success" or event == "http_failure" then
      response = handle
      print("url: "..u)
      if not response then
        return nil, "file was not found on remote repository"
      end
    end
  end
  if response.getResponseCode() == 200 then
    local result = response.readAll()
    --response.close()
    return result
  else
    return nil, string.format("server returned response code %d\n", response.getResponseCode())
  end
end


for name, path in pairs(files) do
  io.write(string.format("loading %s... ", name))
  local file, e = fetch(git_url.."/"..path)
  
  if file then
    local handle = fs.open(name, "w")
    if handle then
      handle.write(file)
      handle.close()
      print("success!")
    else
      print(string.format("could not write %s to %s", path, name))
    end
  else
    print(e)
  end
end

--execute post init commands
for i, command in ipairs(postcommands) do
  print(string.format("executing: %s", command))
  local success, e = pcall(shell.run, command)
  if not success then print(e) end
end
