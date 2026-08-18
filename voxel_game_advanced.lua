--[[
    Voxel Blocky Game - Advanced Edition with Carnage Mode
    Features:
    - Transform into a carnage monster
    - Bullet physics with reflection
    - Enemy AI with guns
    - Grab and ragdoll mechanics
    - PBR (Physically Based Rendering) materials
    - Advanced lighting, shadows, and HDR rendering
]]--

-- ======================== CONSTANTS ========================
local CHUNK_SIZE = 16
local WORLD_HEIGHT = 256
local RENDER_DISTANCE = 10
local BLOCK_SIZE = 1.0

-- Block types
local BLOCK_TYPES = {
    AIR = 0,
    STONE = 1,
    DIRT = 2,
    GRASS = 3,
    WOOD = 4,
    SAND = 5,
    WATER = 6,
    METAL = 7,
    CONCRETE = 8,
    GLASS = 9,
}

-- Photorealistic PBR materials
local MATERIALS = {
    [BLOCK_TYPES.STONE] = {
        color = {0.45, 0.45, 0.48},
        roughness = 0.8,
        metallic = 0.0,
        ao = 0.6,
        normal_scale = 1.2,
        displacement = 0.3,
        specular = {0.5, 0.5, 0.5},
    },
    [BLOCK_TYPES.DIRT] = {
        color = {0.55, 0.37, 0.2},
        roughness = 0.95,
        metallic = 0.0,
        ao = 0.5,
        normal_scale = 0.8,
        displacement = 0.2,
        specular = {0.2, 0.2, 0.2},
    },
    [BLOCK_TYPES.GRASS] = {
        color = {0.2, 0.6, 0.15},
        roughness = 0.85,
        metallic = 0.0,
        ao = 0.4,
        normal_scale = 1.0,
        displacement = 0.25,
        specular = {0.3, 0.3, 0.3},
    },
    [BLOCK_TYPES.WOOD] = {
        color = {0.54, 0.37, 0.15},
        roughness = 0.6,
        metallic = 0.0,
        ao = 0.7,
        normal_scale = 1.5,
        displacement = 0.4,
        specular = {0.4, 0.35, 0.25},
    },
    [BLOCK_TYPES.SAND] = {
        color = {0.92, 0.88, 0.38},
        roughness = 0.98,
        metallic = 0.0,
        ao = 0.5,
        normal_scale = 0.6,
        displacement = 0.15,
        specular = {0.2, 0.2, 0.15},
    },
    [BLOCK_TYPES.WATER] = {
        color = {0.05, 0.3, 0.6},
        roughness = 0.05,
        metallic = 0.0,
        ao = 1.0,
        normal_scale = 2.0,
        displacement = 0.5,
        refraction = 0.8,
        specular = {1.0, 1.0, 1.0},
    },
    [BLOCK_TYPES.METAL] = {
        color = {0.75, 0.75, 0.78},
        roughness = 0.2,
        metallic = 1.0,
        ao = 0.8,
        normal_scale = 0.5,
        displacement = 0.1,
        specular = {0.9, 0.9, 0.95},
    },
    [BLOCK_TYPES.CONCRETE] = {
        color = {0.5, 0.5, 0.5},
        roughness = 0.7,
        metallic = 0.1,
        ao = 0.4,
        normal_scale = 1.3,
        displacement = 0.35,
        specular = {0.4, 0.4, 0.4},
    },
    [BLOCK_TYPES.GLASS] = {
        color = {0.8, 0.95, 1.0},
        roughness = 0.05,
        metallic = 0.0,
        ao = 1.0,
        normal_scale = 0.3,
        displacement = 0.0,
        transparency = 0.9,
        ior = 1.5,
        specular = {1.0, 1.0, 1.0},
    },
}

-- ======================== BULLET PHYSICS ========================
local Bullet = {}
Bullet.__index = Bullet

function Bullet:new(x, y, z, vx, vy, vz)
    local self = setmetatable({}, Bullet)
    self.x = x
    self.y = y
    self.z = z
    self.vx = vx
    self.vy = vy
    self.vz = vz
    self.age = 0
    self.maxAge = 10.0
    self.size = 0.1
    self.reflections = 0
    self.maxReflections = 5
    self.damage = 15
    self.speed = math.sqrt(vx*vx + vy*vy + vz*vz)
    return self
end

