import sys
import os
import math
from mathutils import Matrix, Vector, Euler

import io_scene_fbx.import_fbx as ifbx
orig_link_hierarchy = ifbx.FbxImportHelperNode.link_hierarchy
def patched_link_hierarchy(self, fbx_tmpl, settings, scene):
    if self.meshes:
        for mesh in self.meshes:
            if self not in mesh.armature_setup:
                mesh.armature_setup[self] = (Matrix(), getattr(self, 'bind_matrix', None))
    return orig_link_hierarchy(self, fbx_tmpl, settings, scene)
ifbx.FbxImportHelperNode.link_hierarchy = patched_link_hierarchy

import bpy

for obj in list(bpy.data.objects):
    bpy.data.objects.remove(obj, do_unlink=True)
for mat in list(bpy.data.materials):
    bpy.data.materials.remove(mat, do_unlink=True)
for act in list(bpy.data.actions):
    bpy.data.actions.remove(act, do_unlink=True)

fbx_model_path = r"E:\JyGameRemake\Assets\Art\Character\A_043_展晏\A_043_Zhanyan_LOD.FBX"
tex_dir = r"E:\JyGameRemake\Assets\Art\Character\A_043_展晏\Textures"
weapon_fbx_path = r"E:\JyGameRemake\Assets\Art\Character\F_武器\Model\A_043_Zhanyan_Weapon_01.FBX"
idle_anim_path = r"E:\JyGameRemake\Assets\BuildSource\animations_3d\Humanoid\A_043_展晏\Battle\A_043_Zhanyan_Anim_Battle_Idle.FBX"
blend_save_path = r"E:\SwordCultivator\resources\zhanyan_8way_flight_poses.blend"

# 1. 导入模型
bpy.ops.import_scene.fbx(filepath=fbx_model_path)
armature_obj = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
mesh_objs = [o for o in bpy.data.objects if o.type == 'MESH']
armature_obj.name = "Armature_Zhanyan_Base"

# 2. 赋予材质
tex_mapping = {
    "Clothes_01": os.path.join(tex_dir, "A_043_Zhanyan_Tex_Clothes_01_D.TGA"),
    "Clothes_02": os.path.join(tex_dir, "A_043_Zhanyan_Tex_Clothes_02_D.TGA"),
    "Face": os.path.join(tex_dir, "A_043_Zhanyan_Tex_Face_D.tga"),
    "Hair": os.path.join(tex_dir, "A_043_Zhanyan_Tex_Hair_D.tga"),
}

for mat in bpy.data.materials:
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    out = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.inputs['Roughness'].default_value = 0.5
    links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
    
    for key, path in tex_mapping.items():
        if key.lower() in mat.name.lower() and os.path.exists(path):
            img = bpy.data.images.load(path)
            tex_node = nodes.new(type='ShaderNodeTexImage')
            tex_node.image = img
            links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
            break

# 3. 导入武器
bpy.ops.import_scene.fbx(filepath=weapon_fbx_path)
weapon_obj = [o for o in bpy.data.objects if "Weapon" in o.name and o.type == 'MESH'][0]
weapon_tex = os.path.join(tex_dir, "A_043_Zhanyan_Tex_Weapon_D.TGA")
if os.path.exists(weapon_tex):
    w_mat = bpy.data.materials.new(name="Mat_Weapon")
    w_mat.use_nodes = True
    wn = w_mat.node_tree.nodes
    wl = w_mat.node_tree.links
    wn.clear()
    w_out = wn.new(type='ShaderNodeOutputMaterial')
    w_bsdf = wn.new(type='ShaderNodeBsdfPrincipled')
    wl.new(w_bsdf.outputs['BSDF'], w_out.inputs['Surface'])
    w_img = bpy.data.images.load(weapon_tex)
    w_tex = wn.new(type='ShaderNodeTexImage')
    w_tex.image = w_img
    wl.new(w_tex.outputs['Color'], w_bsdf.inputs['Base Color'])
    weapon_obj.data.materials.clear()
    weapon_obj.data.materials.append(w_mat)

