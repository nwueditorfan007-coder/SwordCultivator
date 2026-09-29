import bpy, os, math
from mathutils import Matrix, Vector

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

fbx_model = r"E:\SwordCultivator\resources\modle\000_男主角\000_Nanzhujue_LOD.FBX"
tex_dir = r"E:\SwordCultivator\resources\modle\000_男主角\Textures"
fbx_weapon = r"E:\JyGameRemake\Assets\BuildSource\animations_3d\Humanoid\000_男主角\Battle\000_Nanzhujue_WeaponA_000.FBX"
anim_idle_path = r"E:\JyGameRemake\Assets\BuildSource\animations_3d\Humanoid\000_男主角\Battle\000_Nanzhujue_Anim_Idle.fbx"
blend_save_path = r"E:\SwordCultivator\resources\nanzhujue_8way_flight_poses.blend"
output_dir = r"E:\SwordCultivator\assets\characters\nanzhujue"
os.makedirs(output_dir, exist_ok=True)

# 1. 材质
tex_mapping = {
    "Clothes_01": os.path.join(tex_dir, "000_Nanzhujue_Tex_Clothes_01_D.tga"),
    "Clothes_02": os.path.join(tex_dir, "000_Nanzhujue_Tex_Clothes_02_D.tga"),
    "Face": os.path.join(tex_dir, "000_Nanzhujue_Tex_Face_D.tga"),
    "Hair": os.path.join(tex_dir, "000_Nanzhujue_Tex_Hair_D.tga"),
}

for key, path in tex_mapping.items():
    mat = bpy.data.materials.new(name=f"Mat_{key}")
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

# 2. 导入模型
bpy.ops.import_scene.fbx(filepath=fbx_model)
armature = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
armature.name = "Armature_Nanzhujue"

for m in meshes:
    for slot in m.material_slots:
        for key in tex_mapping.keys():
            if key.lower() in slot.name.lower():
                slot.material = bpy.data.materials[f"Mat_{key}"]
                break

# 3. 导入动作
bpy.ops.import_scene.fbx(filepath=anim_idle_path)
anim_arm = [o for o in bpy.data.objects if o.type == 'ARMATURE' and o != armature][0]
action = anim_arm.animation_data.action

armature.animation_data_create()
armature.animation_data.action = action
if hasattr(action, 'slots') and len(action.slots) > 0:
    armature.animation_data.action_slot = action.slots[0]
bpy.data.objects.remove(anim_arm, do_unlink=True)

# 4. 导入武器
if os.path.exists(fbx_weapon):
    bpy.ops.import_scene.fbx(filepath=fbx_weapon)
    w_objs = [o for o in bpy.data.objects if "Weapon" in o.name and o.type == 'MESH']
    if w_objs:
        w_obj = w_objs[0]
        weapon_tex = os.path.join(tex_dir, "000_Nanzhujue_Tex_Weapon_D.tga")
        if os.path.exists(weapon_tex):
            w_mat = bpy.data.materials.new(name="Mat_Weapon")
            w_mat.use_nodes = True
            nodes = w_mat.node_tree.nodes
            nodes.clear()
            out = nodes.new(type='ShaderNodeOutputMaterial')
            bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
            w_mat.node_tree.links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
            img = bpy.data.images.load(weapon_tex)
            tex_node = nodes.new(type='ShaderNodeTexImage')
            tex_node.image = img
            w_mat.node_tree.links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
            w_obj.data.materials.clear()
            w_obj.data.materials.append(w_mat)

        target_bone = "Weapon_R_Mount" if "Weapon_R_Mount" in armature.data.bones else "Bip001 R Hand"
        w_obj.parent = armature
        w_obj.parent_type = 'BONE'
        w_obj.parent_bone = target_bone
        w_obj.location = (0, 0, 0)
        w_obj.rotation_euler = (0, 0, 0)

bpy.context.scene.frame_set(10)