function Bullet:update(dt, player)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.z = self.z + self.vz * dt
    self.age = self.age + dt
    
    -- Check collision with carnage player
    if player.isCarnage then
        local dx = player.x - self.x
        local dy = player.y - self.z
        local dz = player.z - self.z
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
        
        if dist < player.carnageRadius then
            -- Reflect bullet
            local normalX = dx / dist
            local normalY = dy / dist
            local normalZ = dz / dist
            
            local dotProduct = self.vx * normalX + self.vy * normalY + self.vz * normalZ
            
            self.vx = self.vx - 2 * dotProduct * normalX
            self.vy = self.vy - 2 * dotProduct * normalY
            self.vz = self.vz - 2 * dotProduct * normalZ
            
            self.reflections = self.reflections + 1
            
            if self.reflections >= self.maxReflections then
                self.age = self.maxAge
            end
        end
    end
end

function Bullet:isAlive()
    return self.age < self.maxAge
end

-- ======================== ADVANCED LIGHTING ENGINE ========================
local LightingEngine = {}
LightingEngine.__index = LightingEngine

function LightingEngine:new()
    local self = setmetatable({}, LightingEngine)
    self.sunPosition = {200, 300, 200}
    self.sunColor = {1.0, 0.95, 0.8}
    self.sunIntensity = 2.0
    self.ambientColor = {0.3, 0.4, 0.5}
    self.ambientIntensity = 0.8
    self.skyColor = {0.5, 0.7, 1.0}
    self.horizonColor = {1.0, 0.7, 0.5}
    self.lights = {}
    self.shadowMaps = {}
    self.time = 0
    return self
end

function LightingEngine:addLight(x, y, z, color, intensity, radius)
    table.insert(self.lights, {
        x = x, y = y, z = z,
        color = color,
        intensity = intensity,
        radius = radius,
        age = 0,
        decay = 0.5,
    })
end

function LightingEngine:calculatePBR(x, y, z, normal, viewDir, material)
    local light = {self.ambientIntensity * self.ambientColor[1], 
                   self.ambientIntensity * self.ambientColor[2], 
                   self.ambientIntensity * self.ambientColor[3]}
    
    local sunDir = {
        self.sunPosition[1] - x,
        self.sunPosition[2] - y,
        self.sunPosition[3] - z,
    }
    local sunDist = math.sqrt(sunDir[1]^2 + sunDir[2]^2 + sunDir[3]^2)
    if sunDist > 0 then
        sunDir[1] = sunDir[1] / sunDist
        sunDir[2] = sunDir[2] / sunDist
        sunDir[3] = sunDir[3] / sunDist
    end
    
    local dotProduct = math.max(0, normal[1] * viewDir[1] + normal[2] * viewDir[2] + normal[3] * viewDir[3])
    local fresnel = 0.04 + (1 - 0.04) * math.pow(1 - dotProduct, 5)
    
    local roughness = material.roughness
    local alpha = roughness * roughness
    local halfVector = {sunDir[1] + viewDir[1], sunDir[2] + viewDir[2], sunDir[3] + viewDir[3]}
    local hLen = math.sqrt(halfVector[1]^2 + halfVector[2]^2 + halfVector[3]^2)
    if hLen > 0 then
        halfVector[1] = halfVector[1] / hLen
        halfVector[2] = halfVector[2] / hLen
        halfVector[3] = halfVector[3] / hLen
    end
    
    local NDotH = math.max(0, normal[1] * halfVector[1] + normal[2] * halfVector[2] + normal[3] * halfVector[3])
    local specular = fresnel * math.pow(math.max(0, 1 - alpha * (1 - NDotH * NDotH)), 2)
    
    local sunDot = math.max(0, normal[1] * sunDir[1] + normal[2] * sunDir[2] + normal[3] * sunDir[3])
    local specIntensity = material.metallic * 0.8 + (1 - material.metallic) * 0.2
    
    light[1] = light[1] + (sunDot * material.color[1] * (1 - specIntensity) + specular * material.specular[1]) * self.sunColor[1] * self.sunIntensity
    light[2] = light[2] + (sunDot * material.color[2] * (1 - specIntensity) + specular * material.specular[2]) * self.sunColor[2] * self.sunIntensity
    light[3] = light[3] + (sunDot * material.color[3] * (1 - specIntensity) + specular * material.specular[3]) * self.sunColor[3] * self.sunIntensity
    
    for i = #self.lights, 1, -1 do
        local lamp = self.lights[i]
        lamp.age = lamp.age + 0.016
        if lamp.age > 5 then
            table.remove(self.lights, i)
        else
            local dx = lamp.x - x
            local dy = lamp.y - y
            local dz = lamp.z - z
            local dist = math.sqrt(dx^2 + dy^2 + dz^2)
            
            if dist < lamp.radius then
                local falloff = 1.0 - (dist / lamp.radius)
                local decay = math.pow(lamp.decay, lamp.age)
                local dotProduct = math.max(0, (normal[1] * dx + normal[2] * dy + normal[3] * dz) / (dist + 0.001))
                local intensity = dotProduct * lamp.intensity * falloff * decay
                
                light[1] = light[1] + intensity * lamp.color[1]
                light[2] = light[2] + intensity * lamp.color[2]
                light[3] = light[3] + intensity * lamp.color[3]
            end
        end
    end
    
    light[1] = light[1] * material.ao
    light[2] = light[2] * material.ao
    light[3] = light[3] * material.ao
    
    return light
