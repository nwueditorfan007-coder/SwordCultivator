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

for obj in list(bpy.data.objects): bpy.data.objects.remove(obj, do_unlink=True)
for mat in list(bpy.data.materials): bpy.data.materials.remove(mat, do_unlink=True)
for act in list(bpy.data.actions): bpy.data.actions.remove(act, do_unlink=True)

fbx_model = r"E:\JyGameRemake\Assets\Art\Character\A_043_展晏\A_043_Zhanyan_LOD.FBX"
tex_dir = r"E:\JyGameRemake\Assets\Art\Character\A_043_展晏\Textures"
fbx_weapon = r"E:\JyGameRemake\Assets\Art\Character\F_武器\Model\A_043_Zhanyan_Weapon_01.FBX"
fbx_anim = r"E:\JyGameRemake\Assets\BuildSource\animations_3d\Humanoid\A_043_展晏\Battle\A_043_Zhanyan_Anim_Battle_Idle.FBX"

# 1. 导入模型
bpy.ops.import_scene.fbx(filepath=fbx_model)
base_arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
base_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
base_arm.name = "Armature_Zhanyan"

# 2. 导入动画
bpy.ops.import_scene.fbx(filepath=fbx_anim)
anim_arm = [o for o in bpy.data.objects if o.type == 'ARMATURE' and o != base_arm][0]
anim_action = anim_arm.animation_data.action
base_arm.animation_data_create()
base_arm.animation_data.action = anim_action
if hasattr(anim_action, 'slots') and len(anim_action.slots) > 0:
    base_arm.animation_data.action_slot = anim_action.slots[0]
bpy.data.objects.remove(anim_arm, do_unlink=True)

# 3. 材质
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
    for k, p in tex_mapping.items():
        if k.lower() in mat.name.lower() and os.path.exists(p):
            img = bpy.data.images.load(p)
            tex_node = nodes.new(type='ShaderNodeTexImage')
            tex_node.image = img
            links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
            break

# 4. 导入武器
bpy.ops.import_scene.fbx(filepath=fbx_weapon)
w_obj = [o for o in bpy.data.objects if "Weapon" in o.name and o.type == 'MESH'][0]
w_tex = os.path.join(tex_dir, "A_043_Zhanyan_Tex_Weapon_D.TGA")
if os.path.exists(w_tex):
    w_mat = bpy.data.materials.new(name="Mat_Weapon")
    w_mat.use_nodes = True
    wn = w_mat.node_tree.nodes
    wl = w_mat.node_tree.links
    wn.clear()
    w_out = wn.new(type='ShaderNodeOutputMaterial')
    w_bsdf = wn.new(type='ShaderNodeBsdfPrincipled')
    wl.new(w_bsdf.outputs['BSDF'], w_out.inputs['Surface'])
    w_img = bpy.data.images.load(w_tex)
    w_tex = wn.new(type='ShaderNodeTexImage')
    w_tex.image = w_img
    wl.new(w_tex.outputs['Color'], w_bsdf.inputs['Base Color'])
    w_obj.data.materials.clear()
    w_obj.data.materials.append(w_mat)

target_bone = "Weapon_R_Mount" if "Weapon_R_Mount" in base_arm.data.bones else "Bip001 R Hand"
w_obj.parent = base_arm
w_obj.parent_type = 'BONE'
w_obj.parent_bone = target_bone
w_obj.location = (0, 0, 0)
w_obj.rotation_euler = (0, 0, 0)

# 5. 将整个 Armature 扶正为 Z 轴朝上（绕 X 轴旋转 -90 度）
# 并在当前物体层级上立正
base_arm.rotation_euler = (math.radians(-90), 0, 0)

bpy.context.scene.frame_set(15)

# 6. 相机机位：在 Y = -3.5, Z = 0.9, 仰角 90 度看原点
cam_data = bpy.data.cameras.new(name="MainCam")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = 2.4
cam_obj = bpy.data.objects.new(name="MainCam", object_data=cam_data)
bpy.context.collection.objects.link(cam_obj)

cam_obj.location = (0.0, -3.5, 0.9)
cam_obj.rotation_euler = (math.radians(90), 0, 0)
bpy.context.scene.camera = cam_obj

# 7. 正面柔和光照
l1 = bpy.data.lights.new(name="KeyLight", type='SUN')
l1.energy = 2.8
o1 = bpy.data.objects.new(name="KeyLight", object_data=l1)
o1.rotation_euler = (math.radians(45), math.radians(20), math.radians(35))
bpy.context.collection.objects.link(o1)

l2 = bpy.data.lights.new(name="FillLight", type='SUN')
l2.energy = 1.2
l2.color = (0.8, 0.9, 1.0)
o2 = bpy.data.objects.new(name="FillLight", object_data=l2)
o2.rotation_euler = (math.radians(-30), math.radians(-30), math.radians(-135))
bpy.context.collection.objects.link(o2)

for o in bpy.data.objects:
    if o.type == 'ARMATURE':
        o.show_in_front = False

bpy.context.scene.render.film_transparent = True
bpy.context.scene.render.resolution_x = 960
bpy.context.scene.render.resolution_y = 960
render_out = r"E:\SwordCultivator\assets\characters\zhanyan\zhanyan_true_standing.png"
bpy.context.scene.render.filepath = render_out
bpy.ops.render.render(write_still=True)

blend_save_path = r"E:\SwordCultivator\resources\zhanyan_8way_flight_poses.blend"
bpy.ops.wm.save_as_mainfile(filepath=blend_save_path)
print("=== TRUE STANDING RENDER SAVED ===")
