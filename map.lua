--[[
    Contains tile data and necessary code for rendering a tile map to the
    screen.
]]

require 'Util'

Map = Class{}

TILE_BRICK = 1
TILE_EMPTY = 4

-- cloud tiles
CLOUD_LEFT = 6
CLOUD_RIGHT = 7

-- bush tiles
BUSH_LEFT = 2
BUSH_RIGHT = 3

-- mushroom tiles
MUSHROOM_TOP = 10
MUSHROOM_BOTTOM = 11

-- jump block
JUMP_BLOCK = 5
JUMP_BLOCK_HIT = 9

-- flag pole BLOCK
POLE_TOP = TILE_EMPTY * 2
POLE = POLE_TOP + 4
POLE_BOTTOM = POLE + 4

-- flag BLOCK
FLAG_UNOPENED = 15
FLAG_HALF_OPENED = FLAG_UNOPENED - 1
FLAG_OPENED = FLAG_HALF_OPENED - 1

-- a speed to multiply delta time to scroll map; smooth value
local SCROLL_SPEED = 62

-- constructor for our map object
function Map:init()

    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
    self.tileWidth = 16
    self.tileHeight = 16
    self.sprites = generateQuads(self.spritesheet, self.tileWidth, self.tileHeight)
    self.music = love.audio.newSource('sounds/music.wav', 'static')

    self.mapWidth = 30 * 2
    self.mapHeight = 28
    self.tiles = {}

    -- applies positive Y influence on anything affected
    self.gravity = 20

    -- associate player with map
    self.player = Player(self)

    -- camera offsets
    self.camX = 0
    self.camY = 0

    -- cache width and height of map in pixels
    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight

    -- game statemachine
    self.gameState = 'play'

    -- current animation frame
    self.flag = nil

    -- used to determine flag behavior and animations
    self.flagState = 'flag-unopened'
    self.flagX = self.mapWidth - 9
    self.flagY = self.mapHeight / 2 - 1

    -- first, fill map with empty tiles
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            -- support for multiple sheets per tile; storing tiles as tables 
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    -- populate map with static level elements
    self:generateLevel()

    -- initialize all map animations
    self.animations = {
        ['flag-unopened'] = Animation({
            texture = self.spritesheet,
            frames = {
                self.sprites[FLAG_UNOPENED]
            }
        }),
        ['flag-midway'] = Animation({
            texture = self.spritesheet,
            frames = {
                self.sprites[FLAG_HALF_OPENED],
                self.sprites[FLAG_OPENED]
            },
            interval = 0.15
        }),
        ['flag-opened'] = Animation({
            texture = self.spritesheet,
            frames = {
                self.sprites[FLAG_OPENED]
            }
        })
    }

    -- behavior flag in map we can call based on player state
    self.behaviors = {
        ['flag-unopened'] = function(dt)
            if self:collides(self:tileAt(self.player.x - 1, self.player.y + self.player.height)) == -1 or
                self:collides(self:tileAt(self.player.x - 1, self.player.y)) == -1 or
                self:collides(self:tileAt(self.player.x - 1, self.player.y - 1)) == -1 or
                self:collides(self:tileAt(self.player.x, self.player.y - 1)) == -1 or
                self:collides(self:tileAt(self.player.x + self.player.width - 1, self.player.y - 1)) == -1 or
                self:collides(self:tileAt(self.player.x + self.player.width - 1, self.player.y)) == -1 or
                self:collides(self:tileAt(self.player.x + self.player.width - 1, self.player.y + self.player.height)) == -1 then
                self.flagState = 'flag-midway'
                self.animations[self.flagState]:restart()
                self.flagY = self.flagY - 1
                self.animation = self.animations[self.flagState]
            end
        end,
        ['flag-midway'] = function(dt)
            if self.flagY < self.mapHeight / 2 - 11 and self.flagY > self.mapHeight / 2 - 1  then
                self.flagY = self.flagY - 1
            else
                self.flagState = 'flag-opened'
                self.animation = self.animations[self.flagState]
            end            
        end,
        ['flag-opened'] = function(dt)
            self.gameState = 'won'
            self.animation = self.animations[self.flagState]
        end,
    }

    -- initialize animation and current frame we should render
    self.animation = self.animations[self.flagState]
    self.flag = self.animation:getCurrentFrame()

    -- start the background music
    self.music:setLooping(true)
    self.music:setVolume(0.25)
    self.music:play()
end