end

-- ======================== ADVANCED PARTICLE SYSTEM ========================
local ParticleSystem = {}
ParticleSystem.__index = ParticleSystem

function ParticleSystem:new()
    local self = setmetatable({}, ParticleSystem)
    self.particles = {}
    self.bloodParticles = {}
    return self
end

function ParticleSystem:emitDebris(x, y, z, blockType, count, force)
    count = count or 20
    force = force or 1.0
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local elevation = (math.random() - 0.5) * math.pi
        local velocity = (5 + math.random() * 15) * force
        table.insert(self.particles, {
            x = x + (math.random() - 0.5) * 0.8,
            y = y + (math.random() - 0.5) * 0.8,
            z = z + (math.random() - 0.5) * 0.8,
            vx = math.cos(angle) * math.cos(elevation) * velocity,
            vy = math.sin(elevation) * velocity,
            vz = math.sin(angle) * math.cos(elevation) * velocity,
            life = 3.0 + math.random(),
            maxLife = 3.0 + math.random(),
            size = 0.1 + math.random() * 0.3,
            blockType = blockType,
            rotation = math.random() * math.pi * 2,
            angularVelocity = (math.random() - 0.5) * 20,
            bounce = 3,
        })
    end
end

function ParticleSystem:emitBlood(x, y, z, count, force)
    count = count or 30
    force = force or 1.5
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local elevation = (math.random() - 0.3) * 1.2
        local velocity = (3 + math.random() * 12) * force
        table.insert(self.bloodParticles, {
            x = x,
            y = y,
            z = z,
            vx = math.cos(angle) * math.cos(elevation) * velocity,
            vy = math.sin(elevation) * velocity,
            vz = math.sin(angle) * math.cos(elevation) * velocity,
            life = 4.0 + math.random(),
            maxLife = 4.0 + math.random(),
            size = 0.15 + math.random() * 0.35,
            color = {0.7 + math.random() * 0.3, 0.05, 0.05},
            alpha = 1.0,
            splat = false,
        })
    end
end

