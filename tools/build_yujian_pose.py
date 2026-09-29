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

fbx_model = r"E:\JyGameRemake\Assets\Art\Character\A_043_展晏\A_043_Zhanyan_LOD.FBX"
tex_dir = r"E:\JyGameRemake\Assets\Art\Character\A_043_展晏\Textures"
fbx_weapon = r"E:\JyGameRemake\Assets\Art\Character\F_武器\Model\A_043_Zhanyan_Weapon_01.FBX"
output_dir = r"E:\SwordCultivator\assets\characters\zhanyan"

# 材质
tex_mapping = {
    "Clothes_01": os.path.join(tex_dir, "A_043_Zhanyan_Tex_Clothes_01_D.TGA"),
    "Clothes_02": os.path.join(tex_dir, "A_043_Zhanyan_Tex_Clothes_02_D.TGA"),
    "Face": os.path.join(tex_dir, "A_043_Zhanyan_Tex_Face_D.tga"),
    "Hair": os.path.join(tex_dir, "A_043_Zhanyan_Tex_Hair_D.tga"),
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

# 导入模型
bpy.ops.import_scene.fbx(filepath=fbx_model)
armature = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
armature.name = "Armature_Zhanyan"

for m in meshes:
    for slot in m.material_slots:
        for key in tex_mapping.keys():
            if key.lower() in slot.name.lower():
                slot.material = bpy.data.materials[f"Mat_{key}"]
                break

# 导入飞剑（作为脚下踩着的飞剑 Platform）
bpy.ops.import_scene.fbx(filepath=fbx_weapon)
w_obj = [o for o in bpy.data.objects if "Weapon" in o.name and o.type == 'MESH'][0]
w_obj.name = "FlyingSword_Platform"
weapon_tex = os.path.join(tex_dir, "A_043_Zhanyan_Tex_Weapon_D.TGA")
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

# 将飞剑水平放置在脚底 (Y=0.05 附近)
w_obj.location = Vector((0, 0.05, 0))
w_obj.rotation_euler = (math.radians(90), 0, math.radians(90))
w_obj.scale = Vector((1.3, 1.3, 1.3))

# 进入 Pose Mode 手工精准对齐火柴人低速御剑姿态
bpy.context.view_layer.objects.active = armature
bpy.ops.object.mode_set(mode='POSE')
pb = armature.pose.bones

# 1. 消除所有次级骨骼位移
for b in pb:
    b.location = Vector((0, 0, 0))
    b.rotation_quaternion = Quaternion((1, 0, 0, 0))
    b.rotation_euler = Euler((0, 0, 0))

# 2. 调配低速踏剑姿态 (前右脚、后左脚前后错步踏剑，右手身前掐诀，左手身后负手)
# 躯干微侧倾
pb['Bip001 Spine'].rotation_euler = Euler((math.radians(-5), math.radians(5), math.radians(10)))
pb['Bip001 Spine1'].rotation_euler = Euler((math.radians(-5), math.radians(0), math.radians(5)))
pb['Bip001 Head'].rotation_euler = Euler((math.radians(5), math.radians(0), math.radians(-10)))

# 右腿（前脚，踏剑前部，屈膝）
pb['Bip001 R Thigh'].rotation_euler = Euler((math.radians(20), math.radians(-10), math.radians(15)))
pb['Bip001 R Calf'].rotation_euler = Euler((math.radians(-25), math.radians(0), math.radians(0)))
pb['Bip001 R Foot'].rotation_euler = Euler((math.radians(5), math.radians(10), math.radians(-15)))

# 左腿（后脚，踏剑尾部，微屈）
pb['Bip001 L Thigh'].rotation_euler = Euler((math.radians(-15), math.radians(10), math.radians(-10)))
pb['Bip001 L Calf'].rotation_euler = Euler((math.radians(-15), math.radians(0), math.radians(0)))
pb['Bip001 L Foot'].rotation_euler = Euler((math.radians(30), math.radians(-10), math.radians(10)))

# 右手（前手，掐剑诀伸向前方）
pb['Bip001 R Clavicle'].rotation_euler = Euler((0, math.radians(10), 0))
pb['Bip001 R UpperArm'].rotation_euler = Euler((math.radians(-35), math.radians(20), math.radians(-40)))
pb['Bip001 R Forearm'].rotation_euler = Euler((math.radians(0), math.radians(-65), math.radians(0)))

# 左手（后手，负手于身后微垂）
pb['Bip001 L Clavicle'].rotation_euler = Euler((0, math.radians(-10), 0))
pb['Bip001 L UpperArm'].rotation_euler = Euler((math.radians(20), math.radians(-15), math.radians(30)))
pb['Bip001 L Forearm'].rotation_euler = Euler((math.radians(0), math.radians(-30), math.radians(0)))

bpy.ops.object.mode_set(mode='OBJECT')

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

# 侧向相机 (01_Right 视角)
cam_dist = 3.5
# 视角从右前方看
cam_pos = Vector((center.x + cam_dist * math.cos(math.radians(20)), center.y - 0.2, center.z))
forward = (center - cam_pos).normalized()
head_up = Vector((0, -1, 0))
right = forward.cross(head_up).normalized()
actual_up = right.cross(forward).normalized()

cam_data = bpy.data.cameras.new(name="Cam_Low")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = max(size.x, size.y) * 1.2
cam_obj = bpy.data.objects.new(name="Cam_Low", object_data=cam_data)
bpy.context.collection.objects.link(cam_obj)

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

# 渲染低速踏剑姿态
bpy.context.scene.render.film_transparent = True
bpy.context.scene.render.resolution_x = 720
bpy.context.scene.render.resolution_y = 720
render_out = os.path.join(output_dir, "zhanyan_yujian_low_pose.png")
bpy.context.scene.render.filepath = render_out
bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath=r"E:\SwordCultivator\resources\zhanyan_yujian_poses.blend")
print("=== LOW SPEED YUJIAN POSE RENDERED ===")
