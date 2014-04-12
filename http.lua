local exports = {}

local htp = require("luasocket")

local http = {
  get = function(url)
    return {
      readAll = function()
        print(htp.request(url))
      end
    }
  end
}



setmetatable(exports, {
  __call = function(table)
    for k, v in pairs(table) do
      _G[k] = v
    end
  end
})

http.get("http://nu.nl").readAll()

return exports