function ParticleSystem:update(dt)
    local gravity = 25
    
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.z = p.z + p.vz * dt
        p.vy = p.vy - gravity * dt
        p.life = p.life - dt
        p.rotation = p.rotation + p.angularVelocity * dt
        
        p.vx = p.vx * 0.98
        p.vz = p.vz * 0.98
        
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
    
    for i = #self.bloodParticles, 1, -1 do
        local b = self.bloodParticles[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.z = b.z + b.vz * dt
        b.vy = b.vy - gravity * dt
        b.life = b.life - dt
        b.alpha = b.life / b.maxLife
        
        b.vx = b.vx * 0.97
        b.vz = b.vz * 0.97
        
        if b.life <= 0 then
            table.remove(self.bloodParticles, i)
        end
    end
end

-- ======================== RAGDOLL PHYSICS WITH GORE ========================
local Ragdoll = {}
Ragdoll.__index = Ragdoll

function Ragdoll:new(x, y, z, force)
    local self = setmetatable({}, Ragdoll)
    force = force or 1.0
    self.bones = {
        {x = x, y = y + 0.9, z = z, vx = (math.random() - 0.5) * 10 * force, vy = (math.random() + 0.5) * 10 * force, vz = (math.random() - 0.5) * 10 * force, mass = 4, radius = 0.15, bloodLevel = 0.8},
        {x = x, y = y + 0.4, z = z, vx = (math.random() - 0.5) * 8 * force, vy = (math.random() + 0.2) * 5 * force, vz = (math.random() - 0.5) * 8 * force, mass = 8, radius = 0.2, bloodLevel = 1.0},
        {x = x - 0.3, y = y + 0.3, z = z, vx = (math.random() - 0.5) * 15 * force, vy = (math.random() + 0.3) * 8 * force, vz = (math.random() - 0.5) * 15 * force, mass = 2, radius = 0.1, bloodLevel = 0.5},
        {x = x + 0.3, y = y + 0.3, z = z, vx = (math.random() - 0.5) * 15 * force, vy = (math.random() + 0.3) * 8 * force, vz = (math.random() - 0.5) * 15 * force, mass = 2, radius = 0.1, bloodLevel = 0.5},
        {x = x - 0.2, y = y - 0.3, z = z, vx = (math.random() - 0.5) * 12 * force, vy = (math.random() + 0.2) * 6 * force, vz = (math.random() - 0.5) * 12 * force, mass = 3, radius = 0.12, bloodLevel = 0.6},
        {x = x + 0.2, y = y - 0.3, z = z, vx = (math.random() - 0.5) * 12 * force, vy = (math.random() + 0.2) * 6 * force, vz = (math.random() - 0.5) * 12 * force, mass = 3, radius = 0.12, bloodLevel = 0.6},
    }
    self.life = 8.0
    self.decayTime = 15.0
    self.bloodTrail = {}
    self.health = 100
    self.severed = {}
    return self
end

function Ragdoll:applyForce(fx, fy, fz)
    for _, bone in ipairs(self.bones) do
        bone.vx = bone.vx + fx / bone.mass
        bone.vy = bone.vy + fy / bone.mass
        bone.vz = bone.vz + fz / bone.mass
    end
    self.health = self.health - (math.sqrt(fx*fx + fy*fy + fz*fz) / 10)
end

function Ragdoll:update(dt, world, particles)
    local gravity = 25
    
    for i, bone in ipairs(self.bones) do
        if not self.severed[i] then
            bone.vy = bone.vy - gravity * dt
            
            bone.x = bone.x + bone.vx * dt
            bone.y = bone.y + bone.vy * dt
            bone.z = bone.z + bone.vz * dt
            
            bone.vx = bone.vx * 0.99
            bone.vz = bone.vz * 0.99
            
            if math.random() < 0.3 then
                table.insert(self.bloodTrail, {
                    x = bone.x,
                    y = bone.y,
                    z = bone.z,
                    life = 5.0,
                    size = 0.08 + math.random() * 0.12,
                })
            end
            
            if bone.y < 1 then
                bone.y = 1
                bone.vy = bone.vy * -0.2
                bone.vx = bone.vx * 0.7
                bone.vz = bone.vz * 0.7
                
                if particles and bone.bloodLevel > 0 then
                    particles:emitBlood(bone.x, bone.y + 0.1, bone.z, 8, 0.3)
                    bone.bloodLevel = bone.bloodLevel - 0.05
                end
            end
        end
    end
    
    self.life = self.life - dt
    self.decayTime = self.decayTime - dt
    
    if self.health < 50 and math.random() < 0.01 then
        local limbIndex = math.random(3, 6)
        self.severed[limbIndex] = true
        if particles then
            particles:emitBlood(self.bones[limbIndex].x, self.bones[limbIndex].y, self.bones[limbIndex].z, 25, 2.0)
        end
    end
end

-- ======================== ENEMY SOLDIER ========================
local Enemy = {}
Enemy.__index = Enemy

function Enemy:new(x, y, z, player)
    local self = setmetatable({}, Enemy)
    self.x = x
    self.y = y
    self.z = z
    self.vx = 0
    self.vy = 0
    self.vz = 0
    self.yaw = 0
    self.pitch = 0
    
    self.health = 100
    self.maxHealth = 100
    self.speed = 0.15
    self.width = 0.6
    self.height = 1.8
    self.isGrounded = false
    
    self.shootTimer = 0
    self.shootInterval = 1.5
    self.fireRate = 0.1
    self.bullets = {}
    self.player = player
    
    self.state = "patrol" -- patrol, chase, shoot
    self.patrolTimer = 0
    self.patrolTarget = {x = x + math.random(-20, 20), z = z + math.random(-20, 20)}
    
    self.chaseRange = 50
    self.shootRange = 40
    self.detectionRange = 60
    
    return self
end

function Enemy:update(dt, world, player)
    local dx = player.x - self.x
    local dz = player.z - self.z
    local dist = math.sqrt(dx*dx + dz*dz)
    
    -- AI state machine
    if dist < self.detectionRange then
        if dist < self.shootRange then
            self.state = "shoot"
        else
            self.state = "chase"
        end
    else
        self.state = "patrol"
    end
    
    if self.state == "patrol" then
        self:patrol(dt, world)
    elseif self.state == "chase" then
        self:chase(dt, world, dx, dz)
    elseif self.state == "shoot" then
        self:shoot(dt, world, dx, dz)
    end
    
    -- Update position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.z = self.z + self.vz * dt
    
    -- Gravity
    self.vy = self.vy - 25 * dt
    
    -- Collision
    self:handleCollisions(world)
    
    -- Update bullets
    for i = #self.bullets, 1, -1 do
        self.bullets[i]:update(dt, player)
        if not self.bullets[i]:isAlive() then
            table.remove(self.bullets, i)
        end
    end
    
    self.shootTimer = self.shootTimer - dt
end

function Enemy:patrol(dt, world)
    local dx = self.patrolTarget.x - self.x
    local dz = self.patrolTarget.z - self.z
    local dist = math.sqrt(dx*dx + dz*dz)
    
    if dist < 5 then
        self.patrolTarget = {x = self.x + math.random(-20, 20), z = self.z + math.random(-20, 20)}
    else
        local angle = math.atan2(dz, dx)
        self.vx = math.cos(angle) * self.speed
        self.vz = math.sin(angle) * self.speed
    end
end

function Enemy:chase(dt, world, dx, dz)
    local dist = math.sqrt(dx*dx + dz*dz)
    if dist > 0 then
        self.vx = (dx / dist) * self.speed * 1.5
        self.vz = (dz / dist) * self.speed * 1.5
        self.yaw = math.atan2(dz, dx)
    end
end

function Enemy:shoot(dt, world, dx, dz)
    local dist = math.sqrt(dx*dx + dz*dz)
    if dist > 0 then
        self.yaw = math.atan2(dz, dx)
        local dy = self.player.y - self.y
        self.pitch = math.atan2(dy, dist)
    end
    
    self.vx = 0
    self.vz = 0
    
    -- Fire bullets
    if self.shootTimer <= 0 then
        self:fireBullet()
        self.shootTimer = self.fireRate
    end
end

function Enemy:fireBullet()
    local cos_pitch = math.cos(self.pitch)
    local bulletVx = math.cos(self.yaw) * cos_pitch * 50
    local bulletVy = math.sin(self.pitch) * 50
    local bulletVz = math.sin(self.yaw) * cos_pitch * 50
    
    local bullet = Bullet:new(
        self.x,
        self.y + self.height / 2,
        self.z,
        bulletVx,
        bulletVy,
        bulletVz
    )
    table.insert(self.bullets, bullet)
end

function Enemy:takeDamage(damage)
    self.health = self.health - damage
end

function Enemy:handleCollisions(world)
    local checkY = math.floor(self.y - self.height / 2)
    local blockBelow = world:getBlock(math.floor(self.x), checkY - 1, math.floor(self.z))
    
    if blockBelow ~= BLOCK_TYPES.AIR then
        self.isGrounded = true
        self.y = checkY + 0.5 + self.height / 2
        self.vy = math.min(0, self.vy)
    else
        self.isGrounded = false
    end
end

function Enemy:isAlive()
    return self.health > 0
end

function Enemy:getCenter()
    return {x = self.x, y = self.y, z = self.z}
end

-- ======================== PERLIN NOISE ========================
local Perlin = {}

function Perlin.fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

function Perlin.lerp(t, a, b)
    return a + t * (b - a)
end

function Perlin:noise(x, y, z)
    z = z or 0
    local xi = math.floor(x) % 256
    local yi = math.floor(y) % 256
    local zi = math.floor(z) % 256
    
    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)
    
    local u = self.fade(x)
    local v = self.fade(y)
    
    local function hash(a, b, c)
        return math.abs(math.sin(a * 12.9898 + b * 78.233 + c * 43.614) * 43758.5453) % 1
    end
    
    local n0 = hash(xi, yi, zi)
    local n1 = hash(xi + 1, yi, zi)
    local nx0 = self.lerp(u, n0, n1)
    
    return nx0 * 2 - 1
