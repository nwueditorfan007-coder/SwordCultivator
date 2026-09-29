import sys
import os
import math
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

import bpy

for obj in list(bpy.data.objects):
    bpy.data.objects.remove(obj, do_unlink=True)
for mat in list(bpy.data.materials):
    bpy.data.materials.remove(mat, do_unlink=True)

fbx_model_path = r"E:\JyGameRemake\Assets\Art\Character\A_043_展晏\A_043_Zhanyan_LOD.FBX"
tex_dir = r"E:\JyGameRemake\Assets\Art\Character\A_043_展晏\Textures"
weapon_fbx_path = r"E:\JyGameRemake\Assets\Art\Character\F_武器\Model\A_043_Zhanyan_Weapon_01.FBX"
idle_anim_path = r"E:\JyGameRemake\Assets\BuildSource\animations_3d\Humanoid\A_043_展晏\Battle\A_043_Zhanyan_Anim_Battle_Idle.FBX"
blend_save_path = r"E:\SwordCultivator\resources\zhanyan_8way_flight_poses.blend"

# 1. 先导入带有动画的骨架
bpy.ops.import_scene.fbx(filepath=idle_anim_path)
anim_armature = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
anim_armature.name = "Armature_With_Action"

# 2. 导入模型网格
bpy.ops.import_scene.fbx(filepath=fbx_model_path)
mesh_objs = [o for o in bpy.data.objects if o.type == 'MESH' and "Weapon" not in o.name]
model_armature = [o for o in bpy.data.objects if o.type == 'ARMATURE' and o != anim_armature][0]

# 将所有 Mesh 的 Armature 修改器和父级重定向到 anim_armature
for m in mesh_objs:
    m.parent = anim_armature
    for mod in m.modifiers:
        if mod.type == 'ARMATURE':
            mod.object = anim_armature

# 删除多余的 model_armature
bpy.data.objects.remove(model_armature, do_unlink=True)

# 3. 赋予材质
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

# 4. 导入武器并挂接
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

target_bone = "Weapon_R_Mount" if "Weapon_R_Mount" in anim_armature.data.bones else "Bip001 R Hand"
weapon_obj.parent = anim_armature
weapon_obj.parent_type = 'BONE'
weapon_obj.parent_bone = target_bone
weapon_obj.location = (0, 0, 0)
weapon_obj.rotation_euler = (0, 0, 0)

# 设置第 1 帧
bpy.context.scene.frame_set(1)

# 相机与光照
cam_data = bpy.data.cameras.new(name="MainViewCamera")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = 3.5
cam_obj = bpy.data.objects.new(name="MainViewCamera", object_data=cam_data)
bpy.context.collection.objects.link(cam_obj)
cam_obj.location = (0, -5.0, 1.2)
cam_obj.rotation_euler = (math.radians(80), 0, 0)
bpy.context.scene.camera = cam_obj

l1 = bpy.data.lights.new(name="KeyLight", type='SUN')
l1.energy = 2.5
o1 = bpy.data.objects.new(name="KeyLight", object_data=l1)
o1.rotation_euler = (math.radians(45), math.radians(15), math.radians(45))
bpy.context.collection.objects.link(o1)

# 渲染测试图
bpy.context.scene.render.film_transparent = True
bpy.context.scene.render.resolution_x = 960
bpy.context.scene.render.resolution_y = 720
render_out = r"E:\SwordCultivator\assets\characters\zhanyan\zhanyan_anim_test.png"
bpy.context.scene.render.filepath = render_out
bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath=blend_save_path)
print("=== ANIMATION ATTACHED SUCCESSFULLY ===")
