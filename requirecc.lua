shell.run("/require")

local path = "require_cc"
local name_repos = "repos"
local name_local = "local"

local function prompt(prefix, default)
  io.write(prefix)
  local input = io.read()
  input = input == "" and default or input
  return input
end

local function promptYesNo(prefix, default, yesInput, noInput)
  local choice
  local input = string.lower(prompt(string.format("%s [%s/%s]? ", prefix, default and string.upper(yesInput) or yesInput, default and noInput or string.upper(noInput)), default and yesInput or noInput))
  while choice == nil do
    if input == string.lower(yesInput) then
      choice = true
    else
      choice = false
    end
  end
  return choice
end

local function table2string(t)
  local commands = ""
  for key, v in pairs(t) do
    commands = commands..key.. "|"
  end
  commands = string.sub(commands, 0, #commands - 1)
  return commands
end

--decorators around urls, for example git://bla.git -> https://raw.github.com/bla
local urlDecorators = {
  git = function(url) return string.gsub("https://raw.github.com/"..url, ".git$", "") end
}

local repo = {

    add = function(name, url)
      if not name or not url then
        print("usage: add [name] [url]")
        return
      end
      local decorator = urlDecorators[string.gsub(string.match(url, "^%a+://") or "", "://$", "")]

      if(decorator) then
        url = decorator(string.gsub(url, "^%a+://", ""))
      end

      local uri = path.."/"..name_repos.."/"..name
      if fs.exists(uri) then
        if promptYesNo(string.format("%s exists! override", name) , true, "y", "n") then
          print(string.format("overriding repo %s", name))
        else
          print(string.format("did not override repo %s", name))
          return
        end
      end
      local handle = fs.open(uri, "w")
      handle.write(url)
      handle.close()
      print(string.format("succesfully created repo %s", name))
    end,

    show = function()
      print("[repositories]")
      local uri = path.."/"..name_repos
      for i, name in ipairs(fs.list(uri)) do
        local handle = fs.open(uri.."/"..name, "r")
        if handle then
          local url = handle.readAll()
          handle.close()
          print(string.format("\t%s: %s", name, url))
        end

      end
    end,

    delete = function(name)
      local uri = path.."/"..name_repos.."/"..name
      if fs.exists(uri) then
        if promptYesNo(string.format("really delete repo %s", name), true, "y", "n") then
          fs.delete(uri)
          print(string.format("deleted %s", name))
        else
          print(string.format("did not delete %s", name))
        end
      else
        print(string.format("cannot delete repo %s: repo does not exist!", name))
      end
    end,

    clear = function(force)
      if force == "f" or promptYesNo("really clear all repositories", false, "y", "n") then
        local uri = path.."/"..name_repos
        for i, name in ipairs(fs.list(uri)) do
          fs.delete(uri.."/"..name)
        end
        print("cleared all repositories")
      end
    end,
}

local commands
commands = {
  repo = repo,
  load = function(name, alias)
    if name then
      loadrequire(name, alias)
    else
      print("please specify which require to load")
    end
  end,

  delete = function(name)
    local uri = path.."/"..name_local.."/"..name
    if fs.exists(uri) then
      if promptYesNo(string.format("really delete %s", name), true, "y", "n") then
        fs.delete(uri)
        print(string.format("%s deleted", name))
      else
        print(string.format("%s not deleted", name))
      end
    else
      print(string.format("require %s does not exist", name))
    end
  end,

  run = function(name, ...)
    local uri = path.."/"..name_local.."/"..name
    if not fs.exists(uri) then
      loadrequire(name)
    end
    return loadfile(uri, ...)()
  end,

  call = function(name, ...)
    local tocall, e = commands.run(name, ...)
    if tocall then
      tocall()
    else
      print("cannot call "..name)
    end
  end,

  clear = function()
    if force == "f" or promptYesNo("really clear all local requires", false, "y", "n") then
      local uri = path.."/"..name_local
      for i, name in ipairs(fs.list(uri)) do
        fs.delete(uri.."/"..name)
      end
      print("cleared all local requires")
    end
  end
}

local tArgs = {...}
local args = {...}
local current = commands
local interpreted = false

while not interpreted do
  if #args > 0 then
    local command = current[args[1]]
    if command then
      table.remove(args, 1)
      if type(command) == "table" then
        current = command
      elseif type(command) == "function" then
        command(unpack(args))
        interpreted = true
      end
    else
      interpreted = true
      print(string.format("unknown command %s, possible commands: [%s]", args[1], table2string(current)))
    end

  else
    interpreted = true
    print(string.format("missing arguments, choose any of the following: [%s]", table2string(current)))
  end
end