end

-- ======================== VOXEL WORLD ========================
local VoxelWorld = {}
VoxelWorld.__index = VoxelWorld

function VoxelWorld:new()
    local self = setmetatable({}, VoxelWorld)
    self.chunks = {}
    self.perlin = Perlin
    self.lighting = LightingEngine:new()
    return self
end

function VoxelWorld:getChunkKey(cx, cy, cz)
    return string.format("%d,%d,%d", cx, cy, cz)
end

function VoxelWorld:getChunk(cx, cy, cz)
    local key = self:getChunkKey(cx, cy, cz)
    if not self.chunks[key] then
        self.chunks[key] = self:generateChunk(cx, cy, cz)
    end
    return self.chunks[key]
end

function VoxelWorld:generateChunk(cx, cy, cz)
    local chunk = {}
    for x = 0, CHUNK_SIZE - 1 do
        chunk[x] = chunk[x] or {}
        for y = 0, CHUNK_SIZE - 1 do
            chunk[x][y] = chunk[x][y] or {}
            for z = 0, CHUNK_SIZE - 1 do
                local worldX = cx * CHUNK_SIZE + x
                local worldY = cy * CHUNK_SIZE + y
                local worldZ = cz * CHUNK_SIZE + z
                
                local noise1 = self.perlin:noise(worldX * 0.02, worldZ * 0.02)
                local noise2 = self.perlin:noise(worldX * 0.08, worldZ * 0.08)
                local noise3 = self.perlin:noise(worldX * 0.15, worldZ * 0.15)
                local noiseVal = noise1 * 0.5 + noise2 * 0.3 + noise3 * 0.2
                
                local terrainHeight = 64 + noiseVal * 40
                
                if worldY < terrainHeight - 15 then
                    chunk[x][y][z] = BLOCK_TYPES.STONE
                elseif worldY < terrainHeight - 4 then
                    chunk[x][y][z] = BLOCK_TYPES.DIRT
                elseif worldY == math.floor(terrainHeight) then
                    chunk[x][y][z] = BLOCK_TYPES.GRASS
                elseif worldY < 35 then
                    chunk[x][y][z] = BLOCK_TYPES.WATER
                else
                    chunk[x][y][z] = BLOCK_TYPES.AIR
                end
            end
        end
    end
    return chunk
