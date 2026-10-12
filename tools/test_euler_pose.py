import bpy, os, math
from mathutils import Matrix, Vector, Euler, Quaternion

blend_file = r"E:\SwordCultivator\resources\nanzhujue_yujian_poses.blend"
output_dir = r"E:\SwordCultivator\assets\characters\nanzhujue"

bpy.ops.wm.open_mainfile(filepath=blend_file)
arm = bpy.data.objects['Armature_Nanzhujue']
sword = bpy.data.objects['FlyingSword_Platform']

bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
pb = arm.pose.bones

def set_bone_euler(bone_name, deg_x, deg_y, deg_z):
    if bone_name in pb:
        b = pb[bone_name]
        b.rotation_mode = 'XYZ'
        b.rotation_euler = Euler((math.radians(deg_x), math.radians(deg_y), math.radians(deg_z)))

# 躯干大幅前倾 40°
set_bone_euler('Bip001 Spine', 35, 0, 0)
set_bone_euler('Bip001 Spine1', 15, 0, 0)
set_bone_euler('Bip001 Head', -30, 0, 0)

# 双腿大跨步前后踏剑
set_bone_euler('Bip001 R Thigh', -35, -5, 10)
set_bone_euler('Bip001 R Calf', 45, 0, 0)
set_bone_euler('Bip001 L Thigh', 35, 5, -10)
set_bone_euler('Bip001 L Calf', 20, 0, 0)

# 双臂向后飞掠
set_bone_euler('Bip001 R UpperArm', 60, 20, -20)
set_bone_euler('Bip001 R Forearm', 20, -20, 10)
set_bone_euler('Bip001 L UpperArm', 60, -20, 20)
set_bone_euler('Bip001 L Forearm', 20, -20, -10)

bpy.ops.object.mode_set(mode='OBJECT')

render_fast = os.path.join(output_dir, "nanzhujue_euler_test.png")
bpy.context.scene.render.filepath = render_fast
bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=blend_file)
print("=== NAN ZHU JUE EULER TEST RENDERED ===")
