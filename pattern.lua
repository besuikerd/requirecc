function constructor(name, ...)
  local args = {...}
  local cons
  local object = {__name = name}
  if _G[name] then error(name.." already exists in namespace") end
  if #args == 0 then
    cons = object
  else
    cons = function(...)
      local consArgs = {...}
      if #consArgs ~= #args then error("wrong amount of constructor arguments, required: "..#args) end
      for i, c in ipairs(args) do
        object[c] = consArgs[i]
      end
      return object
    end
  end
  _G[name] = cons
end

function map(f, list)
  local result = {}
  for k,v in pairs(list) do
    result[k] = f(v, k) or v
  end
  return result
end

function deepMap(f, list)
  for k,v in pairs(list) do
    list[k] = f(v, k) or v
  end
  return list
end

function filter(f, list)
  local result = {}
  for i,j in pairs(list) do
    if f(j) then
      result[i] = j
    end
  end
  return result
end

function foldl(f, accum, list)
  for i,j in pairs(list) do
    accum = accum and f(j, accum) or j
  end
  return accum
end

function shallowcopy(table)
  local result = {}
  for i,j in pairs(table) do
    result[i] = j
  end
  return result
end

function rep(f, amount)
  for i=1, amount and amount - 1 or 0 do f() end
  return f()
end


function match(cons, cases)
  local case = cases[cons.__name] 
  if(case) then
--    if type(cons) == "table" then case() elseif type(cons) == "function" then case(unpack(foldl(function(list, next) if() return list end, {}, cons))) else error("invalid constructor to match against") end
  else
    error("non-exhaustive pattern for "..cons.__name)
  end
end

constructor("Node", "element", "left", "right")
constructor("Leaf")


function testTree(tree)
  match(tree, {
    Node = function(element, left, right) return testTree(left).." "..tostring(element).." "..testTree(right) end,
    Leaf = function() return "leaf" end
  })
end

testTree(Node(5, Node(4, Leaf, Leaf), Leaf))