end

function VoxelWorld:getBlock(x, y, z)
    if y < 0 or y >= WORLD_HEIGHT then
        return BLOCK_TYPES.AIR
    end
    
    local cx = math.floor(x / CHUNK_SIZE)
    local cy = math.floor(y / CHUNK_SIZE)
    local cz = math.floor(z / CHUNK_SIZE)
    
    local lx = x - (cx * CHUNK_SIZE)
    local ly = y - (cy * CHUNK_SIZE)
    local lz = z - (cz * CHUNK_SIZE)
    
    if lx < 0 then lx = lx + CHUNK_SIZE end
    if lz < 0 then lz = lz + CHUNK_SIZE end
    
    local chunk = self:getChunk(cx, cy, cz)
    return chunk[lx] and chunk[lx][ly] and chunk[lx][ly][lz] or BLOCK_TYPES.AIR
end

function VoxelWorld:setBlock(x, y, z, blockType)
    if y < 0 or y >= WORLD_HEIGHT then
        return
    end
    
    local cx = math.floor(x / CHUNK_SIZE)
    local cy = math.floor(y / CHUNK_SIZE)
    local cz = math.floor(z / CHUNK_SIZE)
    
    local lx = x - (cx * CHUNK_SIZE)
    local ly = y - (cy * CHUNK_SIZE)
    local lz = z - (cz * CHUNK_SIZE)
    
    if lx < 0 then lx = lx + CHUNK_SIZE end
    if lz < 0 then lz = lz + CHUNK_SIZE end
    
    local chunk = self:getChunk(cx, cy, cz)
    if chunk[lx] and chunk[lx][ly] then
        chunk[lx][ly][lz] = blockType
    end
end

function VoxelWorld:createExplosion(x, y, z, radius, particles)
    particles = particles or ParticleSystem:new()
    local radiusSq = radius * radius
    
    for dx = -radius, radius do
        for dy = -radius, radius do
            for dz = -radius, radius do
                if dx*dx + dy*dy + dz*dz <= radiusSq then
                    local bx, by, bz = math.floor(x) + dx, math.floor(y) + dy, math.floor(z) + dz
                    local block = self:getBlock(bx, by, bz)
                    if block ~= BLOCK_TYPES.AIR then
                        local force = 1.0 - (math.sqrt(dx*dx + dy*dy + dz*dz) / radius)
                        particles:emitDebris(bx, by, bz, block, 8, force)
                        self:setBlock(bx, by, bz, BLOCK_TYPES.AIR)
                    end
                end
            end
        end
    end
    
    self.lighting:addLight(x, y, z, {1.0, 0.8, 0.3}, 3.0, radius * 4)
end

-- ======================== PLAYER ========================
local Player = {}
Player.__index = Player

function Player:new(x, y, z)
    local self = setmetatable({}, Player)
    self.x = x or 50
    self.y = y or 140
    self.z = z or 50
    
    self.vx = 0
    self.vy = 0
    self.vz = 0
    
    self.yaw = 0
    self.pitch = 0
    
    self.speed = 0.2
    self.sprintSpeed = 0.4
    self.jumpPower = 12
    self.isGrounded = false
    self.height = 1.8
    self.width = 0.6
    
    -- Carnage mode
    self.isCarnage = false
    self.carnageHealth = 100
    self.carnageMaxHealth = 300
    self.carnageRadius = 3.0
    self.carnageStrength = 2.0
    self.carnageTransformTimer = 0
    self.carnageTransformDuration = 30.0 -- 30 seconds
    self.grabTarget = nil
    self.grabCooldown = 0
    
    return self
