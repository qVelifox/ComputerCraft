-- ============================================
--   AUTO VILLAGER TRADER - CC:Tweaked + Plethora
--   Configuration :
--     Villageois = devant (front)
--     Coffre input  = gauche (left)
--     Coffre output = derrière (back)
-- ============================================

local VILLAGER_SIDE  = "front"
local INPUT_SIDE     = "left"
local OUTPUT_SIDE    = "back"
local TRADE_DELAY    = 1      -- secondes entre chaque trade
local RESTOCK_WAIT   = 30     -- secondes d'attente si le villageois est à court

-- ============================================
--  Utilitaires
-- ============================================

local function log(msg)
  local t = os.date("%H:%M:%S")
  print(("[%s] %s"):format(t, msg))
end

local function centerPrint(msg, width)
  width = width or 40
  local pad = math.floor((width - #msg) / 2)
  print(string.rep(" ", pad) .. msg)
end

local function printHeader()
  term.clear()
  term.setCursorPos(1,1)
  print(string.rep("=", 40))
  centerPrint("AUTO VILLAGER TRADER", 40)
  centerPrint("CC:Tweaked + Plethora", 40)
  print(string.rep("=", 40))
  print()
end

-- ============================================
--  Initialisation des périphériques
-- ============================================

local function getPeripherals()
  local villager = peripheral.wrap(VILLAGER_SIDE)
  local inputChest = peripheral.wrap(INPUT_SIDE)
  local outputChest = peripheral.wrap(OUTPUT_SIDE)

  if not villager then
    error("Aucun villageois détecté côté '" .. VILLAGER_SIDE .. "' !", 2)
  end
  if not inputChest then
    error("Aucun coffre input détecté côté '" .. INPUT_SIDE .. "' !", 2)
  end
  if not outputChest then
    error("Aucun coffre output détecté côté '" .. OUTPUT_SIDE .. "' !", 2)
  end

  -- Vérification que c'est bien un villageois (Plethora)
  if not villager.getTrades then
    error("Le périphérique '" .. VILLAGER_SIDE .. "' n'est pas un villageois Plethora !", 2)
  end

  log("Périphériques OK.")
  return villager, inputChest, outputChest
end

-- ============================================
--  Gestion du coffre input
-- ============================================

-- Retourne un tableau { slot -> itemDetail } du coffre input
local function getInputItems(inputChest)
  local items = {}
  for slot, item in pairs(inputChest.list()) do
    items[slot] = item
  end
  return items
end

-- Compte le total d'un item par name dans le coffre input
local function countItem(inputChest, itemName)
  local total = 0
  for _, item in pairs(inputChest.list()) do
    if item.name == itemName then
      total = total + item.count
    end
  end
  return total
end

-- ============================================
--  Gestion des trades
-- ============================================

-- Récupère les trades disponibles du villageois
local function getAvailableTrades(villager)
  local trades = villager.getTrades()
  local available = {}
  for i, trade in ipairs(trades) do
    if not trade.disabled then
      table.insert(available, { index = i, trade = trade })
    end
  end
  return available
end

-- Affiche les trades disponibles
local function printTrades(trades)
  log("=== Trades disponibles ===")
  for _, t in ipairs(trades) do
    local tr = t.trade
    local input1 = tr.inputs[1] and (tr.inputs[1].count .. "x " .. tr.inputs[1].name) or "?"
    local input2 = tr.inputs[2] and (" + " .. tr.inputs[2].count .. "x " .. tr.inputs[2].name) or ""
    local output = tr.outputs[1] and (tr.outputs[1].count .. "x " .. tr.outputs[1].name) or "?"
    log(("[%d] %s%s  =>  %s"):format(t.index, input1, input2, output))
  end
end

-- Vérifie si le coffre input contient assez pour un trade
local function canAffordTrade(inputChest, trade)
  for _, input in ipairs(trade.inputs) do
    if countItem(inputChest, input.name) < input.count then
      return false, input.name, input.count
    end
  end
  return true
end

-- Déplace les items nécessaires depuis le coffre vers l'inventaire du turtle
-- (Plethora fait le trade depuis l'inventaire du turtle ou directement selon l'API)
-- Ici on utilise turtle.suck depuis le côté INPUT ou chest.pushItems

local function moveItemsToTurtle(inputChest, trade)
  for _, input in ipairs(trade.inputs) do
    local needed = input.count
    for slot, item in pairs(inputChest.list()) do
      if item.name == input.name and needed > 0 then
        local toMove = math.min(needed, item.count)
        -- Pousse depuis le coffre vers l'inventaire du turtle (turtle = "self")
        inputChest.pushItems(peripheral.getName(peripheral.find("turtle") or "self"), toMove, nil, slot)
        needed = needed - toMove
        if needed <= 0 then break end
      end
    end
    if needed > 0 then
      log("ERREUR : pas assez de " .. input.name)
      return false
    end
  end
  return true
end

-- Déplace tout l'inventaire du turtle vers le coffre output
local function dumpToOutput(outputChest)
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item then
      turtle.select(slot)
      -- Pousse via le coffre output (ou drop côté back)
      -- On utilise turtle.drop vers la face OUTPUT
      -- On sélectionne le slot puis on drop côté back
    end
  end
  -- Méthode directe : pushItems depuis "self" vers outputChest
  local turtleName = os.getComputerLabel() or ("computer_" .. os.getComputerID())
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item then
      outputChest.pullItems(turtleName, item.count, nil, slot)
    end
  end
end

-- ============================================
--  Trade principal via Plethora
-- ============================================

local function executeTrade(villager, inputChest, outputChest, tradeIndex, trade)
  -- 1. Vérif affordabilité
  local canDo, missingItem, missingCount = canAffordTrade(inputChest, trade)
  if not canDo then
    return false, ("Manque %dx %s"):format(missingCount, missingItem)
  end

  -- 2. Plethora : trade() prend l'index du trade et utilise l'inventaire autour
  --    La méthode Plethora pour villager : villager.trade(index)
  --    Elle cherche les items dans les inventaires adjacents automatiquement
  --    ou dans l'inventaire du turtle selon la version.

  -- On déplace d'abord les items dans l'inventaire du turtle
  local ok = moveItemsToTurtle(inputChest, trade)
  if not ok then
    return false, "Échec du transfert des items"
  end

  -- 3. Exécuter le trade
  local success, err = villager.trade(tradeIndex)
  if not success then
    -- Remettre les items dans l'input si échec
    dumpToOutput(inputChest)  -- fallback : dump dans input (réutilisable)
    return false, (err or "Trade refusé par le villageois")
  end

  -- 4. Dump le résultat vers le coffre output
  dumpToOutput(outputChest)

  return true
end

-- ============================================
--  Boucle principale
-- ============================================

local function mainLoop()
  printHeader()
  log("Démarrage du trader automatique...")
  log("Appuyez sur Q pour quitter.")
  print()

  local villager, inputChest, outputChest = getPeripherals()

  local totalTrades = 0
  local running = true

  -- Thread de sortie propre
  parallel.waitForAny(
    function()
      -- Attente de la touche Q
      while true do
        local _, key = os.pullEvent("key")
        if key == keys.q then
          running = false
          log("Arrêt demandé par l'utilisateur.")
          return
        end
      end
    end,
    function()
      -- Boucle de trading
      while running do
        -- Récupérer les trades dispo
        local available = getAvailableTrades(villager)

        if #available == 0 then
          log("Aucun trade disponible. Attente de restock (" .. RESTOCK_WAIT .. "s)...")
          sleep(RESTOCK_WAIT)
        else
          local traded = false

          for _, t in ipairs(available) do
            if not running then break end

            local canDo = canAffordTrade(inputChest, t.trade)
            if canDo then
              local tr = t.trade
              local outName = tr.outputs[1] and tr.outputs[1].name or "?"
              local outCount = tr.outputs[1] and tr.outputs[1].count or 0

              log(("Trade #%d : %s"):format(t.index, outName))

              local ok, err = executeTrade(villager, inputChest, outputChest, t.index, tr)
              if ok then
                totalTrades = totalTrades + 1
                log(("  ✓ Succès ! +%dx %s (total: %d trades)"):format(outCount, outName, totalTrades))
                traded = true
              else
                log(("  ✗ Échec : %s"):format(err or "inconnu"))
              end

              sleep(TRADE_DELAY)
            end
          end

          if not traded then
            log("Coffre input insuffisant pour tous les trades. Attente...")
            sleep(5)
          end
        end
      end
    end
  )

  log("Trader arrêté. Total trades effectués : " .. totalTrades)
end

-- ============================================
--  Point d'entrée
-- ============================================

local ok, err = pcall(mainLoop)
if not ok then
  printError("ERREUR FATALE : " .. tostring(err))
  printError("Vérifiez la configuration (côtés, périphériques).")
end