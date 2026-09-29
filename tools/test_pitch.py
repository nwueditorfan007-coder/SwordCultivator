import bpy, os, math
from mathutils import Matrix, Vector, Euler, Quaternion

blend_file = r"E:\SwordCultivator\resources\nanzhujue_rigged_character.blend"
output_dir = r"E:\SwordCultivator\assets\characters\nanzhujue"

bpy.ops.wm.open_mainfile(filepath=blend_file)
arm = bpy.data.objects['Armature_Nanzhujue']
sword = bpy.data.objects['FlyingSword_Platform']

sword.location = Vector((0.0, 0.05, -0.05))
sword.rotation_euler = (math.radians(90), 0, math.radians(90))
sword.scale = Vector((0.012, 0.012, 0.012))

bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
pb = arm.pose.bones

for b in pb:
    b.rotation_mode = 'QUATERNION'
    b.rotation_quaternion = Quaternion((1, 0, 0, 0))
    b.location = Vector((0, 0, 0))

def pose_joint(bone_name, pitch=0, yaw=0, roll=0):
    if bone_name in pb:
        b = pb[bone_name]
        qx = Quaternion(Vector((1, 0, 0)), math.radians(pitch))
        qy = Quaternion(Vector((0, 1, 0)), math.radians(roll))
        qz = Quaternion(Vector((0, 0, 1)), math.radians(yaw))
        b.rotation_quaternion = qz @ qy @ qx

# 1. 躯干微侧微倾 10°
pose_joint('Bip001 Spine', pitch=10, yaw=0, roll=5)
pose_joint('Bip001 Spine1', pitch=5, yaw=0, roll=0)
pose_joint('Bip001 Head', pitch=-8, yaw=0, roll=-5)

# 2. 右臂（身前掐诀）：屈肘 55 度
pose_joint('Bip001 R UpperArm', pitch=-35, yaw=15, roll=-10)
pose_joint('Bip001 R Forearm', pitch=55, yaw=10, roll=0)
pose_joint('Bip001 R Hand', pitch=-15, yaw=0, roll=0)

# 3. 左臂（身后负手）：向后微扬
pose_joint('Bip001 L UpperArm', pitch=25, yaw=-10, roll=10)
pose_joint('Bip001 L Forearm', pitch=30, yaw=-5, roll=0)

# 4. 双腿（前后踏剑）：右脚在前微屈踏剑尖，左脚在后踏剑尾
pose_joint('Bip001 R Thigh', pitch=-18, yaw=-5, roll=5)
pose_joint('Bip001 R Calf', pitch=28, yaw=0, roll=0)
pose_joint('Bip001 R Foot', pitch=-10, yaw=0, roll=0)

pose_joint('Bip001 L Thigh', pitch=15, yaw=5, roll=-5)
pose_joint('Bip001 L Calf', pitch=12, yaw=0, roll=0)
pose_joint('Bip001 L Foot', pitch=8, yaw=0, roll=0)

bpy.ops.object.mode_set(mode='OBJECT')

render_out = os.path.join(output_dir, "nanzhujue_yujian_pitch_success.png")
bpy.context.scene.render.filepath = render_out
bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath=blend_file)
print("=== PITCH SUCCESS RENDERED ===")
