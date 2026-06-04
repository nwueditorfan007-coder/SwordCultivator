local out_file = app.params["out_file"]
local sheet_file = app.params["sheet_file"]
local preview_file = app.params["preview_file"]
local frame_count = tonumber(app.params["frame_count"] or "8")
local frame_seconds = tonumber(app.params["frame_seconds"] or "0.12")

if not out_file or out_file == "" then
  error("Missing out_file")
end

local W = 96
local H = 96

local transparent = Color{ r=0, g=0, b=0, a=0 }
local outline = Color{ r=8, g=10, b=12, a=255 }
local ink = Color{ r=20, g=23, b=25, a=255 }
local dark = Color{ r=31, g=34, b=36, a=255 }
local mid = Color{ r=62, g=66, b=64, a=255 }
local light = Color{ r=128, g=132, b=124, a=255 }
local rim = Color{ r=178, g=188, b=178, a=230 }
local hair = Color{ r=10, g=11, b=13, a=255 }
local hair_hi = Color{ r=74, g=76, b=74, a=230 }
local sash = Color{ r=110, g=96, b=126, a=245 }
local sole = Color{ r=6, g=7, b=9, a=255 }

local function put(img, x, y, color)
  if x >= 0 and x < W and y >= 0 and y < H then
    img:drawPixel(x, y, color)
  end
end

local function line(img, x0, y0, x1, y1, color)
  local dx = math.abs(x1 - x0)
  local sx = x0 < x1 and 1 or -1
  local dy = -math.abs(y1 - y0)
  local sy = y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    put(img, x0, y0, color)
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then
      err = err + dy
      x0 = x0 + sx
    end
    if e2 <= dx then
      err = err + dx
      y0 = y0 + sy
    end
  end
end

local function thick_line(img, x0, y0, x1, y1, radius, color)
  for ox = -radius, radius do
    for oy = -radius, radius do
      if ox * ox + oy * oy <= radius * radius then
        line(img, x0 + ox, y0 + oy, x1 + ox, y1 + oy, color)
      end
    end
  end
end

local function rect(img, x0, y0, x1, y1, color)
  for y = y0, y1 do
    for x = x0, x1 do
      put(img, x, y, color)
    end
  end
end

local function ellipse(img, cx, cy, rx, ry, color)
  for y = cy - ry, cy + ry do
    for x = cx - rx, cx + rx do
      local dx = (x - cx) / rx
      local dy = (y - cy) / ry
      if dx * dx + dy * dy <= 1.0 then
        put(img, x, y, color)
      end
    end
  end
end

local function polygon(img, points, color)
  local min_y = 999
  local max_y = -999
  for _, p in ipairs(points) do
    min_y = math.min(min_y, p[2])
    max_y = math.max(max_y, p[2])
  end
  for y = min_y, max_y do
    local nodes = {}
    local j = #points
    for i = 1, #points do
      local pi = points[i]
      local pj = points[j]
      if (pi[2] < y and pj[2] >= y) or (pj[2] < y and pi[2] >= y) then
        table.insert(nodes, math.floor(pi[1] + (y - pi[2]) / (pj[2] - pi[2]) * (pj[1] - pi[1]) + 0.5))
      end
      j = i
    end
    table.sort(nodes)
    for i = 1, #nodes, 2 do
      if nodes[i + 1] then
        for x = nodes[i], nodes[i + 1] do
          put(img, x, y, color)
        end
      end
    end
  end
end

