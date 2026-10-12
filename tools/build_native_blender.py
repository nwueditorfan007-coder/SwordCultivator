import bpy, os, math
from mathutils import Matrix, Vector, Euler, Quaternion

for obj in list(bpy.data.objects): bpy.data.objects.remove(obj, do_unlink=True)
for mat in list(bpy.data.materials): bpy.data.materials.remove(mat, do_unlink=True)

fbx_model = r"E:\JyGameRemake\Assets\Art\Character\000_男主角\000_Nanzhujue.FBX"
tex_dir = r"E:\JyGameRemake\Assets\Art\Character\000_男主角\Textures"
output_dir = r"E:\SwordCultivator\assets\characters\nanzhujue"
blend_rigged_path = r"E:\SwordCultivator\resources\nanzhujue_blender_native.blend"

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

# 导入 FBX
import io_scene_fbx.import_fbx as ifbx
orig_link_hierarchy = ifbx.FbxImportHelperNode.link_hierarchy
def patched_link_hierarchy(self, fbx_tmpl, settings, scene):
    if self.meshes:
        for mesh in self.meshes:
            if self not in mesh.armature_setup:
                mesh.armature_setup[self] = (Matrix(), getattr(self, 'bind_matrix', None))
    return orig_link_hierarchy(self, fbx_tmpl, settings, scene)
ifbx.FbxImportHelperNode.link_hierarchy = patched_link_hierarchy

bpy.ops.import_scene.fbx(filepath=fbx_model)
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
orig_arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]

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

# 创建 Blender 原生 Humanoid 标准骨架 (Native Clean Armature)
char_meshes = [m for m in meshes if m not in [w_obj] and not m.hide_render]

# 计算人体各关键部位高度
bpy.ops.object.select_all(action='DESELECT')
for m in char_meshes:
    m.select_set(True)
bpy.context.view_layer.objects.active = char_meshes[0]
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# 创建干净骨架
arm_data = bpy.data.armatures.new(name="Armature_Clean")
clean_arm = bpy.data.objects.new(name="Armature_Clean", object_data=arm_data)
bpy.context.collection.objects.link(clean_arm)
bpy.context.view_layer.objects.active = clean_arm

bpy.ops.object.mode_set(mode='EDIT')
eb = clean_arm.data.edit_bones

# 搭建标准人体关节 (Z-Up 体系)
# 骨骼定义: Root -> Spine -> Chest -> Neck -> Head
root = eb.new("Root")
root.head = Vector((0, 0, 0)); root.tail = Vector((0, 0, 0.1))

pelvis = eb.new("Pelvis")
pelvis.head = Vector((0, 0, 0.95)); pelvis.tail = Vector((0, 0, 1.05))
pelvis.parent = root

spine = eb.new("Spine")
spine.head = Vector((0, 0, 1.05)); spine.tail = Vector((0, 0, 1.25))
spine.parent = pelvis

chest = eb.new("Chest")
chest.head = Vector((0, 0, 1.25)); chest.tail = Vector((0, 0, 1.45))
chest.parent = spine

neck = eb.new("Neck")
neck.head = Vector((0, 0, 1.45)); neck.tail = Vector((0, 0, 1.55))
neck.parent = chest

head = eb.new("Head")
head.head = Vector((0, 0, 1.55)); head.tail = Vector((0, 0, 1.80))
head.parent = neck

# 双臂
def make_arm(side, sign):
    ua = eb.new(f"UpperArm_{side}")
    ua.head = Vector((sign * 0.18, 0, 1.42))
    ua.tail = Vector((sign * 0.42, 0, 1.42))
    ua.parent = chest
    
    fa = eb.new(f"Forearm_{side}")
    fa.head = ua.tail
    fa.tail = Vector((sign * 0.65, 0, 1.42))
    fa.parent = ua
    fa.use_connect = True
    
    hand = eb.new(f"Hand_{side}")
    hand.head = fa.tail
    hand.tail = Vector((sign * 0.78, 0, 1.42))
    hand.parent = fa
    hand.use_connect = True

make_arm("R", 1)
make_arm("L", -1)

