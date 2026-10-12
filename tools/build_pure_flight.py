import bpy, os, math
from mathutils import Matrix, Vector, Euler, Quaternion

import io_scene_fbx.import_fbx as ifbx
orig_link_hierarchy = ifbx.FbxImportHelperNode.link_hierarchy
def patched_link_hierarchy(self, fbx_tmpl, settings, scene):
    if self.meshes:
        for mesh in self.meshes:
            if self not in mesh.armature_setup:
                mesh.armature_setup[self] = (Matrix(), getattr(self, 'bind_matrix', None))
    return orig_link_hierarchy(self, fbx_tmpl, settings, scene)
ifbx.FbxImportHelperNode.link_hierarchy = patched_link_hierarchy

for obj in list(bpy.data.objects): bpy.data.objects.remove(obj, do_unlink=True)
for mat in list(bpy.data.materials): bpy.data.materials.remove(mat, do_unlink=True)
for act in list(bpy.data.actions): bpy.data.actions.remove(act, do_unlink=True)

fbx_model = r"E:\JyGameRemake\Assets\Art\Character\000_男主角\000_Nanzhujue.FBX"
tex_dir = r"E:\JyGameRemake\Assets\Art\Character\000_男主角\Textures"
anim_skill1_path = r"E:\JyGameRemake\Assets\BuildSource\animations_3d\Humanoid\000_男主角\Battle\000_Nanzhujue_Anim_Skill1.fbx"
blend_file = r"E:\SwordCultivator\resources\nanzhujue_8way_flight_poses.blend"
output_dir = r"E:\SwordCultivator\assets\characters\nanzhujue"

tex_mapping = {
    "Clothes_01": os.path.join(tex_dir, "000_Nanzhujue_Tex_Clothes_01_D.tga"),
    "Clothes_02": os.path.join(tex_dir, "000_Nanzhujue_Tex_Clothes_02_D.tga"),
    "Face": os.path.join(tex_dir, "000_Nanzhujue_Tex_Face_D.tga"),
    "Hair": os.path.join(tex_dir, "000_Nanzhujue_Tex_Hair_D.tga"),
    "Weapon": os.path.join(tex_dir, "000_Nanzhujue_Tex_Weapon_D.tga"),
}

for key, path in tex_mapping.items():
    mat = bpy.data.materials.new(name=f"Mat_Nanzhujue_{key}")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    out = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.inputs['Roughness'].default_value = 0.5
    mat.node_tree.links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
    if os.path.exists(path):
        img = bpy.data.images.load(path)
        tex_node = nodes.new(type='ShaderNodeTexImage')
        tex_node.image = img
        mat.node_tree.links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])

# 1. 导入模型
bpy.ops.import_scene.fbx(filepath=fbx_model)
armature = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
armature.name = "Armature_Nanzhujue"

for m in meshes:
    for slot in m.material_slots:
        for key in tex_mapping.keys():
            if key.lower() in slot.name.lower() or key.lower() in m.name.lower():
                slot.material = bpy.data.materials[f"Mat_Nanzhujue_{key}"]
                break

weapon_a = [o for o in meshes if "WeaponA" in o.name]
if weapon_a:
    w_obj = weapon_a[0]
    w_obj.name = "FlyingSword_Platform"
    w_obj.parent = None
    w_obj.location = Vector((0.0, -0.015, -0.05))
    w_obj.rotation_euler = (math.radians(90), 0, math.radians(90))
    w_obj.scale = Vector((0.012, 0.012, 0.012))

weapon_b = [o for o in meshes if "WeaponB" in o.name]
if weapon_b:
    weapon_b[0].hide_render = True
    weapon_b[0].hide_viewport = True

# 2. 导入御风动画并过滤掉所有致畸的 Location 通道
bpy.ops.import_scene.fbx(filepath=anim_skill1_path)
anim_arm = [o for o in bpy.data.objects if o.type == 'ARMATURE' and o != armature][0]
action = anim_arm.animation_data.action

# 过滤 Action 中的 F-Curves：清除除了 Bip001 / Root 以外所有骨骼的 location 通道！
if hasattr(action, 'fcurves'):
    for fc in list(action.fcurves):
        # 只要是子骨骼的 location 通道，全部删除，只保留 rotation_quaternion！
        if "location" in fc.data_path and "Bip001\"" not in fc.data_path and "Root" not in fc.data_path:
            action.fcurves.remove(fc)

