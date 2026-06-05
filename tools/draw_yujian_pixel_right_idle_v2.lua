local out_file = app.params["out_file"]
local sheet128_file = app.params["sheet128_file"]
local sheet512_file = app.params["sheet512_file"]
local preview_file = app.params["preview_file"]
local frame_count = tonumber(app.params["frame_count"] or "8")
local frame_seconds = tonumber(app.params["frame_seconds"] or "0.12")

if not out_file or out_file == "" then
  error("Missing out_file")
end

local W = 128
local H = 128

local transparent = Color{ r=0, g=0, b=0, a=0 }
local outline = Color{ r=5, g=7, b=9, a=255 }
local black = Color{ r=11, g=12, b=14, a=255 }
local ink = Color{ r=19, g=21, b=23, a=255 }
local dark = Color{ r=33, g=36, b=37, a=255 }
local mid = Color{ r=58, g=62, b=61, a=255 }
local grey = Color{ r=88, g=93, b=90, a=255 }
local light = Color{ r=142, g=148, b=138, a=245 }
local rim = Color{ r=191, g=202, b=188, a=235 }
local hair = Color{ r=6, g=7, b=9, a=255 }
local hair_mid = Color{ r=38, g=41, b=42, a=255 }
local hair_hi = Color{ r=92, g=96, b=94, a=235 }
local sash = Color{ r=108, g=94, b=130, a=245 }
local sash_hi = Color{ r=158, g=143, b=176, a=235 }
local sole = Color{ r=4, g=5, b=7, a=255 }

local function put(img, x, y, color)
  x = math.floor(x + 0.5)
  y = math.floor(y + 0.5)
  if x >= 0 and x < W and y >= 0 and y < H then
    img:drawPixel(x, y, color)
  end
end

local function line(img, x0, y0, x1, y1, color)
  x0 = math.floor(x0 + 0.5)
  y0 = math.floor(y0 + 0.5)
  x1 = math.floor(x1 + 0.5)
  y1 = math.floor(y1 + 0.5)
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

local function tapered_chain(img, points, widths, color)
  for i = 1, #points - 1 do
    local w = widths[i] or 1
    thick_line(img, points[i][1], points[i][2], points[i + 1][1], points[i + 1][2], w, color)
  end
end

local function add_dither(img, points)
  for _, p in ipairs(points) do
    put(img, p[1], p[2], p[3])
  end
end