# 双腿
def make_leg(side, sign):
    thigh = eb.new(f"Thigh_{side}")
    thigh.head = Vector((sign * 0.12, 0, 0.95))
    thigh.tail = Vector((sign * 0.12, 0, 0.50))
    thigh.parent = pelvis
    
    calf = eb.new(f"Calf_{side}")
    calf.head = thigh.tail
    calf.tail = Vector((sign * 0.12, 0, 0.10))
    calf.parent = thigh
    calf.use_connect = True
    
    foot = eb.new(f"Foot_{side}")
    foot.head = calf.tail
    foot.tail = Vector((sign * 0.12, -0.15, 0.0))
    foot.parent = calf
    foot.use_connect = True

make_leg("R", 1)
make_leg("L", -1)

bpy.ops.object.mode_set(mode='OBJECT')

# 清除旧 Armature 并绑定原生干净骨架
bpy.data.objects.remove(orig_arm, do_unlink=True)

for m in char_meshes:
    m.modifiers.clear()
    m.parent = clean_arm
    mod = m.modifiers.new(name="Armature", type='ARMATURE')
    mod.object = clean_arm

# 自动蒙皮
bpy.ops.object.select_all(action='DESELECT')
for m in char_meshes:
    m.select_set(True)
clean_arm.select_set(True)
bpy.context.view_layer.objects.active = clean_arm
bpy.ops.object.parent_set(type='ARMATURE_AUTO')

# 摆出火柴人御剑低速姿态
bpy.ops.object.mode_set(mode='POSE')
pb = clean_arm.pose.bones

# 躯干微前倾 12°
pb['Spine'].rotation_euler = Euler((math.radians(12), 0, 0))
pb['Head'].rotation_euler = Euler((math.radians(-8), 0, 0))

# 右臂向前平举掐剑诀
pb['UpperArm_R'].rotation_euler = Euler((math.radians(-40), math.radians(20), math.radians(-30)))
pb['Forearm_R'].rotation_euler = Euler((math.radians(-20), math.radians(60), 0))

# 左臂向后负手微展
pb['UpperArm_L'].rotation_euler = Euler((math.radians(35), math.radians(-15), math.radians(20)))
pb['Forearm_L'].rotation_euler = Euler((0, math.radians(-25), 0))

# 双腿前后踏剑
pb['Thigh_R'].rotation_euler = Euler((math.radians(-25), 0, 0))
pb['Calf_R'].rotation_euler = Euler((math.radians(35), 0, 0))

pb['Thigh_L'].rotation_euler = Euler((math.radians(20), 0, 0))
pb['Calf_L'].rotation_euler = Euler((math.radians(15), 0, 0))

bpy.ops.object.mode_set(mode='OBJECT')

# 计算包围盒
min_v = Vector((float('inf'), float('inf'), float('inf')))
max_v = Vector((float('-inf'), float('-inf'), float('-inf')))
for m in char_meshes + [w_obj]:
    for corner in m.bound_box:
        world_pt = m.matrix_world @ Vector(corner)
        min_v.x = min(min_v.x, world_pt.x); max_v.x = max(max_v.x, world_pt.x)
        min_v.y = min(min_v.y, world_pt.y); max_v.y = max(max_v.y, world_pt.y)
        min_v.z = min(min_v.z, world_pt.z); max_v.z = max(max_v.z, world_pt.z)
center = (min_v + max_v) * 0.5
size = max_v - min_v

# 2.5D 相机
cam_data = bpy.data.cameras.new(name="Cam_Native")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = max(size.x, size.y, size.z) * 1.2
cam_obj = bpy.data.objects.new(name="Cam_Native", object_data=cam_data)
bpy.context.collection.objects.link(cam_obj)

cam_dist = 4.0
cam_pos = Vector((center.x + cam_dist * math.cos(math.radians(20)), center.y - cam_dist * math.sin(math.radians(20)), center.z + 0.5))
forward = (center - cam_pos).normalized()
up = Vector((0, 0, 1))
right = forward.cross(up).normalized()
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
render_out = os.path.join(output_dir, "nanzhujue_native_blender_success.png")
bpy.context.scene.render.filepath = render_out
bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath=blend_rigged_path)
print("=== NATIVE BLENDER CHARACTER POSED AND RENDERED ===")
