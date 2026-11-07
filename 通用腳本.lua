local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- 確保玩家角色與環境完全加載
repeat task.wait() until LocalPlayer and LocalPlayer.Character

local CurrentPlaceId = game.PlaceId

-- =========================================================================
--  【內建通知函式】負責在右下角跳出提示
-- =========================================================================
local function showNotification(title, text, isSuccess)
    task.spawn(function()
        -- 確保 StarterGui 已經準備好接受通知請求
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = 5, -- 提示停留 5 秒
                Button1 = "確定",
                TextColor3 = isSuccess and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
            })
        end)
    end)
end

-- =========================================================================
--  【智慧環境感應器】主動判斷當前遊戲是槍戰類還是格鬥類
-- =========================================================================
local function DetectGameType()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    
    local function checkItems(container)
        if not container then return nil end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                -- 智慧偵測關鍵字
                if name:find("gun") or name:find("pistol") or name:find("rifle") or name:find("shoot") or name:find("revolver") or name:find("ammo") or name:find("snip") then
                    return "Gunfight"
                elseif name:find("sword") or name:find("melee") or name:find("knife") or name:find("fist") or name:find("combat") or name:find("blade") then
                    return "Melee"
                end
            end
        end
        return nil
    end

    local detectedType = checkItems(bp) or checkItems(char)
    
    if not detectedType then
        if workspace:FindFirstChild("Bullets") or workspace:FindFirstChild("RaycastCamera") then
            detectedType = "Gunfight"
        else
            detectedType = "Melee"
        end
    end
    
    return detectedType
end

-- =========================================================================
--  【萬能引導核心執行分流】
-- =========================================================================
print("=== [萬能智慧引導器] 正在分析當前遊戲環境... ===")

local FinalLuaUrl = ""
local GameModeName = ""

-- 1. 紅線 (REDLINER) 專屬地圖 ID 判定
if CurrentPlaceId == 94987506187454 or CurrentPlaceId == 9490750616 then
    GameModeName = "REDLINER 專屬版"
    -- 填入你的 REDLINER 專用腳本 GitHub 網址
    FinalLuaUrl = "https://githubusercontent.com"
else
    -- 2. 其他所有遊戲：智慧感知自動分流
    local gameType = DetectGameType()
    
    if gameType == "Gunfight" then
        GameModeName = "通用槍戰自瞄版"
        -- 填入你的 通用槍戰腳本 GitHub 網址 (內含兵工廠團隊檢查的那份)
        FinalLuaUrl = "https://githubusercontent.com"
    else
        GameModeName = "高級格鬥貼人版"
        -- 填入你的 高級格鬥通用腳本 GitHub 網址
        FinalLuaUrl = "https://githubusercontent.com"
    end
end

-- =========================================================================
--  【安全載入並執行遠端 Lua 代碼 + 內建通知判定】
-- =========================================================================
if FinalLuaUrl ~= "" then
    local success, err = pcall(function()
        loadstring(game:HttpGet(FinalLuaUrl))()
    end)
    
    if success then
        -- 執行成功：右下角跳出綠色成功通知
        showNotification("🟢 腳本載入成功", "已成功啟動【" .. GameModeName .. "】選單！", true)
        print("✔ [萬能引導器] " .. GameModeName .. " 載入成功！")
    else
        -- 執行失敗：右下角跳出紅色失敗通知
        showNotification("🔴 腳本載入失敗", "無法讀取遠端原始碼，請檢查網路或網址！", false)
        warn("❌ 遠端腳本執行失敗，錯誤回報: ", err)
    end
end
