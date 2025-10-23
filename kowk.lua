local Library = {}
Library.__index = Library

-- Утилиты
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Защита GUI
local function ProtectGui(gui)
    if gethui then
        gui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = game.CoreGui
    else
        gui.Parent = game.CoreGui
    end
end

-- Класс для Drawing объектов
local DrawingObject = {}
DrawingObject.__index = DrawingObject

function DrawingObject.new(type)
    local self = setmetatable({}, DrawingObject)
    self.Object = Drawing.new(type)
    self.Visible = true
    self.Connections = {}
    return self
end

function DrawingObject:Remove()
    if self.Object then
        self.Object:Remove()
    end
    for _, conn in pairs(self.Connections) do
        if conn then
            conn:Disconnect()
        end
    end
end

function DrawingObject:SetProperty(prop, value)
    if self.Object then
        self.Object[prop] = value
    end
end

-- Главный класс библиотеки
function Library.new(title)
    local self = setmetatable({}, Library)
    self.Title = title or "UI Library"
    self.Windows = {}
    self.CurrentWindow = nil
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = game:GetService("HttpService"):GenerateGUID(false)
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.IgnoreGuiInset = true
    ProtectGui(self.ScreenGui)
    return self
end

-- Создание окна
function Library:CreateWindow(config)
    self.Windows = self.Windows or {}  -- Safeguard to prevent nil error
    config = config or {}
    local window = {
        Title = config.Title or "Window",
        Size = config.Size or Vector2.new(500, 400),
        Position = config.Position or Vector2.new(100, 100),
        Tabs = {},
        CurrentTab = nil,
        Dragging = false,
        DragStart = nil,
        StartPos = nil,
        Visible = true,
        Connections = {}
    }

    -- Фон окна
    window.Background = DrawingObject.new("Square")
    window.Background:SetProperty("Size", window.Size)
    window.Background:SetProperty("Position", window.Position)
    window.Background:SetProperty("Color", Color3.fromRGB(25, 25, 35))
    window.Background:SetProperty("Filled", true)
    window.Background:SetProperty("Thickness", 1)
    window.Background:SetProperty("Visible", true)

    -- Граница окна
    window.Border = DrawingObject.new("Square")
    window.Border:SetProperty("Size", window.Size)
    window.Border:SetProperty("Position", window.Position)
    window.Border:SetProperty("Color", Color3.fromRGB(60, 60, 80))
    window.Border:SetProperty("Filled", false)
    window.Border:SetProperty("Thickness", 2)
    window.Border:SetProperty("Visible", true)

    -- Шапка окна
    window.Header = DrawingObject.new("Square")
    window.Header:SetProperty("Size", Vector2.new(window.Size.X, 30))
    window.Header:SetProperty("Position", window.Position)
    window.Header:SetProperty("Color", Color3.fromRGB(35, 35, 50))
    window.Header:SetProperty("Filled", true)
    window.Header:SetProperty("Visible", true)

    -- Заголовок
    window.TitleText = DrawingObject.new("Text")
    window.TitleText:SetProperty("Text", window.Title)
    window.TitleText:SetProperty("Size", 16)
    window.TitleText:SetProperty("Center", false)
    window.TitleText:SetProperty("Outline", true)
    window.TitleText:SetProperty("Color", Color3.fromRGB(255, 255, 255))
    window.TitleText:SetProperty("Position", window.Position + Vector2.new(10, 7))
    window.TitleText:SetProperty("Visible", true)

    -- Драг окна
    local function StartDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            if mousePos.Y - window.Position.Y <= 30 and mousePos.X >= window.Position.X and mousePos.X <= window.Position.X + window.Size.X then
                window.Dragging = true
                window.DragStart = mousePos
                window.StartPos = window.Position
            end
        end
    end

    local function UpdateDrag()
        if window.Dragging then
            local mousePos = UserInputService:GetMouseLocation()
            local delta = mousePos - window.DragStart
            window.Position = window.StartPos + delta
            -- Обновление позиций всех элементов
            window.Background:SetProperty("Position", window.Position)
            window.Border:SetProperty("Position", window.Position)
            window.Header:SetProperty("Position", window.Position)
            window.TitleText:SetProperty("Position", window.Position + Vector2.new(10, 7))
            -- Обновление табов
            for i, tab in ipairs(window.Tabs) do
                local tabX = window.Position.X + (i - 1) * 100
                tab.Button:SetProperty("Position", Vector2.new(tabX, window.Position.Y + 30))
                tab.ButtonText:SetProperty("Position", Vector2.new(tabX + 10, window.Position.Y + 37))
                -- Обновление элементов таба
                if tab.Elements then
                    for j, element in ipairs(tab.Elements) do
                        local elemY = window.Position.Y + 60 + (j - 1) * 35
                        if element.UpdatePosition then
                            element:UpdatePosition(window.Position.X + 10, elemY)
                        end
                    end
                end
            end
        end
    end

    local function EndDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.Dragging = false
        end
    end

    if not window.Connections then
        window.Connections = {}
    end
    table.insert(window.Connections, UserInputService.InputBegan:Connect(StartDrag))
    table.insert(window.Connections, RunService.RenderStepped:Connect(UpdateDrag))
    table.insert(window.Connections, UserInputService.InputEnded:Connect(EndDrag))

    -- Методы окна
    function window:CreateTab(name)
        local tab = {
            Name = name,
            Window = self,
            Elements = {},
            Visible = false,
            Connections = {}
        }
        local tabIndex = #self.Tabs + 1
        local tabX = self.Position.X + (tabIndex - 1) * 100

        -- Кнопка таба
        tab.Button = DrawingObject.new("Square")
        tab.Button:SetProperty("Size", Vector2.new(95, 25))
        tab.Button:SetProperty("Position", Vector2.new(tabX, self.Position.Y + 30))
        tab.Button:SetProperty("Color", Color3.fromRGB(40, 40, 55))
        tab.Button:SetProperty("Filled", true)
        tab.Button:SetProperty("Visible", true)

        -- Текст кнопки
        tab.ButtonText = DrawingObject.new("Text")
        tab.ButtonText:SetProperty("Text", name)
        tab.ButtonText:SetProperty("Size", 14)
        tab.ButtonText:SetProperty("Center", false)
        tab.ButtonText:SetProperty("Outline", true)
        tab.ButtonText:SetProperty("Color", Color3.fromRGB(200, 200, 200))
        tab.ButtonText:SetProperty("Position", Vector2.new(tabX + 10, self.Position.Y + 37))
        tab.ButtonText:SetProperty("Visible", true)

        -- Клик по табу
        local function OnTabClick(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = UserInputService:GetMouseLocation()
                local btnPos = tab.Button.Object.Position
                local btnSize = tab.Button.Object.Size
                if mousePos.X >= btnPos.X and mousePos.X <= btnPos.X + btnSize.X and mousePos.Y >= btnPos.Y and mousePos.Y <= btnPos.Y + btnSize.Y then
                    self:SelectTab(tab)
                end
            end
        end

        if not tab.Connections then
            tab.Connections = {}
        end
        table.insert(tab.Connections, UserInputService.InputBegan:Connect(OnTabClick))

        -- Методы таба
        function tab:AddButton(config)
            config = config or {}
            local button = {
                Text = config.Text or "Button",
                Callback = config.Callback or function() end,
                Tab = self,
                Connections = {}
            }
            local elemIndex = #self.Elements + 1
            local elemY = self.Window.Position.Y + 60 + (elemIndex - 1) * 35

            -- Фон кнопки
            button.Background = DrawingObject.new("Square")
            button.Background:SetProperty("Size", Vector2.new(self.Window.Size.X - 20, 28))
            button.Background:SetProperty("Position", Vector2.new(self.Window.Position.X + 10, elemY))
            button.Background:SetProperty("Color", Color3.fromRGB(50, 50, 70))
            button.Background:SetProperty("Filled", true)
            button.Background:SetProperty("Visible", false)

            -- Текст кнопки
            button.TextObj = DrawingObject.new("Text")
            button.TextObj:SetProperty("Text", button.Text)
            button.TextObj:SetProperty("Size", 14)
            button.TextObj:SetProperty("Center", false)
            button.TextObj:SetProperty("Outline", true)
            button.TextObj:SetProperty("Color", Color3.fromRGB(255, 255, 255))
            button.TextObj:SetProperty("Position", Vector2.new(self.Window.Position.X + 20, elemY + 7))
            button.TextObj:SetProperty("Visible", false)

            -- Обновление позиции
            function button:UpdatePosition(x, y)
                self.Background:SetProperty("Position", Vector2.new(x, y))
                self.TextObj:SetProperty("Position", Vector2.new(x + 10, y + 7))
            end

            -- Клик
            local function OnClick(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and button.Background.Object.Visible then
                    local mousePos = UserInputService:GetMouseLocation()
                    local pos = button.Background.Object.Position
                    local size = button.Background.Object.Size
                    if mousePos.X >= pos.X and mousePos.X <= pos.X + size.X and mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y then
                        pcall(button.Callback)
                    end
                end
            end

            if not button.Connections then
                button.Connections = {}
            end
            table.insert(button.Connections, UserInputService.InputBegan:Connect(OnClick))

            table.insert(self.Elements, button)
            return button
        end

        function tab:AddToggle(config)
            config = config or {}
            local toggle = {
                Text = config.Text or "Toggle",
                Default = config.Default or false,
                Callback = config.Callback or function() end,
                Value = config.Default or false,
                Tab = self,
                Connections = {}
            }
            local elemIndex = #self.Elements + 1
            local elemY = self.Window.Position.Y + 60 + (elemIndex - 1) * 35

            -- Фон
            toggle.Background = DrawingObject.new("Square")
            toggle.Background:SetProperty("Size", Vector2.new(self.Window.Size.X - 20, 28))
            toggle.Background:SetProperty("Position", Vector2.new(self.Window.Position.X + 10, elemY))
            toggle.Background:SetProperty("Color", Color3.fromRGB(40, 40, 55))
            toggle.Background:SetProperty("Filled", true)
            toggle.Background:SetProperty("Visible", false)

            -- Текст
            toggle.TextObj = DrawingObject.new("Text")
            toggle.TextObj:SetProperty("Text", toggle.Text)
            toggle.TextObj:SetProperty("Size", 14)
            toggle.TextObj:SetProperty("Center", false)
            toggle.TextObj:SetProperty("Outline", true)
            toggle.TextObj:SetProperty("Color", Color3.fromRGB(255, 255, 255))
            toggle.TextObj:SetProperty("Position", Vector2.new(self.Window.Position.X + 20, elemY + 7))
            toggle.TextObj:SetProperty("Visible", false)

            -- Чекбокс
            toggle.Checkbox = DrawingObject.new("Square")
            toggle.Checkbox:SetProperty("Size", Vector2.new(18, 18))
            toggle.Checkbox:SetProperty("Position", Vector2.new(self.Window.Position.X + self.Window.Size.X - 35, elemY + 5))
            toggle.Checkbox:SetProperty("Color", toggle.Value and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(60, 60, 80))
            toggle.Checkbox:SetProperty("Filled", true)
            toggle.Checkbox:SetProperty("Visible", false)

            -- Обновление позиции
            function toggle:UpdatePosition(x, y)
                self.Background:SetProperty("Position", Vector2.new(x, y))
                self.TextObj:SetProperty("Position", Vector2.new(x + 10, y + 7))
                self.Checkbox:SetProperty("Position", Vector2.new(x + self.Tab.Window.Size.X - 35, y + 5))
            end

            -- Метод установки значения
            function toggle:SetValue(value)
                self.Value = value
                self.Checkbox:SetProperty("Color", value and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(60, 60, 80))
                pcall(self.Callback, value)
            end

            -- Клик
            local function OnClick(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and toggle.Background.Object.Visible then
                    local mousePos = UserInputService:GetMouseLocation()
                    local pos = toggle.Background.Object.Position
                    local size = toggle.Background.Object.Size
                    if mousePos.X >= pos.X and mousePos.X <= pos.X + size.X and mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y then
                        toggle:SetValue(not toggle.Value)
                    end
                end
            end

            if not toggle.Connections then
                toggle.Connections = {}
            end
            table.insert(toggle.Connections, UserInputService.InputBegan:Connect(OnClick))

            table.insert(self.Elements, toggle)
            return toggle
        end

        function tab:AddSlider(config)
            config = config or {}
            local slider = {
                Text = config.Text or "Slider",
                Min = config.Min or 0,
                Max = config.Max or 100,
                Default = config.Default or 50,
                Callback = config.Callback or function() end,
                Value = config.Default or 50,
                Dragging = false,
                Tab = self,
                Connections = {}
            }
            local elemIndex = #self.Elements + 1
            local elemY = self.Window.Position.Y + 60 + (elemIndex - 1) * 35

            -- Фон
            slider.Background = DrawingObject.new("Square")
            slider.Background:SetProperty("Size", Vector2.new(self.Window.Size.X - 20, 28))
            slider.Background:SetProperty("Position", Vector2.new(self.Window.Position.X + 10, elemY))
            slider.Background:SetProperty("Color", Color3.fromRGB(40, 40, 55))
            slider.Background:SetProperty("Filled", true)
            slider.Background:SetProperty("Visible", false)

            -- Текст
            slider.TextObj = DrawingObject.new("Text")
            slider.TextObj:SetProperty("Text", slider.Text .. ": " .. math.floor(slider.Value))
            slider.TextObj:SetProperty("Size", 14)
            slider.TextObj:SetProperty("Center", false)
            slider.TextObj:SetProperty("Outline", true)
            slider.TextObj:SetProperty("Color", Color3.fromRGB(255, 255, 255))
            slider.TextObj:SetProperty("Position", Vector2.new(self.Window.Position.X + 20, elemY + 7))
            slider.TextObj:SetProperty("Visible", false)

            -- Слайдер фон
            slider.SliderBg = DrawingObject.new("Square")
            slider.SliderBg:SetProperty("Size", Vector2.new(200, 6))
            slider.SliderBg:SetProperty("Position", Vector2.new(self.Window.Position.X + self.Window.Size.X - 220, elemY + 11))
            slider.SliderBg:SetProperty("Color", Color3.fromRGB(30, 30, 45))
            slider.SliderBg:SetProperty("Filled", true)
            slider.SliderBg:SetProperty("Visible", false)

            -- Слайдер заполнение
            local fillPercent = (slider.Value - slider.Min) / (slider.Max - slider.Min)
            slider.SliderFill = DrawingObject.new("Square")
            slider.SliderFill:SetProperty("Size", Vector2.new(200 * fillPercent, 6))
            slider.SliderFill:SetProperty("Position", Vector2.new(self.Window.Position.X + self.Window.Size.X - 220, elemY + 11))
            slider.SliderFill:SetProperty("Color", Color3.fromRGB(100, 150, 255))
            slider.SliderFill:SetProperty("Filled", true)
            slider.SliderFill:SetProperty("Visible", false)

            -- Обновление позиции
            function slider:UpdatePosition(x, y)
                self.Background:SetProperty("Position", Vector2.new(x, y))
                self.TextObj:SetProperty("Position", Vector2.new(x + 10, y + 7))
                self.SliderBg:SetProperty("Position", Vector2.new(x + self.Tab.Window.Size.X - 230, y + 11))
                local fillPercent = (self.Value - self.Min) / (self.Max - self.Min)
                self.SliderFill:SetProperty("Position", Vector2.new(x + self.Tab.Window.Size.X - 230, y + 11))
                self.SliderFill:SetProperty("Size", Vector2.new(200 * fillPercent, 6))
            end

            -- Метод установки значения
            function slider:SetValue(value)
                self.Value = math.clamp(value, self.Min, self.Max)
                local fillPercent = (self.Value - self.Min) / (self.Max - self.Min)
                self.SliderFill:SetProperty("Size", Vector2.new(200 * fillPercent, 6))
                self.TextObj:SetProperty("Text", self.Text .. ": " .. math.floor(self.Value))
                pcall(self.Callback, self.Value)
            end

            -- Драг слайдера
            local function OnDragStart(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and slider.SliderBg.Object.Visible then
                    local mousePos = UserInputService:GetMouseLocation()
                    local pos = slider.SliderBg.Object.Position
                    if mousePos.Y >= pos.Y - 5 and mousePos.Y <= pos.Y + 11 and mousePos.X >= pos.X and mousePos.X <= pos.X + 200 then
                        slider.Dragging = true
                    end
                end
            end

            local function OnDragUpdate()
                if slider.Dragging and slider.SliderBg.Object.Visible then
                    local mousePos = UserInputService:GetMouseLocation()
                    local pos = slider.SliderBg.Object.Position
                    local percent = math.clamp((mousePos.X - pos.X) / 200, 0, 1)
                    local value = slider.Min + (slider.Max - slider.Min) * percent
                    slider:SetValue(value)
                end
            end

            local function OnDragEnd(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    slider.Dragging = false
                end
            end

            if not slider.Connections then
                slider.Connections = {}
            end
            table.insert(slider.Connections, UserInputService.InputBegan:Connect(OnDragStart))
            table.insert(slider.Connections, RunService.RenderStepped:Connect(OnDragUpdate))
            table.insert(slider.Connections, UserInputService.InputEnded:Connect(OnDragEnd))

            table.insert(self.Elements, slider)
            return slider
        end

        table.insert(self.Tabs, tab)

        -- Автоматически выбрать первый таб
        if #self.Tabs == 1 then
            self:SelectTab(tab)
        end

        return tab
    end

    function window:SelectTab(tab)
        -- Скрыть все табы
        for _, t in ipairs(self.Tabs) do
            t.Visible = false
            t.Button:SetProperty("Color", Color3.fromRGB(40, 40, 55))
            -- Скрыть элементы
            for _, elem in ipairs(t.Elements) do
                if elem.Background then elem.Background:SetProperty("Visible", false) end
                if elem.TextObj then elem.TextObj:SetProperty("Visible", false) end
                if elem.Checkbox then elem.Checkbox:SetProperty("Visible", false) end
                if elem.SliderBg then elem.SliderBg:SetProperty("Visible", false) end
                if elem.SliderFill then elem.SliderFill:SetProperty("Visible", false) end
            end
        end

        -- Показать выбранный таб
        tab.Visible = true
        tab.Button:SetProperty("Color", Color3.fromRGB(60, 60, 85))
        self.CurrentTab = tab

        -- Показать элементы
        for _, elem in ipairs(tab.Elements) do
            if elem.Background then elem.Background:SetProperty("Visible", true) end
            if elem.TextObj then elem.TextObj:SetProperty("Visible", true) end
            if elem.Checkbox then elem.Checkbox:SetProperty("Visible", true) end
            if elem.SliderBg then elem.SliderBg:SetProperty("Visible", true) end
            if elem.SliderFill then elem.SliderFill:SetProperty("Visible", true) end
        end
    end

    function window:Destroy()
        -- Отключить все соединения окна
        for _, conn in ipairs(self.Connections) do
            if conn then
                conn:Disconnect()
            end
        end
        self.Background:Remove()
        self.Border:Remove()
        self.Header:Remove()
        self.TitleText:Remove()

        for _, tab in ipairs(self.Tabs) do
            -- Отключить соединения таба
            for _, conn in ipairs(tab.Connections) do
                if conn then
                    conn:Disconnect()
                end
            end
            tab.Button:Remove()
            tab.ButtonText:Remove()

            for _, elem in ipairs(tab.Elements) do
                -- Отключить соединения элемента
                if elem.Connections then
                    for _, conn in ipairs(elem.Connections) do
                        if conn then
                            conn:Disconnect()
                        end
                    end
                end
                if elem.Background then elem.Background:Remove() end
                if elem.TextObj then elem.TextObj:Remove() end
                if elem.Checkbox then elem.Checkbox:Remove() end
                if elem.SliderBg then elem.SliderBg:Remove() end
                if elem.SliderFill then elem.SliderFill:Remove() end
            end
        end
    end

    table.insert(self.Windows, window)
    self.CurrentWindow = window
    return window
end

return Library
