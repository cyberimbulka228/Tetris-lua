-- Colors for different block types (ComputerCraft style)
local COLORS = {
    [1] = colors.blue,     -- I
    [2] = colors.orange,   -- L
    [3] = colors.cyan,     -- J
    [4] = colors.lime,     -- S
    [5] = colors.red,      -- Z
    [6] = colors.purple,   -- T
    [7] = colors.yellow    -- O
}

-- Shapes of pieces
local SHAPES = {
    -- I
    { {0,0,0,0}, {1,1,1,1}, {0,0,0,0}, {0,0,0,0} },
    -- O
    { {0,0,0,0}, {0,1,1,0}, {0,1,1,0}, {0,0,0,0} },
    -- T
    { {0,0,0,0}, {0,0,1,0}, {0,1,1,1}, {0,0,0,0} },
    -- S
    { {0,0,0,0}, {0,1,1,0}, {1,1,0,0}, {0,0,0,0} },
    -- Z
    { {0,0,0,0}, {1,1,0,0}, {0,1,1,0}, {0,0,0,0} },
    -- L
    { {0,0,0,0}, {0,0,1,0}, {0,0,1,0}, {0,1,1,0} },
    -- J
    { {0,0,0,0}, {1,0,0,0}, {1,0,0,0}, {1,1,0,0} }
}

-- Game field (10x20)
local field = {}
for x = 1, 10 do
    field[x] = {}
    for y = 1, 20 do
        field[x][y] = 0
    end
end

local currentPiece = { shape = {}, x = 3, y = 1, color = 0, type = 1 }

-- Clear screen and draw borders
local function drawBorder()
    term.clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    for y = 1, 20 do
        term.setCursorPos(1, y) write("X")
        term.setCursorPos(12, y) write("X")
    end
    for x = 1, 12 do
        term.setCursorPos(x, 21) write("X")
    end
end

-- Draw game grid
local function drawField()
    for x = 1, 10 do
        for y = 1, 20 do
            local color = field[x][y]
            if color ~= 0 then
                term.setCursorPos(x + 1, y)
                term.setBackgroundColor(color)
                write("  ")
            end
        end
    end
end

-- Draw current piece
local function drawPiece()
    for i = 1, 4 do
        for j = 1, 4 do
            if currentPiece.shape[i][j] == 1 then
                term.setCursorPos(currentPiece.x + j, currentPiece.y + i - 1)
                term.setBackgroundColor(currentPiece.color)
                write("  ")
            end
        end
    end
end

-- Check for collisions
local function checkCollision(px, py, shape)
    for i = 1, 4 do
        for j = 1, 4 do
            if shape[i][j] == 1 then
                local newX = px + j - 1
                local newY = py + i - 1
                if newX < 1 or newX > 10 or newY > 20 then return true end
                if newY >= 1 and field[newX][newY] ~= 0 then return true end
            end
        end
    end
    return false
end

-- Spawn a new piece
local function spawnNewPiece()
    local t = math.random(1, #SHAPES)
    currentPiece.shape = SHAPES[t]
    currentPiece.color = COLORS[t]
    currentPiece.x = 4
    currentPiece.y = 1
    currentPiece.type = t

    if checkCollision(currentPiece.x, currentPiece.y, currentPiece.shape) then
        term.setCursorPos(5, 10)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.red)
        write("GAME OVER")
        sleep(2)
        os.reboot()
    end
end

-- Merge piece into the field
local function mergePiece()
    for i = 1, 4 do
        for j = 1, 4 do
            if currentPiece.shape[i][j] == 1 then
                local x = currentPiece.x + j - 1
                local y = currentPiece.y + i - 1
                if y >= 1 and y <= 20 then
                    field[x][y] = currentPiece.color
                end
            end
        end
    end
    spawnNewPiece()
end

-- Rotate piece
local function rotatePiece()
    local rotated = {}
    for i = 1, 4 do
        rotated[i] = {}
        for j = 1, 4 do
            rotated[i][j] = currentPiece.shape[4 - j + 1][i]
        end
    end
    if not checkCollision(currentPiece.x, currentPiece.y, rotated) then
        currentPiece.shape = rotated
    end
end

-- Clear completed lines
local function clearLines()
    for y = 20, 1, -1 do
        local full = true
        for x = 1, 10 do
            if field[x][y] == 0 then
                full = false
                break
            end
        end
        if full then
            for y2 = y, 2, -1 do
                for x = 1, 10 do
                    field[x][y2] = field[x][y2 - 1]
                end
            end
            for x = 1, 10 do
                field[x][1] = 0
            end
            y = y + 1
        end
    end
end

-- Main game loop
local function gameLoop()
    spawnNewPiece()
    while true do
        drawBorder()
        drawField()
        drawPiece()

        local event, key = os.pullEvent()
        if event == "key" then
            if key == keys.left then
                if not checkCollision(currentPiece.x - 1, currentPiece.y, currentPiece.shape) then
                    currentPiece.x = currentPiece.x - 1
                end
            elseif key == keys.right then
                if not checkCollision(currentPiece.x + 1, currentPiece.y, currentPiece.shape) then
                    currentPiece.x = currentPiece.x + 1
                end
            elseif key == keys.down then
                if not checkCollision(currentPiece.x, currentPiece.y + 1, currentPiece.shape) then
                    currentPiece.y = currentPiece.y + 1
                else
                    mergePiece()
                    clearLines()
                end
            elseif key == keys.up then
                rotatePiece()
            elseif key == keys.space then
                while not checkCollision(currentPiece.x, currentPiece.y + 1, currentPiece.shape) do
                    currentPiece.y = currentPiece.y + 1
                end
                mergePiece()
                clearLines()
            end
        elseif event == "timer" then
            if not checkCollision(currentPiece.x, currentPiece.y + 1, currentPiece.shape) then
                currentPiece.y = currentPiece.y + 1
            else
                mergePiece()
                clearLines()
            end
            os.startTimer(0.5)
        end

        if event ~= "timer" then
            os.startTimer(0.5)
        end
    end
end

-- Start the game
term.clear()
term.setCursorBlink(false)
os.startTimer(0.5)
gameLoop()
