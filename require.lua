local fetch
local path = "require_cc"
local name_repos = "repos"
local name_local = "local"

if not requirecc then
  loadrequire = function(name, alias)
    local local_uri = path.."/"..name_local.."/"..name
    local repo_uri = path.."/"..name_repos
    local repos = fs.list(repo_uri)
    local found = false
    while not found and #repos > 0 do
      local repo = table.remove(repos, 1)
      local handle = fs.open(repo_uri.."/"..repo, "r")
      local url = handle.readAll()
      handle.close()
      io.write(string.format("downloading %s from repo %s... ", name, repo))
      local success, file, e = pcall(fetch, url.."/"..string.gsub(name, "%.", "/")..".lua")
      if success then
        if file then
          local handle = fs.open(local_uri, "w")
          handle.write(file)
          handle.close()
          found = true
          print("success")
          if alias then
            if fs.exists(alias) then
              fs.delete(alias)
            end
            fs.copy(local_uri, alias)
            print(string.format("aliased %s to %s", name, alias))
          end
        else
          print(e)
        end
      else
        print(file)
      end
    end
    if not found then error(string.format("could not resolve require %s", name)) end
  end

  require = function(name)
    local local_uri = path.."/"..name_local.."/"..name
    if not fs.exists(local_uri) then
      loadrequire(name)
    else
      print(string.format("%s found locally", name))
    end
    local f, e = loadfile(local_uri)
    if not f then error(e) end
    return f()
  end
end

fetch = function(url)
  local request = http.request(url)
  local response
  while response == nil do
    http.request(url)
    local event, url, handle = os.pullEvent()
    if event == "http_success" or event == "http_failure" then
      response = handle
      if not response then
        return nil, "file was not found on remote repository"
      end
    end
  end
  if response.getResponseCode() == 200 then
    local result = response.readAll()
    response.close()
    return result
  else
    return nil, string.format("server returned response code %d\n", response.getResponseCode())
  end
end