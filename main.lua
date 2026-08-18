-- [[ KHỞI TẠO THƯ VIỆN UI FLUENT (HỖ TRỢ TOUCH CỰC TỐT) ]] --
local Fluent = loadstring(game:HttpGet("https://github.com"))()
local SaveManager = loadstring(game:HttpGet("https://githubusercontent.com"))()
local InterfaceManager = loadstring(game:HttpGet("https://githubusercontent.com"))()

-- TẠO CỬA SỔ CHÍNH
local Window = Fluent:CreateWindow({
    Title = "Blox Fruits: Mobile Smart Attack",
    SubTitle = "bởi AI Assistant",
    TabWidth = 140,
    Size = UDim2.fromOffset(480, 320), -- Kích thước vừa vặn cho màn hình dọc/ngang điện thoại
    Acrylic = false, -- Tắt hiệu ứng mờ để tránh lag trên máy yếu
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl -- Phím tắt cho PC
})

-- [[ BIẾN CẤU HÌNH HỆ THỐNG ]] --
_G.SmartAttack = false       
_G.AttackRange = 30         
_G.AttackDelay = 0.15       
_G.HighlightColor = Color3.fromRGB(0, 255, 255) 

-- [[ CÁC SERVICES CẦN THIẾT ]] --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- [[ KHỞI TẠO CÁC BIẾN FRAMEWORK ĐÁNH ]] --
local CombatFramework
pcall(function()
    CombatFramework = require(LocalPlayer.PlayerScripts:WaitForChild("CombatFramework"))
end)

-- [[ CÁC HÀM XỬ LÝ CHỨC NĂNG ]] --
local function ApplyHighlight(monster)
    if monster and not monster:FindFirstChild("TargetHighlight") then
        local hl = Instance.new("Highlight")
        hl.Name = "TargetHighlight"
        hl.FillColor = _G.HighlightColor
        hl.FillTransparency = 0.6
        hl.OutlineColor = _G.HighlightColor
        hl.OutlineTransparency = 0
        hl.Adornee = monster
        hl.Parent = monster
    end
end

local function RemoveHighlight(monster)
    if monster and monster:FindFirstChild("TargetHighlight") then
        monster.TargetHighlight:Destroy()
    end
end

local function FireSmartAttack()
    pcall(function()
        local character = LocalPlayer.Character
        local tool = character and character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Tooltip") then 
            local activeCombat = CombatFramework.activeController
            if activeCombat and activeCombat.equippedWeaponData then
                ReplicatedStorage.Remotes.Validator:FireServer(math.random(1, 9999)) 
                local combatEvent = ReplicatedStorage:FindFirstChild("CombatFramework") and ReplicatedStorage.CombatStorage.RemoteEvent
                if not combatEvent then
                    combatEvent = ReplicatedStorage:FindFirstChild("CombatFramework") and ReplicatedStorage.CombatFramework:FindFirstChild("RemoteEvent")
                end
                if combatEvent then
                    combatEvent:FireServer({["$"] = "Attack", ["_"] = activeCombat.equippedWeaponData})
                end
            end
        end
    end)
end

-- [[ VÒNG LẶP CHẠY NGẦM (BACKGROUND LOOP) ]] --
task.spawn(function()
    local currentTargets = {}
    while true do
        task.wait(_G.AttackDelay)
        if _G.SmartAttack then
            pcall(function()
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local enemiesFolder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Characters")
                    local newTargets = {}
                    if enemiesFolder then
                        for _, enemy in pairs(enemiesFolder:GetChildren()) do
                            if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                                local distance = (rootPart.Position - enemy.HumanoidRootPart.Position).magnitude
                                if distance <= _G.AttackRange then
                                    newTargets[enemy] = true
                                    ApplyHighlight(enemy)
                                    FireSmartAttack()
                                end
                            end
                        end
                    end
                    for oldEnemy, _ in pairs(currentTargets) do
                        if not newTargets[oldEnemy] or not oldEnemy:FindFirstChild("Humanoid") or oldEnemy.Humanoid.Health <= 0 then
                            RemoveHighlight(oldEnemy)
                        end
                    end
                    currentTargets = newTargets
                end
            end)
        else
            for oldEnemy, _ in pairs(currentTargets) do
                RemoveHighlight(oldEnemy)
            end
            table.clear(currentTargets)
        end
    end
end)

