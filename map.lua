require("Util")
require("Player")

Map = Class{}

TILE_BRICK = 1
TILE_EMPTY = -1

CLOUD_LEFT = 6
CLOUD_RIGHT = 7

BUSH_LEFT = 2
BUSH_RIGHT = 3

MUSHROOM_TOP = 10
MUSHROOM_BOTTOM = 11

JUMP_BLOCK = 5

local SCROLL_SPEED = 62

function Map:init( ... )
    self.spriteSheet = love.graphics.newImage('graphics/spritesheet.png')
    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 30
    self.mapHeight = 28
    self.tiles = {}

    self.camX = 0
    self.camY = -3

    self.tileSprites = generateQuads(self.spriteSheet, self.tileWidth, self.tileHeight)

    self.mapWidthPixles = self.mapWidth * self.tileWidth
    self.mapHeightPixles = self.mapHeight * self.tileHeight

    self.player = Player(self)

    -- filling the map with empty tiles
    for y=1,self.mapHeight do
        for x=1,self.mapWidth do
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    local x = 1
    while x < self.mapWidth do

        if x < self.mapWidth - 2 then
            if math.random( 20 ) == 1 then
                local cloudStart = math.random( self.mapHeight / 2 - 6 )
                self:setTile(x, cloudStart, CLOUD_LEFT)
                self:setTile(x+1, cloudStart, CLOUD_RIGHT)
            end
        end

        if math.random( 20 ) == 1 then
            self:setTile(x, self.mapHeight / 2 - 2, MUSHROOM_TOP)
            self:setTile(x, self.mapHeight / 2 - 1, MUSHROOM_BOTTOM)

            for y=self.mapHeight / 2,self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end

            x = x + 1
        elseif math.random( 10 ) == 1 and x < self.mapWidth - 3 then
            local bushLevel = self.mapHeight / 2 - 1

            self:setTile(x, bushLevel, BUSH_LEFT)
            for y=self.mapHeight / 2,self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end
            x = x + 1

            self:setTile(x, bushLevel, BUSH_RIGHT)
            for y=self.mapHeight / 2,self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end
            x = x + 1
            
        elseif math.random( 10 ) ~= 1 then
            for y=self.mapHeight / 2,self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end

            if math.random( 15 ) == 1 then
                self:setTile(x, self.mapHeight / 2 - 4, JUMP_BLOCK)
            end

            x = x + 1
        else
            x = x + 2
        end
    end
end

function Map:setTile( x, y, tile )
    self.tiles[(y - 1) * self.mapWidth + x] = tile
end

function Map:getTile( x, y )
    return self.tiles[(y - 1) * self.mapWidth + x]
end

function Map:update( dt )

    -- self.camX = love.keyboard.isDown('a') and math.max(0, math.floor( self.camX + dt * -SCROLL_SPEED )) or love.keyboard.isDown('d') and math.min(self.mapWidthPixles - VIRTUAL_WIDTH, math.floor( self.camX + dt * SCROLL_SPEED )) or self.camX
    -- self.camY = love.keyboard.isDown('w') and math.max(0, math.floor( self.camY + dt * -SCROLL_SPEED )) or love.keyboard.isDown('s') and math.min(self.mapHeightPixles - VIRTUAL_HEIGHT, math.floor( self.camY + dt * SCROLL_SPEED )) or self.camY

    self.camX = math.max( 0,
        math.min( self.player.x - VIRTUAL_WIDTH / 2,
            math.min( self.mapWidthPixles - VIRTUAL_WIDTH,self.player.x ) ) )

    self.player:update(dt)
end

function Map:render( )
    for y=1,self.mapHeight do
        for x=1,self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spriteSheet, self.tileSprites[tile],
                    (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
            end
        end
    end

    self.player:render()
end