# 挂接武器到 Weapon_R_Mount 或 Bip001 R Hand
target_bone = "Weapon_R_Mount" if "Weapon_R_Mount" in armature_obj.data.bones else "Bip001 R Hand"
weapon_obj.parent = armature_obj
weapon_obj.parent_type = 'BONE'
weapon_obj.parent_bone = target_bone
weapon_obj.location = (0, 0, 0)
weapon_obj.rotation_euler = (0, 0, 0)

# 4. 导入动画
bpy.ops.import_scene.fbx(filepath=idle_anim_path)
imported_arms = [o for o in bpy.data.objects if o.type == 'ARMATURE' and o != armature_obj]
if imported_arms:
    anim_arm = imported_arms[0]
    if anim_arm.animation_data and anim_arm.animation_data.action:
        armature_obj.animation_data_create()
        armature_obj.animation_data.action = anim_arm.animation_data.action
    bpy.data.objects.remove(anim_arm, do_unlink=True)

# 5. 复制出 3 档（微前倾，保持原本帅气武学待机身姿）
def duplicate_character(name, x_offset, lean_pitch_deg):
    bpy.ops.object.select_all(action='DESELECT')
    armature_obj.select_set(True)
    for m in mesh_objs:
        m.select_set(True)
    weapon_obj.select_set(True)
    bpy.context.view_layer.objects.active = armature_obj
    bpy.ops.object.duplicate()
    
    new_arm = bpy.context.active_object
    new_arm.name = f"Armature_{name}"
    new_arm.location = (x_offset, 0, 0)
    # 整体俯冲破风前倾角
    new_arm.rotation_euler = (math.radians(lean_pitch_deg), 0, 0)
    return new_arm

arm_hover = duplicate_character("01_Hover_低速待机(直立)", -1.8, 0.0)
arm_cruise = duplicate_character("02_Cruise_中速御风(微倾)", 0.0, 15.0)
arm_boost = duplicate_character("03_Boost_极速冲刺(破风)", 1.8, 30.0)

# 隐藏原始模板
armature_obj.hide_viewport = True
armature_obj.hide_render = True
for m in mesh_objs:
    m.hide_viewport = True
    m.hide_render = True
weapon_obj.hide_viewport = True
weapon_obj.hide_render = True

# 6. 单一展示主相机（清晰俯视 3 人正面）
cam_data = bpy.data.cameras.new(name="MainViewCamera")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = 5.2
cam_obj = bpy.data.objects.new(name="MainViewCamera", object_data=cam_data)
bpy.context.collection.objects.link(cam_obj)
cam_obj.location = (0, -6.5, 2.0)
cam_obj.rotation_euler = (math.radians(72), 0, 0)
bpy.context.scene.camera = cam_obj

# 7. 柔和三点光照
l1 = bpy.data.lights.new(name="KeyLight", type='SUN')
l1.energy = 2.5
o1 = bpy.data.objects.new(name="KeyLight", object_data=l1)
o1.rotation_euler = (math.radians(45), math.radians(15), math.radians(45))
bpy.context.collection.objects.link(o1)

l2 = bpy.data.lights.new(name="FillLight", type='SUN')
l2.energy = 1.2
l2.color = (0.75, 0.88, 1.0)
o2 = bpy.data.objects.new(name="FillLight", object_data=l2)
o2.rotation_euler = (math.radians(-30), math.radians(-30), math.radians(-135))
bpy.context.collection.objects.link(o2)

# 隐藏骨骼显示，清爽视口
for o in bpy.data.objects:
    if o.type == 'ARMATURE':
        o.show_in_front = False
        o.data.show_axes = False

# 8. 保存 .blend 文件并渲染一张正面预览
bpy.context.scene.render.film_transparent = True
bpy.context.scene.render.resolution_x = 1280
bpy.context.scene.render.resolution_y = 720
render_out = r"E:\SwordCultivator\assets\characters\zhanyan\zhanyan_3speeds_overview.png"
bpy.context.scene.render.filepath = render_out
bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath=blend_save_path)
print("=== PERFECT BLEND SAVED SUCCESSFULLY ===")
