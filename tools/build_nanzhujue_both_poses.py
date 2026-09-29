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

blend_file = r"E:\SwordCultivator\resources\nanzhujue_yujian_poses.blend"
output_dir = r"E:\SwordCultivator\assets\characters\nanzhujue"

bpy.ops.wm.open_mainfile(filepath=blend_file)
arm = bpy.data.objects['Armature_Nanzhujue']
sword = bpy.data.objects['FlyingSword_Platform']

# 1. 飞剑水平垫在脚底 (脚底高度大约在 Y=-0.02)
sword.location = Vector((0.0, -0.02, -0.05))
sword.rotation_euler = (math.radians(90), 0, math.radians(90))
sword.scale = Vector((0.012, 0.012, 0.012))

# 2. 调配男主角【低速御剑姿态 (Hover)】
# 前脚踩剑尖，后脚踏剑尾，右手掐剑诀向前，左手向后微展
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
pb = arm.pose.bones

# 躯干微侧微倾
pb['Bip001 Spine'].rotation_euler = Euler((math.radians(8), math.radians(0), math.radians(8)))
pb['Bip001 Spine1'].rotation_euler = Euler((math.radians(4), 0, 0))
pb['Bip001 Head'].rotation_euler = Euler((math.radians(-6), 0, math.radians(-8)))

# 右腿（前脚，向前踏在剑身上，微屈膝）
pb['Bip001 R Thigh'].rotation_euler = Euler((math.radians(-12), math.radians(-5), math.radians(10)))
pb['Bip001 R Calf'].rotation_euler = Euler((math.radians(20), 0, 0))
pb['Bip001 R Foot'].rotation_euler = Euler((math.radians(-8), 0, 0))

# 左腿（后脚，向后踏在剑尾，踩实平衡）
pb['Bip001 L Thigh'].rotation_euler = Euler((math.radians(15), math.radians(5), math.radians(-10)))
pb['Bip001 L Calf'].rotation_euler = Euler((math.radians(10), 0, 0))
pb['Bip001 L Foot'].rotation_euler = Euler((math.radians(12), 0, 0))

# 右臂（身前平举掐剑诀）
pb['Bip001 R Clavicle'].rotation_euler = Euler((0, math.radians(15), 0))
pb['Bip001 R UpperArm'].rotation_euler = Euler((math.radians(-50), math.radians(25), math.radians(-35)))
pb['Bip001 R Forearm'].rotation_euler = Euler((math.radians(20), math.radians(50), math.radians(15)))

# 左臂（身后自然向后微张，保持平衡）
pb['Bip001 L Clavicle'].rotation_euler = Euler((0, math.radians(-15), 0))
pb['Bip001 L UpperArm'].rotation_euler = Euler((math.radians(35), math.radians(-15), math.radians(25)))
pb['Bip001 L Forearm'].rotation_euler = Euler((0, math.radians(-25), 0))

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

# 相机与光照
cam = bpy.data.objects['Cam_Nanzhujue']
cam.data.ortho_scale = max(size.x, size.y) * 1.25
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
cam.matrix_world = mat

# 渲染低速
render_low = os.path.join(output_dir, "nanzhujue_yujian_low_pose.png")
bpy.context.scene.render.filepath = render_low
bpy.ops.render.render(write_still=True)

# 3. 调配男主角【高速极速俯冲姿态 (Boost / Fast)】
# 45° 大幅前倾破风，双臂向后如翼展开顺风，双腿大跨步踩实飞剑
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
pb = arm.pose.bones

# 躯干大幅前倾 38°
pb['Bip001 Spine'].rotation_euler = Euler((math.radians(35), math.radians(0), math.radians(5)))
pb['Bip001 Spine1'].rotation_euler = Euler((math.radians(15), 0, 0))
pb['Bip001 Head'].rotation_euler = Euler((math.radians(-30), 0, 0))

# 双腿大跨步前后压低重心
pb['Bip001 R Thigh'].rotation_euler = Euler((math.radians(-40), math.radians(-10), math.radians(15)))
pb['Bip001 R Calf'].rotation_euler = Euler((math.radians(45), 0, 0))
pb['Bip001 R Foot'].rotation_euler = Euler((math.radians(-10), 0, 0))

pb['Bip001 L Thigh'].rotation_euler = Euler((math.radians(35), math.radians(10), math.radians(-15)))
pb['Bip001 L Calf'].rotation_euler = Euler((math.radians(20), 0, 0))
pb['Bip001 L Foot'].rotation_euler = Euler((math.radians(20), 0, 0))

# 双臂顺风向后如翼展拉开
pb['Bip001 R Clavicle'].rotation_euler = Euler((0, math.radians(20), 0))
pb['Bip001 R UpperArm'].rotation_euler = Euler((math.radians(55), math.radians(25), math.radians(-20)))
pb['Bip001 R Forearm'].rotation_euler = Euler((math.radians(10), math.radians(-30), math.radians(10)))

pb['Bip001 L Clavicle'].rotation_euler = Euler((0, math.radians(-20), 0))
pb['Bip001 L UpperArm'].rotation_euler = Euler((math.radians(60), math.radians(-25), math.radians(20)))
pb['Bip001 L Forearm'].rotation_euler = Euler((math.radians(10), math.radians(-30), math.radians(-10)))

bpy.ops.object.mode_set(mode='OBJECT')

# 飞剑配合前倾冲刺微低头 (5°)
sword.rotation_euler = (math.radians(95), 0, math.radians(90))

render_fast = os.path.join(output_dir, "nanzhujue_yujian_fast_pose.png")
bpy.context.scene.render.filepath = render_fast
bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath=blend_file)
print("=== NAN ZHU JUE LOW & FAST POSES RENDERED ===")
