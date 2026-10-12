import bpy, os, math
from mathutils import Matrix, Vector, Euler, Quaternion

blend_file = r"E:\SwordCultivator\resources\nanzhujue_rigged_character.blend"
output_dir = r"E:\SwordCultivator\assets\characters\nanzhujue"

bpy.ops.wm.open_mainfile(filepath=blend_file)
arm = bpy.data.objects['Armature_Nanzhujue']
sword = bpy.data.objects['FlyingSword_Platform']

# 飞剑垫在脚底 (Y=0.0, X=0, Z=-0.05)
sword.location = Vector((0.0, -0.01, -0.05))
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
pose_joint('Bip001 Spine', pitch=8, yaw=0, roll=5)
pose_joint('Bip001 Spine1', pitch=4, yaw=0, roll=0)
pose_joint('Bip001 Head', pitch=-6, yaw=0, roll=-5)

# 2. 右臂（从 T-Pose 顺滑下放 + 屈肘掐诀）
# 绕 Z 轴向下放下 65度，绕 Y 轴向前抬 25度
pose_joint('Bip001 R UpperArm', pitch=0, yaw=-65, roll=25)
# 小臂向前屈肘 50度
pose_joint('Bip001 R Forearm', pitch=0, yaw=0, roll=50)

# 3. 左臂（从 T-Pose 顺滑下放 + 向后微扬负手）
pose_joint('Bip001 L UpperArm', pitch=0, yaw=60, roll=-20)
pose_joint('Bip001 L Forearm', pitch=0, yaw=0, roll=-30)

# 4. 双腿（踏剑：右前脚屈膝踩剑头，左后脚蹬踩剑尾）
pose_joint('Bip001 R Thigh', pitch=-18, yaw=-5, roll=8)
pose_joint('Bip001 R Calf', pitch=25, yaw=0, roll=0)
pose_joint('Bip001 R Foot', pitch=-7, yaw=0, roll=0)

pose_joint('Bip001 L Thigh', pitch=16, yaw=5, roll=-8)
pose_joint('Bip001 L Calf', pitch=12, yaw=0, roll=0)
pose_joint('Bip001 L Foot', pitch=8, yaw=0, roll=0)

bpy.ops.object.mode_set(mode='OBJECT')

render_out = os.path.join(output_dir, "nanzhujue_sword_master_pose.png")
bpy.context.scene.render.filepath = render_out
bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath=blend_file)
print("=== SWORD MASTER POSE RENDERED ===")