function Map:generateLevel( )
    -- begin generating the terrain using vertical scan lines
    local x = 1
    while x < self.mapWidth do
        
        -- 5% chance to generate a cloud
        -- make sure we're 2 tiles from edge at least
        if x < self.mapWidth - 2 and math.random(20) == 1 then
            -- choose a random vertical spot above where blocks/pipes generate
            local cloudStart = math.random(self.mapHeight / 2 - 6)

            -- make sure there's no cloud overlaping
            if not (self:getTile(x, cloudStart) == CLOUD_LEFT or self:getTile(x, cloudStart) == CLOUD_RIGHT or self:getTile(x+1, cloudStart) == CLOUD_LEFT or self:getTile(x+1, cloudStart) == CLOUD_RIGHT) then
                self:setTile(x, cloudStart, CLOUD_LEFT)
                self:setTile(x + 1, cloudStart, CLOUD_RIGHT)
            end
        end

        if x < 0.5 * self.mapWidth then
            -- 5% chance to generate a mushroom
            if math.random(20) == 1 and x ~= self:tileAt(self.player.x, self.player.y).x then
                -- top side of pipe
                local mushroomStart = self.mapHeight / 2
                
                -- make sure there's no overlaping betn mushroom tops and bushes
                if not (self:getTile(x, mushroomStart - 2) == BUSH_LEFT or self:getTile(x, mushroomStart - 2) == BUSH_RIGHT or self:getTile(x, mushroomStart - 1) == BUSH_LEFT or self:getTile(x, mushroomStart - 1) == BUSH_RIGHT) then
                    self:setTile(x, mushroomStart - 2, MUSHROOM_TOP)
                    self:setTile(x, mushroomStart - 1, MUSHROOM_BOTTOM)
                end

                -- creates column of tiles going to bottom of map
                for y = self.mapHeight / 2, self.mapHeight do
                    self:setTile(x, y, TILE_BRICK)
                end

                -- next vertical scan line
                x = x + 1

            -- 10% chance to generate bush, being sure to generate away from edge
            elseif math.random(10) == 1 and x < self.mapWidth - 3 then
                local bushLevel = self.mapHeight / 2 - 1

                for i = x+1, x+2 do
                    -- place bush component and then column of bricks
                    if i == x+1 then self:setTile(i, bushLevel, BUSH_LEFT) else self:setTile(i, bushLevel, BUSH_RIGHT) end

                    for y = self.mapHeight / 2, self.mapHeight do self:setTile(i, y, TILE_BRICK) end

                    -- 20% chance to create a block for Mario to hit
                    if math.random(5) == 1 then self:setTile(i, self.mapHeight / 2 - 4, JUMP_BLOCK) end
                end

                x = x + 2

            -- 10% chance to not generate nothing, creating a gap
            elseif math.random(10) ~= 1 then
                
                -- creates column of tiles going to bottom of map
                for y = self.mapHeight / 2, self.mapHeight do
                    self:setTile(x, y, TILE_BRICK)
                end

                -- 5% chance to create a block for Mario to hit
                if math.random(20) == 1 then
                    self:setTile(x, self.mapHeight / 2 - 4, JUMP_BLOCK)
                end

                -- next vertical scan line
                x = x + 1
            end
        else
            -- generate pyramid
            if x >= 0.5 * self.mapWidth and x < 0.7 * self.mapWidth then
                local steps = math.min(x - self.mapWidth/2, 10)
                for y = self.mapHeight / 2 - 1, self.mapHeight / 2 - steps, -1 do
                    self:setTile(x, y, MUSHROOM_BOTTOM)
                end
                self:setTile(x, self.mapHeight / 2 - steps -1, MUSHROOM_TOP)
            -- generate flag pole
            elseif x == self.flagX then
                self:setTile(x, self.flagY, POLE_BOTTOM)
                for y = self.flagY - 1, self.flagY - 10, -1 do
                    self:setTile(x, y, POLE)
                end
                self:setTile(x, self.flagY - 10, POLE_TOP)
            end
            -- creates column of tiles going to bottom of map
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end

            x = x + 1
        end
    end
    -- give our player ground to stand on
    x = self:tileAt(self.player.x, self.player.y).x
    -- creates column of tiles going to bottom of map
    for y = self.mapHeight / 2, self.mapHeight do
        self:setTile(x, y, TILE_BRICK)
    end
end

-- return whether a given tile is collidable
function Map:collides(tile)
    -- define our collidable tiles
    local collidables = {
        TILE_BRICK, JUMP_BLOCK, JUMP_BLOCK_HIT,
        MUSHROOM_TOP, MUSHROOM_BOTTOM
    }

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        elseif tile.id == POLE or tile.id == POLE_BOTTOM or tile.id == POLE_TOP then
            return -1
        end
    end

    return false
end

-- function to update camera offset with delta time
function Map:update(dt)
    if self.gameState == 'play' then
        self.player:update(dt)
        
        -- keep camera's X coordinate following the player, preventing camera from
        -- scrolling past 0 to the left and the map's width
        self.camX = math.max(0, math.min(self.player.x - VIRTUAL_WIDTH / 2,
                        math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x)))

        self.behaviors[self.flagState](dt)
        self.animation:update(dt)
        self.flag = self.animation:getCurrentFrame()
    end
    if self.flagState ~= 'flag-unopened' and self.flagY > 3 then self.flagY = self.flagY - 1 end
end

-- gets the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end

-- returns an integer value for the tile at a given x-y coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

-- sets a tile at a given x-y coordinate to an integer value
function Map:setTile(x, y, id)
    self.tiles[(y - 1) * self.mapWidth + x] = id
end

-- renders our map to the screen, to be called by main's render
function Map:render()

    -- rwnder the generated map
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spritesheet, self.sprites[tile],
                    (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
            end
        end
    end

    -- draw flag
    love.graphics.draw(self.spritesheet, self.flag, self.flagX * self.tileWidth, (self.flagY - 1) * self.tileHeight)

    -- display game over if player falls
    if self.gameState == 'over' or self.gameState == 'won' then
        love.graphics.setFont(love.graphics.newFont('fonts/font.ttf', 8*4))
        local msg = (self.gameState == 'over') and 'game over' or 'you won'
        love.graphics.printf(tostring(msg), self.camX, self.camY + VIRTUAL_HEIGHT/2 - 20, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(love.graphics.newFont('fonts/font.ttf', 8))
    end
    love.graphics.printf('Press esc to quit', self.camX, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('"a" and "d" to move', self.camX, 20, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('space to jump', self.camX, 30, VIRTUAL_WIDTH, 'center')

    self.player:render()
end
