Map = Class{}

TILE_BRICK = 1
TILE_EMPTY = 4

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

    -- filling the map with empty tiles
    for y=1,self.mapHeight / 2 do
        for x=1,self.mapWidth do
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    -- starts halfway down the map populates bricks
    for y=self.mapHeight / 2, self.mapHeight do
        for x=1,self.mapWidth do
            self:setTile(x, y, TILE_BRICK)
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

    self.camX = love.keyboard.isDown('a') and math.max(0, math.floor( self.camX + dt * -SCROLL_SPEED )) or love.keyboard.isDown('d') and math.min(self.mapWidthPixles - VIRTUAL_WIDTH, math.floor( self.camX + dt * SCROLL_SPEED )) or self.camX
    self.camY = love.keyboard.isDown('w') and math.max(0, math.floor( self.camY + dt * -SCROLL_SPEED )) or love.keyboard.isDown('s') and math.min(self.mapHeightPixles - VIRTUAL_HEIGHT, math.floor( self.camY + dt * SCROLL_SPEED )) or self.camY

end

function Map:render( )
    for y=1,self.mapHeight do
        for x=1,self.mapWidth do
            love.graphics.draw(self.spriteSheet, self.tileSprites[self:getTile(x, y)], 
        (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
        end
    end
end