# 计算包围盒
min_v = Vector((float('inf'), float('inf'), float('inf')))
max_v = Vector((float('-inf'), float('-inf'), float('-inf')))
for m in meshes:
    for corner in m.bound_box:
        world_pt = m.matrix_world @ Vector(corner)
        min_v.x = min(min_v.x, world_pt.x); max_v.x = max(max_v.x, world_pt.x)
        min_v.y = min(min_v.y, world_pt.y); max_v.y = max(max_v.y, world_pt.y)
        min_v.z = min(min_v.z, world_pt.z); max_v.z = max(max_v.z, world_pt.z)

center = (min_v + max_v) * 0.5
size = max_v - min_v

# 8个方向相机（严格采用纯正 LookAt 矩阵构建）
cam_dist = 4.0
directions = [
    {"id": "01_right",      "yaw": 90,   "pitch": 25},
    {"id": "02_up_right",   "yaw": 45,   "pitch": 45},
    {"id": "03_up",         "yaw": 0,    "pitch": 50},
    {"id": "04_up_left",    "yaw": 315,  "pitch": 45},
    {"id": "05_left",       "yaw": 270,  "pitch": 25},
    {"id": "06_down_left",  "yaw": 225,  "pitch": 45},
    {"id": "07_down",       "yaw": 180,  "pitch": 45},
    {"id": "08_down_right", "yaw": 135,  "pitch": 45},
]

cam_coll = bpy.data.collections.new("Cameras_8Way")
bpy.context.scene.collection.children.link(cam_coll)

cam_objs = []
head_up_vector = Vector((0, -1, 0))

for d in directions:
    cam_data = bpy.data.cameras.new(name=f"CameraData_{d['id']}")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = max(size.x, size.y) * 1.25
    
    cam_obj = bpy.data.objects.new(name=f"Cam_{d['id']}", object_data=cam_data)
    cam_coll.objects.link(cam_obj)
    
    yaw_rad = math.radians(d['yaw'])
    pitch_rad = math.radians(d['pitch'])
    
    x = center.x + cam_dist * math.cos(pitch_rad) * math.sin(yaw_rad)
    z = center.z - cam_dist * math.cos(pitch_rad) * math.cos(yaw_rad)
    y = center.y - cam_dist * math.sin(pitch_rad)
    cam_pos = Vector((x, y, z))
    
    forward = (center - cam_pos).normalized()
    right = forward.cross(head_up_vector).normalized()
    actual_up = right.cross(forward).normalized()
    
    mat = Matrix((
        (right.x, actual_up.x, -forward.x, cam_pos.x),
        (right.y, actual_up.y, -forward.y, cam_pos.y),
        (right.z, actual_up.z, -forward.z, cam_pos.z),
        (0, 0, 0, 1)
    ))
    cam_obj.matrix_world = mat
    cam_objs.append(cam_obj)

bpy.context.scene.camera = cam_objs[0]

# 光照
l1 = bpy.data.lights.new(name="KeyLight", type='SUN')
l1.energy = 3.2
o1 = bpy.data.objects.new(name="KeyLight", object_data=l1)
o1.rotation_euler = (math.radians(45), math.radians(20), math.radians(45))
bpy.context.collection.objects.link(o1)

l2 = bpy.data.lights.new(name="FillLight", type='SUN')
l2.energy = 1.6
l2.color = (0.75, 0.88, 1.0)
o2 = bpy.data.objects.new(name="FillLight", object_data=l2)
o2.rotation_euler = (math.radians(-30), math.radians(-30), math.radians(-135))
bpy.context.collection.objects.link(o2)

for o in bpy.data.objects:
    if o.type == 'ARMATURE':
        o.show_in_front = False

# 渲染 8 个方向
bpy.context.scene.render.film_transparent = True
bpy.context.scene.render.resolution_x = 512
bpy.context.scene.render.resolution_y = 512

for i, d in enumerate(directions):
    cam = cam_objs[i]
    bpy.context.scene.camera = cam
    render_filepath = os.path.join(output_dir, f"nanzhujue_8way_{d['id']}.png")
    bpy.context.scene.render.filepath = render_filepath
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {render_filepath}")

bpy.ops.wm.save_as_mainfile(filepath=blend_save_path)
print("=== NAN ZHU JUE 8-WAY COMPLETE ===")