end

function Player:update(world, dt, input)
    local moveX = 0
    local moveZ = 0
    local currentSpeed = input.sprint and self.sprintSpeed or self.speed
    
    if input.forward then moveZ = moveZ - currentSpeed end
    if input.backward then moveZ = moveZ + currentSpeed end
    if input.left then moveX = moveX - currentSpeed end
    if input.right then moveX = moveX + currentSpeed end
    
    local angle = self.yaw
    local cos_angle = math.cos(angle)
    local sin_angle = math.sin(angle)
    
    self.vx = moveX * cos_angle - moveZ * sin_angle
    self.vz = moveX * sin_angle + moveZ * cos_angle
    
    local gravity = 25
    self.vy = self.vy - gravity * dt
    
    if input.jump and self.isGrounded then
        self.vy = self.jumpPower
        self.isGrounded = false
    end
    
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.z = self.z + self.vz * dt
    
    self:handleCollisions(world)
    
    -- Carnage mode management
    if self.isCarnage then
        self.carnageTransformTimer = self.carnageTransformTimer - dt
        if self.carnageTransformTimer <= 0 then
            self:exitCarnage()
        end
        
        -- Enhanced speed in carnage
        self.speed = 0.35
        self.carnageRadius = 3.0 + math.sin(self.carnageTransformTimer) * 0.5
    end
    
    self.grabCooldown = math.max(0, self.grabCooldown - dt)
    
    if self.y < -100 then
        self.x = 50
        self.y = 120
        self.z = 50
        self.vy = 0
    end
end

function Player:handleCollisions(world)
    local checkY = math.floor(self.y - self.height / 2)
    local blockBelow = world:getBlock(math.floor(self.x), checkY - 1, math.floor(self.z))
    
    if blockBelow ~= BLOCK_TYPES.AIR then
        self.isGrounded = true
        self.y = checkY + 0.5 + self.height / 2
        self.vy = math.min(0, self.vy)
    else
        self.isGrounded = false
    end
end

function Player:look(dx, dy)
    local sensitivity = 0.003
    self.yaw = self.yaw + dx * sensitivity
    self.pitch = self.pitch + dy * sensitivity
    
    if self.pitch > math.pi / 2 then self.pitch = math.pi / 2 end
    if self.pitch < -math.pi / 2 then self.pitch = -math.pi / 2 end
end

function Player:getForwardVector()
    local cos_pitch = math.cos(self.pitch)
    return {
        math.sin(self.yaw) * cos_pitch,
        math.sin(self.pitch),
        math.cos(self.yaw) * cos_pitch
    }
end

function Player:transformToCarnage()
    if not self.isCarnage then
        self.isCarnage = true
        self.carnageHealth = self.carnageMaxHealth
        self.carnageTransformTimer = self.carnageTransformDuration
        self.height = 2.5
        self.width = 1.2
    end
end

function Player:exitCarnage()
    self.isCarnage = false
    self.height = 1.8
    self.width = 0.6
end

function Player:grab(enemy, particles)
    if self.grabCooldown <= 0 and self.isCarnage then
        if enemy then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local dz = enemy.z - self.z
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            
            if dist < self.carnageRadius * 2 then
                -- Grab and throw enemy
                local throwForce = 200 * self.carnageStrength
                local ragdoll = Ragdoll:new(enemy.x, enemy.y, enemy.z, 2.0)
                
                local normalX = dx / (dist + 0.001)
                local normalY = dy / (dist + 0.001)
                local normalZ = dz / (dist + 0.001)
                
                ragdoll:applyForce(
                    normalX * throwForce,
                    normalY * throwForce + 100,
                    normalZ * throwForce
                )
                particles:emitBlood(enemy.x, enemy.y, enemy.z, 40, 2.0)
                
                self.grabCooldown = 0.5
                return ragdoll
            end
        end
    end
    return nil
end

function Player:takeBulletDamage(damage)
    if self.isCarnage then
        self.carnageHealth = self.carnageHealth - damage * 0.3 -- Reduced damage in carnage mode
    end
end