local function draw_frame(index)
  local phase = math.pi * 2.0 * index / frame_count
  local breath = math.sin(phase)
  local lag = math.sin(phase - 0.8)
  local hair_lag = math.sin(phase - 1.25)
  local cloth_lag = math.sin(phase - 1.05)
  local lift = math.floor(breath * 1.0 + 0.5)
  local torso_y = 48 - lift
  local hip_y = 74
  local foot_y = 106
  local head_x = 76
  local img = Image(W, H, ColorMode.RGB)
  img:clear(transparent)

  local hair_shift = math.floor(hair_lag * 2.0 + 0.5)
  local cloth_shift = math.floor(cloth_lag * 2.0 + 0.5)
  local sleeve_shift = math.floor(lag * 1.0 + 0.5)

  -- Back hair mass: wide ink silhouette like the reference, moving behind the body.
  local hair_mass = {
    {70, torso_y - 19},
    {56 + hair_shift, torso_y - 17},
    {41 + hair_shift, torso_y - 12},
    {23 + hair_shift, torso_y - 6},
    {37 + hair_shift, torso_y - 2},
    {53 + hair_shift, torso_y + 1},
    {67, torso_y - 4},
  }
  polygon(img, hair_mass, hair)
  outline_polygon(img, hair_mass, outline)
  line(img, 65, torso_y - 16, 43 + hair_shift, torso_y - 10, hair_hi)
  line(img, 61, torso_y - 12, 35 + hair_shift, torso_y - 3, hair_mid)
  line(img, 55, torso_y - 6, 28 + hair_shift, torso_y + 4, hair_hi)

  tapered_chain(img, {{70, torso_y - 22}, {55 + hair_shift, torso_y - 25}, {39 + hair_shift, torso_y - 26}}, {1, 1}, hair)
  tapered_chain(img, {{68, torso_y - 17}, {52 + hair_shift, torso_y - 9}, {34 + hair_shift, torso_y - 1}, {20 + hair_shift, torso_y + 7}}, {1, 1, 1}, hair_hi)
  tapered_chain(img, {{67, torso_y - 10}, {50 + hair_shift, torso_y + 4}, {34 + hair_shift, torso_y + 16}, {24 + hair_shift, torso_y + 27}}, {2, 1, 1}, hair_mid)

  -- Back sleeve and long robe panels, kept above foot line.
  local back_sleeve = {
    {61, torso_y + 8},
    {48 + sleeve_shift, torso_y + 17},
    {37 + sleeve_shift, torso_y + 30},
    {49 + sleeve_shift, torso_y + 32},
    {64, torso_y + 18},
  }
  polygon(img, back_sleeve, dark)
  outline_polygon(img, back_sleeve, outline)
  line(img, 48 + sleeve_shift, torso_y + 19, 39 + sleeve_shift, torso_y + 29, light)
  line(img, 55 + sleeve_shift, torso_y + 18, 47 + sleeve_shift, torso_y + 30, mid)

  local back_panel = {
    {61, hip_y - 2},
    {45 + cloth_shift, hip_y + 8},
    {33 + cloth_shift, hip_y + 26},
    {43 + cloth_shift, hip_y + 37},
    {59, hip_y + 22},
  }
  polygon(img, back_panel, ink)
  outline_polygon(img, back_panel, outline)
  line(img, 48 + cloth_shift, hip_y + 10, 39 + cloth_shift, hip_y + 31, grey)
  line(img, 55, hip_y + 2, 52 + cloth_shift, hip_y + 23, light)

  -- Hair ribbons and cloth streamers. Short enough not to become the anchor.
  tapered_chain(img, {{62, torso_y - 14}, {47 + hair_shift, torso_y - 20}, {34 + hair_shift, torso_y - 20}}, {1, 1}, hair_hi)
  tapered_chain(img, {{59, hip_y + 2}, {47 + cloth_shift, hip_y + 12}, {36 + cloth_shift, hip_y + 23}, {31 + cloth_shift, hip_y + 32}}, {1, 1, 1}, sash)
  line(img, 43 + cloth_shift, hip_y + 15, 33 + cloth_shift, hip_y + 29, sash_hi)

  -- Locked lower body. These pixels define the anchor.
  thick_line(img, 63, hip_y + 8, 58, 89, 3, outline)
  thick_line(img, 63, hip_y + 8, 58, 89, 2, ink)
  thick_line(img, 58, 89, 55, foot_y - 4, 3, outline)
  thick_line(img, 58, 89, 55, foot_y - 4, 2, dark)
  thick_line(img, 75, hip_y + 7, 78, 91, 3, outline)
  thick_line(img, 75, hip_y + 7, 78, 91, 2, ink)
  thick_line(img, 78, 91, 84, foot_y - 4, 3, outline)
  thick_line(img, 78, 91, 84, foot_y - 4, 2, dark)
  rect(img, 50, foot_y - 2, 62, foot_y + 1, sole)
  rect(img, 78, foot_y - 2, 92, foot_y + 1, sole)
  put(img, 93, foot_y, sole)
  put(img, 49, foot_y, sole)

  -- Main robe body with black wash and gray planes.
  local robe = {
    {61, torso_y - 7},
    {79, torso_y - 6},
    {88, hip_y + 7},
    {84, hip_y + 30},
    {73, hip_y + 36},
    {60, hip_y + 31},
    {55, hip_y + 8},
  }
  polygon(img, robe, ink)
  outline_polygon(img, robe, outline)
  polygon(img, {{64, torso_y - 3}, {72, torso_y - 2}, {70, hip_y + 24}, {61, hip_y + 20}}, dark)
  polygon(img, {{73, torso_y - 4}, {82, hip_y + 4}, {80, hip_y + 25}, {74, hip_y + 29}}, mid)
  line(img, 67, torso_y - 3, 59, hip_y + 22, light)
  line(img, 77, torso_y - 2, 84, hip_y + 17, rim)
  line(img, 72, torso_y + 6, 64, hip_y + 2, grey)
  rect(img, 59, hip_y - 3, 82, hip_y + 1, outline)
  rect(img, 61, hip_y - 2, 80, hip_y, sash)
  line(img, 62, hip_y - 2, 79, hip_y - 2, sash_hi)

  -- Front arm and sleeve, a small control hand facing right/down.
  thick_line(img, 80, torso_y + 9, 91, torso_y + 22 + math.floor(breath), 3, outline)
  thick_line(img, 80, torso_y + 9, 91, torso_y + 22 + math.floor(breath), 2, mid)
  polygon(img, {
    {84, torso_y + 14},
    {93, torso_y + 22 + math.floor(breath)},
    {95, torso_y + 30 + math.floor(breath)},
    {88, torso_y + 30 + math.floor(breath)},
    {82, torso_y + 18},
  }, dark)
  outline_polygon(img, {
    {84, torso_y + 14},
    {93, torso_y + 22 + math.floor(breath)},
    {95, torso_y + 30 + math.floor(breath)},
    {88, torso_y + 30 + math.floor(breath)},
    {82, torso_y + 18},
  }, outline)
  ellipse(img, 94, torso_y + 32 + math.floor(breath), 3, 4, outline)
  put(img, 95, torso_y + 33 + math.floor(breath), rim)
  put(img, 96, torso_y + 34 + math.floor(breath), rim)

  -- Neck, side face silhouette, and top bun.
  rect(img, 70, torso_y - 14, 74, torso_y - 6, outline)
  rect(img, 71, torso_y - 14, 73, torso_y - 7, dark)
  ellipse(img, head_x, torso_y - 23, 8, 10, outline)
  ellipse(img, head_x + 1, torso_y - 23, 6, 9, dark)
  rect(img, head_x - 8, torso_y - 35, head_x + 4, torso_y - 28, hair)
  ellipse(img, head_x - 5, torso_y - 38, 6, 4, outline)
  ellipse(img, head_x - 5, torso_y - 38, 4, 3, hair)
  line(img, head_x + 5, torso_y - 28, head_x + 8, torso_y - 20, rim)
  line(img, head_x - 2, torso_y - 31, head_x - 8, torso_y - 24, hair_hi)

  -- Sparse rim pixels for ink-wash readability.
  add_dither(img, {
    {66, torso_y + 9, light}, {68, torso_y + 15, grey}, {70, torso_y + 24, grey},
    {80, hip_y + 8, light}, {76, hip_y + 18, grey}, {69, hip_y + 27, light},
    {57, 91, grey}, {83, 92, grey}, {62, hip_y + 4, rim},
    {52 + cloth_shift, hip_y + 14, light}, {44 + cloth_shift, hip_y + 25, grey},
    {43 + hair_shift, torso_y - 7, hair_hi}, {31 + hair_shift, torso_y + 2, hair_hi},
  })

  return img
end

local sprite = Sprite(W, H, ColorMode.RGB)
sprite.filename = out_file
local layer = sprite.layers[1]
layer.name = "01_right_hover_idle_pixel_v2"
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
tag.name = "01_right_hover_idle_pixel_v2"
tag.aniDir = AniDir.FORWARD
sprite.gridBounds = Rectangle(0, 0, W, H)
sprite:saveAs(out_file)

if sheet128_file and sheet128_file ~= "" then
  app.command.ExportSpriteSheet{
    ui=false,
    type=SpriteSheetType.HORIZONTAL,
    textureFilename=sheet128_file,
    dataFilename="",
    borderPadding=0,
    shapePadding=0,
    innerPadding=0,
  }
end

if sheet512_file and sheet512_file ~= "" then
  app.command.SpriteSize{ ui=false, scale=4 }
  app.command.ExportSpriteSheet{
    ui=false,
    type=SpriteSheetType.HORIZONTAL,
    textureFilename=sheet512_file,
    dataFilename="",
    borderPadding=0,
    shapePadding=0,
    innerPadding=0,
  }
  if preview_file and preview_file ~= "" then
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
end

print("created=" .. out_file)
