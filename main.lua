loadfile("functional.lua")()()

function constructor(name, ...)
  local args = {...}
  if _G[name] then error(name.." already exists in namespace") end
  local mt = {
    __name = name,
    __tostring = function(t)
      local i = iter(t)
      return getmetatable(t).__name.. (#t == 0 and "" or ( "("..tail(i):foldl(function(accum, n) return accum..", "..tostring(n) end, tostring(head(i))) .. ")" ))
    end
  }
  if #args == 0 then
    cons = setmetatable({}, mt)
  else
    cons = function(...)
      local obj = {...}
      if(#obj ~= #args) then
        local missing = drop(#obj, iter(args))
        error("missing constructor arguments: ["..tail(missing):foldl(function(acc, s) return acc..","..s end, head(missing).."]"))
      end
      return setmetatable(obj, mt)
    end
  end
  return cons
end

function match(cons, cases)
  if not getmetatable(cons) or not getmetatable(cons).__name then error("invalid constructor to match") end
  local case = cases[getmetatable(cons).__name]
  
  if(case) then
    assert(type(cons) == "table")
    if type(case) == "function" then return case(unpack(cons)) else return case end
  else
    error("non-exhaustive pattern, missing: "..cons.__name)
  end
end

local Node = constructor("Node", "element", "left", "right")
local Leaf = constructor("Leaf")

function tree2string(tree)
  local recurs
  recurs = function(t, l)
    return match(t, {
      Node = function(val, left, right) return "Node("..val..")\n"..take(l, duplicate("\t")):foldl(op.concat, "")..recurs(left, l + 1).."\n"..take(l, duplicate("\t")):foldl(op.concat, "")..recurs(right, l + 1)  end,
      Leaf = "Leaf"
    })
  end
  return recurs(tree, 1)
end

local Cons = constructor("Cons", "val", "next")
local Empty = constructor("Empty")

function cMap(f, c)
  return match(c, {
    Cons = function(x, xs) return Cons(f(x), cMap(f, xs)) end,
    Empty = Empty
  })
end

function list2string(list)
  local recurs
  
  recurs = function(l) 
    return match(l, {
      Cons = function(x, xs) return x..","..recurs(xs) end,
      Empty = ""
    })
  end
  return "["..recurs(list).."]"
end

aList = Cons(2, Cons(3, Cons(4, Empty)))
aTree = (Node(1, Node(2, Leaf, Leaf), Node(2, Node(3, Leaf, Leaf), Node(3, Leaf, Leaf))))
print(tree2string(aTree))
--print(list2string(aList))
--print(list2string(cMap(function(x) return x + 1 end, aList)))
print(Node(5, Node(4, Leaf, Leaf), Node(4, Leaf, Leaf)))
print(aList)