armature.animation_data_create()
armature.animation_data.action = action
if hasattr(action, 'slots') and len(action.slots) > 0:
    armature.animation_data.action_slot = action.slots[0]
bpy.data.objects.remove(anim_arm, do_unlink=True)

# 选取御风引剑最帅气的关键帧 (Frame 12)
bpy.context.scene.frame_set(12)

# 重置所有骨骼的非必要位移
bpy.context.view_layer.objects.active = armature
bpy.ops.object.mode_set(mode='POSE')
for b in armature.pose.bones:
    if b.name != "Bip001" and b.name != "Root":
        b.location = Vector((0, 0, 0))
bpy.ops.object.mode_set(mode='OBJECT')

active_meshes = [m for m in meshes if not m.hide_render] + [w_obj]
min_v = Vector((float('inf'), float('inf'), float('inf')))
max_v = Vector((float('-inf'), float('-inf'), float('-inf')))
for m in active_meshes:
    for corner in m.bound_box:
        world_pt = m.matrix_world @ Vector(corner)
        min_v.x = min(min_v.x, world_pt.x); max_v.x = max(max_v.x, world_pt.x)
        min_v.y = min(min_v.y, world_pt.y); max_v.y = max(max_v.y, world_pt.y)
        min_v.z = min(min_v.z, world_pt.z); max_v.z = max(max_v.z, world_pt.z)
center = (min_v + max_v) * 0.5
size = max_v - min_v

# 侧向 2.5D 相机
cam_data = bpy.data.cameras.new(name="Cam_CleanFlight")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = max(size.x, size.y) * 1.25
cam_obj = bpy.data.objects.new(name="Cam_CleanFlight", object_data=cam_data)
bpy.context.collection.objects.link(cam_obj)

cam_dist = 3.6
pitch_rad = math.radians(20)
yaw_rad = math.radians(90)
x = center.x + cam_dist * math.cos(pitch_rad) * math.sin(yaw_rad)
z = center.z - cam_dist * math.cos(pitch_rad) * math.cos(yaw_rad)
y = center.y - cam_dist * math.sin(pitch_rad)
cam_pos = Vector((x, y, z))

forward = (center - cam_pos).normalized()
head_up_vector = Vector((0, -1, 0))
right = forward.cross(head_up_vector).normalized()
actual_up = right.cross(forward).normalized()
mat = Matrix((
    (right.x, actual_up.x, -forward.x, cam_pos.x),
    (right.y, actual_up.y, -forward.y, cam_pos.y),
    (right.z, actual_up.z, -forward.z, cam_pos.z),
    (0, 0, 0, 1)
))
cam_obj.matrix_world = mat
bpy.context.scene.camera = cam_obj

# 💡 完美顺光光照（从相机正前上方照向角色脸部与前身）
l1 = bpy.data.lights.new(name="KeyLight_Front", type='SUN')
l1.energy = 3.6
o1 = bpy.data.objects.new(name="KeyLight_Front", object_data=l1)
light_pos = cam_pos + Vector((0, -1.5, 2.0))
light_dir = (center - light_pos).normalized()
o1.rotation_euler = light_dir.to_track_quat('-Z', 'Y').to_euler()
bpy.context.collection.objects.link(o1)

l2 = bpy.data.lights.new(name="FillLight", type='SUN')
l2.energy = 1.2
l2.color = (0.8, 0.9, 1.0)
o2 = bpy.data.objects.new(name="FillLight", object_data=l2)
o2.rotation_euler = (math.radians(30), math.radians(60), math.radians(-45))
bpy.context.collection.objects.link(o2)

for o in bpy.data.objects:
    if o.type == 'ARMATURE':
        o.show_in_front = False

bpy.context.scene.render.film_transparent = True
bpy.context.scene.render.resolution_x = 720
bpy.context.scene.render.resolution_y = 720
render_out = os.path.join(output_dir, "nanzhujue_pure_flight_pose.png")
bpy.context.scene.render.filepath = render_out
bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath=blend_file)
print("=== PURE FLIGHT POSE RENDERED ===")
