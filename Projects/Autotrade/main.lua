local TRADE_DELAY   = 1
local RESTOCK_WAIT  = 30
local INPUT_SIDE    = "left"
local OUTPUT_SIDE   = "back"

local function banner()
  term.clear()
  term.setCursorPos(1, 1)
  term.setTextColor(colors.white)
  print()
end

local function log(color, msg)
  term.setTextColor(color)
  local h = os.date("%H:%M:%S")
  print(("[%s] %s"):format(h, msg))
  term.setTextColor(colors.white)
end

local function findVillager()
  for _, side in ipairs(peripheral.getNames()) do
    local p = peripheral.wrap(side)
    if p and p.getTrades then
      return p, side
    end
  end
  return nil
end

local function countItem(chest, name)
  local n = 0
  for _, item in pairs(chest.list()) do
    if item.name == name then n = n + item.count end
  end
  return n
end

local function canAfford(chest, trade)
  for _, inp in ipairs(trade.inputs) do
    if inp and inp.name and countItem(chest, inp.name) < inp.count then
      return false, inp.name, inp.count
    end
  end
  return true
end

local function pullFromChest(chest, itemName, amount)
  local got = 0
  for slot, item in pairs(chest.list()) do
    if item.name == itemName and got < amount then
      local want = math.min(amount - got, item.count)
      local moved = chest.pushItems("turtle_" .. os.getComputerID(), want, nil, slot)
      got = got + (moved or 0)
    end
  end
  return got >= amount
end

local function dumpTurtle(outputChest)
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item then
      turtle.select(slot)
      turtle.dropBack()
    end
  end
end

local function doTrade(villager, inputChest, outputChest, idx, trade)
  local ok, missingName, missingAmt = canAfford(inputChest, trade)
  if not ok then
    return false, ("manque %dx %s"):format(missingAmt, missingName)
  end

  for _, inp in ipairs(trade.inputs) do
    if inp and inp.name then
      local success = pullFromChest(inputChest, inp.name, inp.count)
      if not success then
        dumpTurtle(inputChest)
        return false, "transfert impossible depuis le coffre input"
      end
    end
  end

  local result, err = villager.trade(idx)
  if not result then
    dumpTurtle(inputChest)
    return false, (err or "trade refuse")
  end

  dumpTurtle(outputChest)
  return true
end

local function main()
  banner()

  local inputChest = peripheral.wrap(INPUT_SIDE)
  if not inputChest then
    log(colors.red, "Pas de coffre input cote '" .. INPUT_SIDE .. "'")
    return
  end

  local outputChest = peripheral.wrap(OUTPUT_SIDE)
  if not outputChest then
    log(colors.red, "Pas de coffre output cote '" .. OUTPUT_SIDE .. "'")
    return
  end

  log(colors.cyan, "Recherche du villageois...")
  local villager, vSide = findVillager()
  if not villager then
    log(colors.red, "Aucun villageois Plethora detecte !")
    log(colors.orange, "Verifiez que le villageois est adjacent.")
    return
  end
  log(colors.lime, "Villageois trouve cote : " .. vSide)

  log(colors.cyan, "Coffres OK. Lancement du trading. [Q] pour quitter.")
  print()

  local total = 0
  local running = true

  parallel.waitForAny(
    function()
      while true do
        local _, key = os.pullEvent("key")
        if key == keys.q then
          running = false
          return
        end
      end
    end,
    function()
      while running do
        local trades = villager.getTrades()
        local available = {}
        for i, t in ipairs(trades) do
          if not t.disabled then
            table.insert(available, { idx = i, trade = t })
          end
        end

        if #available == 0 then
          log(colors.orange, "Villageois a court. Attente " .. RESTOCK_WAIT .. "s...")
          sleep(RESTOCK_WAIT)
        else
          local didSomething = false

          for _, entry in ipairs(available) do
            if not running then break end

            local tr = entry.trade
            local outName  = tr.outputs and tr.outputs[1] and tr.outputs[1].name  or "?"
            local outCount = tr.outputs and tr.outputs[1] and tr.outputs[1].count or 0

            local affordable = canAfford(inputChest, tr)
            if affordable then
              local ok, err = doTrade(villager, inputChest, outputChest, entry.idx, tr)
              if ok then
                total = total + 1
                log(colors.lime, ("OK +%dx %s (total: %d)"):format(outCount, outName, total))
                didSomething = true
              else
                log(colors.red, ("ECHEC trade#%d : %s"):format(entry.idx, err))
              end
              sleep(TRADE_DELAY)
            end
          end

          if not didSomething then
            log(colors.orange, "Pas assez d'items dans le coffre input. Attente 5s...")
            sleep(5)
          end
        end
      end

      log(colors.yellow, ("Arret. Total trades : %d"):format(total))
    end
  )
end

local ok, err = pcall(main)
if not ok then
  term.setTextColor(colors.red)
  print("ERREUR : " .. tostring(err))
  term.setTextColor(colors.white)
end