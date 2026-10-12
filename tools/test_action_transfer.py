import bpy, os, math
from mathutils import Matrix

import io_scene_fbx.import_fbx as ifbx
orig_link_hierarchy = ifbx.FbxImportHelperNode.link_hierarchy
def patched_link_hierarchy(self, fbx_tmpl, settings, scene):
    if self.meshes:
        for mesh in self.meshes:
            if self not in mesh.armature_setup:
                mesh.armature_setup[self] = (Matrix(), getattr(self, 'bind_matrix', None))
    return orig_link_hierarchy(self, fbx_tmpl, settings, scene)
ifbx.FbxImportHelperNode.link_hierarchy = patched_link_hierarchy

# 清理
for obj in list(bpy.data.objects): bpy.data.objects.remove(obj, do_unlink=True)
for mat in list(bpy.data.materials): bpy.data.materials.remove(mat, do_unlink=True)
for act in list(bpy.data.actions): bpy.data.actions.remove(act, do_unlink=True)

fbx_model = r"E:\JyGameRemake\Assets\Art\Character\A_043_展晏\A_043_Zhanyan_LOD.FBX"
fbx_anim = r"E:\JyGameRemake\Assets\BuildSource\animations_3d\Humanoid\A_043_展晏\Battle\A_043_Zhanyan_Anim_Battle_Idle.FBX"

# 1. 导入模型
bpy.ops.import_scene.fbx(filepath=fbx_model)
base_arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
base_meshes = [o for o in bpy.data.objects if o.type == 'MESH']

# 2. 导入动画
bpy.ops.import_scene.fbx(filepath=fbx_anim)
anim_arm = [o for o in bpy.data.objects if o.type == 'ARMATURE' and o != base_arm][0]
anim_action = anim_arm.animation_data.action

# 3. 将动画 Action 直接赋给 base_arm
base_arm.animation_data_create()
base_arm.animation_data.action = anim_action
if hasattr(anim_action, 'slots') and len(anim_action.slots) > 0:
    base_arm.animation_data.action_slot = anim_action.slots[0]

# 删除动画骨骼
bpy.data.objects.remove(anim_arm, do_unlink=True)

# 打印骨骼在第 1 帧和第 20 帧的旋转状态
bpy.context.scene.frame_set(20)
print("Base Arm Action Attached:", base_arm.animation_data.action.name)
print("Spine Quat:", base_arm.pose.bones['Bip001 Spine'].rotation_quaternion)
print("R Hand Quat:", base_arm.pose.bones['Bip001 R Hand'].rotation_quaternion)