-- [[ THIẾT KẾ CÁC TAB TRÊN GIAO DIỆN ]] --
local Tabs = {
    Main = Window:NewTab({ Title = "Chức Năng", Icon = "sword" }),
    Settings = Window:NewTab({ Title = "Cài Đặt", Icon = "settings" })
}

-- 1. TAB CHỨC NĂNG CHÍNH
local ToggleAttack = Tabs.Main:AddToggle("SmartAttackToggle", {
    Title = "Bật Auto Đánh & Highlight", 
    Default = false,
    Callback = function(Value)
        _G.SmartAttack = Value
    end
})

local SliderRange = Tabs.Main:AddSlider("RangeSlider", {
    Title = "Tầm Đánh (Range)",
    Description = "Khoảng cách tự kích hoạt đòn đánh",
    Default = 30,
    Min = 10,
    Max = 60,
    Rounding = 0,
    Callback = function(Value)
        _G.AttackRange = Value
    end
})

local SliderDelay = Tabs.Main:AddSlider("DelaySlider", {
    Title = "Tốc Độ Đánh (Delay)",
    Description = "Càng nhỏ đánh càng nhanh. Chuẩn: 0.15",
    Default = 0.15,
    Min = 0.05,
    Max = 0.5,
    Rounding = 2, -- Giữ hai chữ số thập phân cho mượt
    Callback = function(Value)
        _G.AttackDelay = Value
    end
})

local DropdownColor = Tabs.Main:AddDropdown("ColorDropdown", {
    Title = "Màu Sắc Highlight",
    Values = {"Cyan", "Đỏ", "Vàng", "Xanh Lá"},
    CurrentValue = "Cyan",
    Callback = function(Value)
        if Value == "Cyan" then
            _G.HighlightColor = Color3.fromRGB(0, 255, 255)
        elseif Value == "Đỏ" then
            _G.HighlightColor = Color3.fromRGB(255, 0, 0)
        elseif Value == "Vàng" then
            _G.HighlightColor = Color3.fromRGB(255, 255, 0)
        elseif Value == "Xanh Lá" then
            _G.HighlightColor = Color3.fromRGB(0, 255, 0)
        end
    end
})

-- [[ CHỨC NĂNG QUAN TRỌNG: TẠO NÚT NỔI TOGGLE HỖ TRỢ TOUCH ]] --
local function CreateMobileToggle()
    -- Xóa nút cũ nếu có trước đó
    if game:GetService("CoreGui"):FindFirstChild("BloxFruitsMobileToggle") then
        game:GetService("CoreGui").BloxFruitsMobileToggle:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    local ToggleButton = Instance.new("TextButton")
    local UICorner = Instance.new("UICorner")
    local UIStroke = Instance.new("UIStroke")

    ScreenGui.Name = "BloxFruitsMobileToggle"
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Cấu hình nút tròn nổi
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Parent = ScreenGui
    ToggleButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ToggleButton.Position = UDim2.new(0.05, 0, 0.15, 0) -- Vị trí mặc định ở góc trên bên trái màn hình
    ToggleButton.Size = UDim2.new(0, 50, 0, 50) -- Kích thước nút (50x50 pixel dễ chạm)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Text = "BF" -- Chữ viết tắt hiển thị trên nút
    ToggleButton.TextColor3 = Color3.fromRGB(0, 255, 255)
    ToggleButton.TextSize = 16
    ToggleButton.Active = true
    ToggleButton.Draggable = true -- Cho phép giữ ngón tay để kéo nút đi bất kỳ vị trí nào trên màn hình

    UICorner.CornerRadius = UDim.new(0, 25) -- Bo tròn nút thành hình tròn tròn
    UICorner.Parent = ToggleButton

    UIStroke.Color = Color3.fromRGB(0, 255, 255)
    UIStroke.Thickness = 2
    UIStroke.Parent = ToggleButton

    -- Xử lý sự kiện khi chạm (Touch) vào nút
    ToggleButton.MouseButton1Click:Connect(function()
        -- Fluent tự động có hàm ẩn/hiện cửa sổ chính
        if Window.Frame.Visible then
            WindowFrame = Window.Frame
            Window.Frame.Visible = false
        else
            Window.Frame.Visible = true
        end
    end)
end

-- Kích hoạt nút nổi hỗ trợ Touch di động
CreateMobileToggle()

-- Thông báo UI tải thành công
Fluent:Notify({
    Title = "Blox Fruits Script",
    Content = "Đã tạo nút bấm nổi! Hãy chạm để ẩn/hiện Menu.",
    Duration = 5
})
