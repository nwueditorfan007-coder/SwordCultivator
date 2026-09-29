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

fbx_model = r"E:\JyGameRemake\Assets\Art\Character\000_男主角\000_Nanzhujue.FBX"
tex_dir = r"E:\JyGameRemake\Assets\Art\Character\000_男主角\Textures"
output_dir = r"E:\SwordCultivator\assets\characters\nanzhujue"
blend_rigged_path = r"E:\SwordCultivator\resources\nanzhujue_rigged_character.blend"

# 1. 材质
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

# 2. 导入模型
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
    w_obj.location = Vector((0.0, 0.05, -0.05))
    w_obj.rotation_euler = (math.radians(90), 0, math.radians(90))
    w_obj.scale = Vector((0.012, 0.012, 0.012))

weapon_b = [o for o in meshes if "WeaponB" in o.name]
if weapon_b:
    weapon_b[0].hide_render = True
    weapon_b[0].hide_viewport = True

# 3. 关节焊接与禁止拉伸（Connected + Lock Location）
bpy.context.view_layer.objects.active = armature
bpy.ops.object.mode_set(mode='EDIT')
eb = armature.data.edit_bones

# 焊接肘关节与膝关节
chains = [
    ("Bip001 R UpperArm", "Bip001 R Forearm", "Bip001 R Hand"),
    ("Bip001 L UpperArm", "Bip001 L Forearm", "Bip001 L Hand"),
    ("Bip001 R Thigh", "Bip001 R Calf", "Bip001 R Foot"),
    ("Bip001 L Thigh", "Bip001 L Calf", "Bip001 L Foot"),
]

for p_name, m_name, c_name in chains:
    if p_name in eb and m_name in eb and c_name in eb:
        eb[m_name].head = eb[p_name].tail
        eb[m_name].use_connect = True
        eb[c_name].head = eb[m_name].tail
        eb[c_name].use_connect = True

# 创建 IK 控制骨骼
def create_ik_bone(name, parent_name):
    ik_b = eb.new(name)
    parent_b = eb[parent_name]
    ik_b.head = Vector(parent_b.tail)
    ik_b.tail = ik_b.head + Vector((0, 0, 0.12))
    ik_b.use_deform = False
    return ik_b

ik_hand_r = create_ik_bone("IK_Hand_R", "Bip001 R Hand")
ik_hand_l = create_ik_bone("IK_Hand_L", "Bip001 L Hand")
ik_foot_r = create_ik_bone("IK_Foot_R", "Bip001 R Foot")
ik_foot_l = create_ik_bone("IK_Foot_L", "Bip001 L Foot")

bpy.ops.object.mode_set(mode='POSE')
pb = armature.pose.bones

# 锁死所有骨骼的 Location 和 Scale（彻底杜绝橡皮筋拉伸！）
for b in pb:
    if not b.name.startswith("IK_"):
        b.lock_location = (True, True, True)
        b.lock_scale = (True, True, True)

# 添加 IK 约束
def add_ik(bone_name, target_name):
    if bone_name in pb:
        c = pb[bone_name].constraints.new(type='IK')
        c.target = armature
        c.subtarget = target_name
        c.chain_count = 2
        c.use_stretch = False
        return c

add_ik("Bip001 R Forearm", "IK_Hand_R")
add_ik("Bip001 L Forearm", "IK_Hand_L")
add_ik("Bip001 R Calf", "IK_Foot_R")
add_ik("Bip001 L Calf", "IK_Foot_L")

# 4. 移动 IK 控制手柄到自然的御剑位置
# 右手在身前掐诀（屈肘向前）
if "IK_Hand_R" in pb:
    pb["IK_Hand_R"].location = Vector((0.08, -0.15, 0.18))

# 左手在身侧后方负手
if "IK_Hand_L" in pb:
    pb["IK_Hand_L"].location = Vector((-0.10, 0.10, -0.08))

# 右脚踏在飞剑前端
if "IK_Foot_R" in pb:
    pb["IK_Foot_R"].location = Vector((0.04, -0.02, 0.12))

# 左脚踏在飞剑后端
if "IK_Foot_L" in pb:
    pb["IK_Foot_L"].location = Vector((-0.04, 0.02, -0.15))

# 脊柱微侧微前倾 12°
if "Bip001 Spine" in pb:
    pb["Bip001 Spine"].rotation_mode = 'XYZ'
    pb["Bip001 Spine"].rotation_euler = Euler((math.radians(12), 0, math.radians(5)))

bpy.ops.object.mode_set(mode='OBJECT')

# 计算包围盒
meshes = [o for o in bpy.data.objects if o.type == 'MESH' and not o.hide_render]
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

# 侧向 2.5D 相机
cam_data = bpy.data.cameras.new(name="Cam_Rigged")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = max(size.x, size.y) * 1.22
cam_obj = bpy.data.objects.new(name="Cam_Rigged", object_data=cam_data)
bpy.context.collection.objects.link(cam_obj)

cam_dist = 3.6
cam_pos = Vector((center.x + cam_dist * math.cos(math.radians(20)), center.y - 0.2, center.z + cam_dist * math.sin(math.radians(20))))
forward = (center - cam_pos).normalized()
head_up = Vector((0, -1, 0))
right = forward.cross(head_up).normalized()
actual_up = right.cross(forward).normalized()
mat = Matrix((
    (right.x, actual_up.x, -forward.x, cam_pos.x),
    (right.y, actual_up.y, -forward.y, cam_pos.y),
    (right.z, actual_up.z, -forward.z, cam_pos.z),
    (0, 0, 0, 1)
))
cam_obj.matrix_world = mat
bpy.context.scene.camera = cam_obj

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

bpy.context.scene.render.film_transparent = True
bpy.context.scene.render.resolution_x = 720
bpy.context.scene.render.resolution_y = 720
render_out = os.path.join(output_dir, "nanzhujue_welded_rig_pose.png")
bpy.context.scene.render.filepath = render_out
bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath=blend_rigged_path)
print("=== WELDED RIG POSE RENDERED ===")
