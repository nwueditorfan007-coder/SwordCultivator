local frames_dir = app.params["frames_dir"]
local out_file = app.params["out_file"]
local frame_count = tonumber(app.params["frame_count"] or "8")
local frame_seconds = tonumber(app.params["frame_seconds"] or "0.12")
local frame_pattern = app.params["frame_pattern"] or "01_right_hover_idle_%02d.png"
local tag_name = app.params["tag_name"] or "01_right_hover_idle"

if not frames_dir or frames_dir == "" then
  error("Missing frames_dir")
end
if not out_file or out_file == "" then
  error("Missing out_file")
end

local function frame_path(index)
  return frames_dir .. "/" .. string.format(frame_pattern, index)
end

local sprite = Sprite(512, 512, ColorMode.RGB)
sprite.filename = out_file

local layer = sprite.layers[1]
layer.name = tag_name
sprite:deleteCel(layer, 1)

for i = 0, frame_count - 1 do
  local frame = sprite.frames[1]
  if i > 0 then
    frame = sprite:newEmptyFrame(i + 1)
  end
  frame.duration = frame_seconds
  local image = Image{ fromFile=frame_path(i) }
  sprite:newCel(layer, frame, image, Point(0, 0))
end

local tag = sprite:newTag(1, frame_count)
tag.name = tag_name
tag.aniDir = AniDir.FORWARD

sprite.gridBounds = Rectangle(0, 0, 512, 512)
sprite:saveAs(out_file)
print("created=" .. out_file)