-- ======================== RAYCAST ========================
local function raycast(world, x, y, z, dx, dy, dz, maxDist)
    local step = 0.05
    local dist = 0
    local lastX, lastY, lastZ = x, y, z
    
    while dist < maxDist do
        lastX, lastY, lastZ = x, y, z
        x = x + dx * step
        y = y + dy * step
        z = z + dz * step
        dist = dist + step
        
        local bx = math.floor(x)
        local by = math.floor(y)
        local bz = math.floor(z)
        
        local block = world:getBlock(bx, by, bz)
        if block ~= BLOCK_TYPES.AIR then
            return {
                hit = true,
                x = bx,
                y = by,
                z = bz,
                lastX = math.floor(lastX),
                lastY = math.floor(lastY),
                lastZ = math.floor(lastZ),
                block = block,
                distance = dist
            }
        end
    end
    
    return { hit = false }
end

-- ======================== GAME ENGINE ========================
local Game = {}
Game.__index = Game

function Game:new()
    local self = setmetatable({}, Game)
    self.world = VoxelWorld:new()
    self.player = Player:new(50, 140, 50)
    self.particles = ParticleSystem:new()
    self.ragdolls = {}
    self.enemies = {}
    self.input = {
        forward = false,
        backward = false,
        left = false,
        right = false,
        jump = false,
        sprint = false,
        carnage = false,
        grab = false,
    }
    self.selectedBlock = BLOCK_TYPES.CONCRETE
    self.hotbar = {
        BLOCK_TYPES.DIRT,
        BLOCK_TYPES.STONE,
        BLOCK_TYPES.CONCRETE,
        BLOCK_TYPES.WOOD,
        BLOCK_TYPES.GLASS,
    }
    self.hotbarIndex = 1
    
    -- Spawn enemies
    for i = 1, 5 do
        local angle = (i / 5) * math.pi * 2
        local dist = 40
        table.insert(self.enemies, Enemy:new(
            self.player.x + math.cos(angle) * dist,
            140,
            self.player.z + math.sin(angle) * dist,
            self.player
        ))
    end
    
    return self
end

function Game:update(dt)
    self.player:update(self.world, dt, self.input)
    self.particles:update(dt)
    
    -- Update enemies
    for i = #self.enemies, 1, -1 do
        self.enemies[i]:update(dt, self.world, self.player)
        
        if not self.enemies[i]:isAlive() then
            table.remove(self.enemies, i)
        end
    end
    
    -- Update ragdolls
    for i = #self.ragdolls, 1, -1 do
        self.ragdolls[i]:update(dt, self.world, self.particles)
        if self.ragdolls[i].decayTime <= 0 then
            table.remove(self.ragdolls, i)
        end
    end
    
    -- Handle grab input
    if self.input.grab and self.player.isCarnage and #self.enemies > 0 then
        local closest = self.enemies[1]
        local closestDist = math.huge
        
        for _, enemy in ipairs(self.enemies) do
            local dx = enemy.x - self.player.x
            local dy = enemy.y - self.player.y
            local dz = enemy.z - self.player.z
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            
            if dist < closestDist then
                closestDist = dist
                closest = enemy
            end
        end
        
        if closestDist < self.player.carnageRadius * 3 then
            local ragdoll = self.player:grab(closest, self.particles)
            if ragdoll then
                for i, enemy in ipairs(self.enemies) do
                    if enemy == closest then
                        table.remove(self.enemies, i)
                        table.insert(self.ragdolls, ragdoll)
                        break
                    end
                end
            end
        end
    end
    
    self.input.grab = false
end

function Game:destroyBlock()
    local forward = self.player:getForwardVector()
    local result = raycast(
        self.world,
        self.player.x,
        self.player.y,
        self.player.z,
        forward[1],
        forward[2],
        forward[3],
        6
    )
    
    if result.hit then
        self.particles:emitDebris(result.x, result.y, result.z, result.block, 20, 1.5)
        self.world:setBlock(result.x, result.y, result.z, BLOCK_TYPES.AIR)
    end
end

function Game:activateCarnage()
    self.player:transformToCarnage()
end

function Game:selectHotbar(slot)
    if slot >= 1 and slot <= #self.hotbar then
        self.hotbarIndex = slot
        self.selectedBlock = self.hotbar[slot]
    end
end

-- ======================== EXPORTS ========================
return {
    BLOCK_TYPES = BLOCK_TYPES,
    MATERIALS = MATERIALS,
    CHUNK_SIZE = CHUNK_SIZE,
    WORLD_HEIGHT = WORLD_HEIGHT,
    BLOCK_SIZE = BLOCK_SIZE,
    VoxelWorld = VoxelWorld,
    Player = Player,
    Game = Game,
    Ragdoll = Ragdoll,
    Enemy = Enemy,
    Bullet = Bullet,
    ParticleSystem = ParticleSystem,
    LightingEngine = LightingEngine,
    raycast = raycast,
    Perlin = Perlin,
}