local function outline_polygon(img, points, color)
  for i = 1, #points do
    local a = points[i]
    local b = points[(i % #points) + 1]
    line(img, a[1], a[2], b[1], b[2], color)
  end
end

local function draw_trail(img, points, color)
  for i = 1, #points - 1 do
    thick_line(img, points[i][1], points[i][2], points[i + 1][1], points[i + 1][2], 1, color)
  end
end

local function draw_frame(index)
  local phase = math.pi * 2.0 * index / frame_count
  local breath = math.sin(phase)
  local lag = math.sin(phase - 0.9)
  local hair_lag = math.sin(phase - 1.4)
  local lift = math.floor(breath * 1.2 + 0.5)
  local torso_y = 37 - lift
  local hip_y = 55 - math.floor(lift * 0.35)
  local foot_y = 76
  local cx = 50
  local img = Image(W, H, ColorMode.RGB)
  img:clear(transparent)

  -- Back hair, ribbons, and robe tails. These move more than the anchored body.
  local hair_shift = math.floor(hair_lag * 2.0 + 0.5)
  draw_trail(img, {{48, 24 - lift}, {37 + hair_shift, 25}, {27 + hair_shift, 29}, {17 + hair_shift, 31}}, hair_hi)
  draw_trail(img, {{48, 27 - lift}, {36 + hair_shift, 31}, {24 + hair_shift, 37}, {15 + hair_shift, 45}}, hair)
  draw_trail(img, {{48, 30 - lift}, {38 + hair_shift, 36}, {27 + hair_shift, 43}, {19 + hair_shift, 55}}, hair_hi)
  draw_trail(img, {{47, 22 - lift}, {38 + hair_shift, 20}, {29 + hair_shift, 19}}, hair)

  local cloth_shift = math.floor(lag * 2.0 + 0.5)
  local back_tail = {
    {45, hip_y - 2},
    {33 + cloth_shift, hip_y + 6},
    {27 + cloth_shift, hip_y + 14},
    {35 + cloth_shift, hip_y + 18},
    {45, hip_y + 17},
  }
  polygon(img, back_tail, dark)
  outline_polygon(img, back_tail, outline)
  line(img, 36 + cloth_shift, hip_y + 9, 32 + cloth_shift, hip_y + 17, light)

  local low_ribbon = {{45, hip_y + 2}, {38 + cloth_shift, hip_y + 8}, {31 + cloth_shift, hip_y + 12}, {27 + cloth_shift, hip_y + 15}}
  draw_trail(img, low_ribbon, sash)

  -- Legs are intentionally locked to keep the hover anchor stable.
  thick_line(img, 47, hip_y + 7, 45, 64, 2, outline)
  thick_line(img, 47, hip_y + 7, 45, 64, 1, ink)
  thick_line(img, 45, 64, 44, foot_y - 2, 2, outline)
  thick_line(img, 45, 64, 44, foot_y - 2, 1, dark)
  thick_line(img, 54, hip_y + 6, 56, 65, 2, outline)
  thick_line(img, 54, hip_y + 6, 56, 65, 1, ink)
  thick_line(img, 56, 65, 59, foot_y - 2, 2, outline)
  thick_line(img, 56, 65, 59, foot_y - 2, 1, dark)
  rect(img, 41, foot_y - 1, 48, foot_y + 1, sole)
  rect(img, 55, foot_y - 1, 64, foot_y + 1, sole)
  put(img, 65, foot_y, sole)

  -- Robe body.
  local robe = {
    {45, torso_y - 5},
    {57, torso_y - 4},
    {62, hip_y + 7},
    {58, hip_y + 18},
    {49, hip_y + 20},
    {41, hip_y + 16},
    {42, hip_y + 2},
  }
  polygon(img, robe, ink)
  outline_polygon(img, robe, outline)
  line(img, 50, torso_y - 3, 45, hip_y + 16, mid)
  line(img, 56, torso_y - 2, 59, hip_y + 15, light)
  rect(img, 44, hip_y - 2, 58, hip_y + 1, outline)
  rect(img, 45, hip_y - 1, 57, hip_y, sash)

  -- Sleeves and hands. The far sleeve is a balancing control cue.
  local sleeve_sway = math.floor(lag * 1.0 + 0.5)
  local back_sleeve = {
    {44, torso_y + 5},
    {36 + sleeve_sway, torso_y + 10},
    {32 + sleeve_sway, torso_y + 18},
    {42 + sleeve_sway, torso_y + 18},
    {48, torso_y + 9},
  }
  polygon(img, back_sleeve, dark)
  outline_polygon(img, back_sleeve, outline)
  line(img, 36 + sleeve_sway, torso_y + 12, 43 + sleeve_sway, torso_y + 16, light)

  thick_line(img, 57, torso_y + 6, 64, torso_y + 14 + math.floor(breath), 2, outline)
  thick_line(img, 57, torso_y + 6, 64, torso_y + 14 + math.floor(breath), 1, mid)
  ellipse(img, 65, torso_y + 16 + math.floor(breath), 2, 3, outline)
  put(img, 66, torso_y + 17 + math.floor(breath), rim)

  -- Head and hair cap.
  ellipse(img, 55, torso_y - 13, 5, 7, outline)
  ellipse(img, 56, torso_y - 13, 4, 6, dark)
  rect(img, 50, torso_y - 21, 57, torso_y - 16, hair)
  ellipse(img, 52, torso_y - 23, 4, 3, outline)
  ellipse(img, 52, torso_y - 23, 3, 2, hair)
  line(img, 58, torso_y - 17, 60, torso_y - 12, rim)

  -- Front robe highlights and pixel cleanup.
  line(img, 57, torso_y + 3, 60, hip_y + 9, rim)
  line(img, 46, torso_y + 2, 51, torso_y + 10, light)
  put(img, 51, torso_y + 15, rim)
  put(img, 55, hip_y + 7, light)

  return img
end

local sprite = Sprite(W, H, ColorMode.RGB)
sprite.filename = out_file
local layer = sprite.layers[1]
layer.name = "01_right_hover_idle_pixel"
sprite:deleteCel(layer, 1)

for i = 0, frame_count - 1 do
  local frame = sprite.frames[1]
  if i > 0 then
    frame = sprite:newEmptyFrame(i + 1)
  end
  frame.duration = frame_seconds
  sprite:newCel(layer, frame, draw_frame(i), Point(0, 0))
end

local tag = sprite:newTag(1, frame_count)
tag.name = "01_right_hover_idle_pixel"
tag.aniDir = AniDir.FORWARD
sprite.gridBounds = Rectangle(0, 0, W, H)
sprite:saveAs(out_file)

if sheet_file and sheet_file ~= "" then
  app.command.ExportSpriteSheet{
    ui=false,
    type=SpriteSheetType.HORIZONTAL,
    textureFilename=sheet_file,
    dataFilename="",
    borderPadding=0,
    shapePadding=0,
    innerPadding=0,
  }
end

if preview_file and preview_file ~= "" then
  app.command.SpriteSize{ ui=false, scale=5 }
  app.command.ExportSpriteSheet{
    ui=false,
    type=SpriteSheetType.ROWS,
    columns=4,
    textureFilename=preview_file,
    dataFilename="",
    borderPadding=0,
    shapePadding=0,
    innerPadding=0,
  }
end

print("created=" .. out_file)
