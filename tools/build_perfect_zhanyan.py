import bpy, os, math
from mathutils import Matrix, Vector

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

anim_idle_path = r"E:\JyGameRemake\Assets\BuildSource\animations_3d\Humanoid\A_043_展晏\Battle\A_043_Zhanyan_Anim_Battle_Idle.FBX"
anim_skill1_path = r"E:\JyGameRemake\Assets\BuildSource\animations_3d\Humanoid\A_043_展晏\Battle\A_043_Zhanyan_Anim_Skill1.FBX"
anim_skill2_path = r"E:\JyGameRemake\Assets\BuildSource\animations_3d\Humanoid\A_043_展晏\Battle\A_043_Zhanyan_Anim_Skill2.FBX"
blend_save_path = r"E:\SwordCultivator\resources\zhanyan_8way_flight_poses.blend"
output_dir = r"E:\SwordCultivator\assets\characters\zhanyan"

# 1. 材质
tex_mapping = {
    "Clothes_01": os.path.join(tex_dir, "A_043_Zhanyan_Tex_Clothes_01_D.TGA"),
    "Clothes_02": os.path.join(tex_dir, "A_043_Zhanyan_Tex_Clothes_02_D.TGA"),
    "Face": os.path.join(tex_dir, "A_043_Zhanyan_Tex_Face_D.tga"),
    "Hair": os.path.join(tex_dir, "A_043_Zhanyan_Tex_Hair_D.tga"),
}

def create_mats():
    mats = {}
    for key, path in tex_mapping.items():
        mat = bpy.data.materials.new(name=f"Mat_Zhanyan_{key}")
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        nodes.clear()
        out = nodes.new(type='ShaderNodeOutputMaterial')
        bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
        bsdf.inputs['Roughness'].default_value = 0.6
        links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
        if os.path.exists(path):
            img = bpy.data.images.load(path)
            tex_node = nodes.new(type='ShaderNodeTexImage')
            tex_node.image = img
            links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
        mats[key] = mat
    return mats

shared_mats = create_mats()

# 武器材质
weapon_tex = os.path.join(tex_dir, "A_043_Zhanyan_Tex_Weapon_D.TGA")
w_mat = bpy.data.materials.new(name="Mat_Zhanyan_Weapon")
w_mat.use_nodes = True
wn = w_mat.node_tree.nodes
wl = w_mat.node_tree.links
wn.clear()
w_out = wn.new(type='ShaderNodeOutputMaterial')
w_bsdf = wn.new(type='ShaderNodeBsdfPrincipled')
wl.new(w_bsdf.outputs['BSDF'], w_out.inputs['Surface'])
if os.path.exists(weapon_tex):
    w_img = bpy.data.images.load(weapon_tex)
    w_tex = wn.new(type='ShaderNodeTexImage')
    w_tex.image = w_img
    wl.new(w_tex.outputs['Color'], w_bsdf.inputs['Base Color'])

# 2. 导入单个角色与动画
def create_character_instance(name, anim_fbx_path, x_pos):
    bpy.ops.import_scene.fbx(filepath=anim_fbx_path)
    anim_arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][-1]
    anim_arm.name = f"Armature_{name}"
    anim_arm.location = (x_pos, 0, 0)
    
    if anim_arm.animation_data and anim_arm.animation_data.action:
        act = anim_arm.animation_data.action
        if hasattr(act, 'slots') and len(act.slots) > 0:
            anim_arm.animation_data.action_slot = act.slots[0]
            
    bpy.ops.import_scene.fbx(filepath=fbx_model)
    new_meshes = [o for o in bpy.data.objects if o.type == 'MESH' and "Weapon" not in o.name and not o.name.startswith("Processed_")]
    temp_arm = [o for o in bpy.data.objects if o.type == 'ARMATURE' and o != anim_arm][-1]
    
    for m in new_meshes:
        m.name = f"Processed_{name}_{m.name}"
        m.parent = anim_arm
        for mod in m.modifiers:
            if mod.type == 'ARMATURE':
                mod.object = anim_arm
        for slot in m.material_slots:
            for k, mat in shared_mats.items():
                if k.lower() in slot.name.lower():
                    slot.material = mat
                    break
                    
    bpy.data.objects.remove(temp_arm, do_unlink=True)
    
    bpy.ops.import_scene.fbx(filepath=fbx_weapon)
    w_obj = [o for o in bpy.data.objects if "Weapon" in o.name and o.type == 'MESH'][-1]
    w_obj.name = f"Weapon_{name}"
    w_obj.data.materials.clear()
    w_obj.data.materials.append(w_mat)
    
    target_bone = "Weapon_R_Mount" if "Weapon_R_Mount" in anim_arm.data.bones else "Bip001 R Hand"
    w_obj.parent = anim_arm
    w_obj.parent_type = 'BONE'
    w_obj.parent_bone = target_bone
    w_obj.location = (0, 0, 0)
    w_obj.rotation_euler = (0, 0, 0)
    
    anim_arm.show_in_front = False
    return anim_arm

char_hover = create_character_instance("01_Hover_低速待机", anim_idle_path, -1.8)
char_cruise = create_character_instance("02_Cruise_中速御风", anim_skill1_path, 0.0)
char_boost = create_character_instance("03_Boost_极速冲刺", anim_skill2_path, 1.8)

bpy.context.scene.frame_set(15)

# 3. 计算所有 Mesh 的中心点
all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
min_v = Vector((float('inf'), float('inf'), float('inf')))
max_v = Vector((float('-inf'), float('-inf'), float('-inf')))

for m in all_meshes:
    for corner in m.bound_box:
        world_pt = m.matrix_world @ Vector(corner)
        min_v.x = min(min_v.x, world_pt.x); max_v.x = max(max_v.x, world_pt.x)
        min_v.y = min(min_v.y, world_pt.y); max_v.y = max(max_v.y, world_pt.y)
        min_v.z = min(min_v.z, world_pt.z); max_v.z = max(max_v.z, world_pt.z)

center = (min_v + max_v) * 0.5
size = max_v - min_v
print(f"Computed Mesh Center: {center}, Size: {size}")

# 4. 创建正对前方的优雅相机 (LookAt Center)
cam_data = bpy.data.cameras.new(name="MainViewCamera")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = max(size.x, size.y) * 1.15
cam_obj = bpy.data.objects.new(name="MainViewCamera", object_data=cam_data)
bpy.context.collection.objects.link(cam_obj)

# 视线从前上方朝向 Center
cam_dist = 5.0
cam_obj.location = Vector((center.x, center.y - 0.2, center.z + cam_dist))
cam_obj.rotation_euler = Vector((0, 0, math.radians(180)))
bpy.context.scene.camera = cam_obj

# 5. 灯光
l1 = bpy.data.lights.new(name="KeyLight", type='SUN')
l1.energy = 3.2
o1 = bpy.data.objects.new(name="KeyLight", object_data=l1)
o1.rotation_euler = (math.radians(45), math.radians(20), math.radians(45))
bpy.context.collection.objects.link(o1)

l2 = bpy.data.lights.new(name="FillLight", type='SUN')
l2.energy = 1.5
l2.color = (0.75, 0.88, 1.0)
o2 = bpy.data.objects.new(name="FillLight", object_data=l2)
o2.rotation_euler = (math.radians(-30), math.radians(-30), math.radians(-135))
bpy.context.collection.objects.link(o2)

# 6. 渲染并保存
bpy.context.scene.render.film_transparent = True
bpy.context.scene.render.resolution_x = 1280
bpy.context.scene.render.resolution_y = 720
render_out = os.path.join(output_dir, "zhanyan_3speeds_overview.png")
bpy.context.scene.render.filepath = render_out
bpy.ops.render.render(write_still=True)

bpy.ops.wm.save_as_mainfile(filepath=blend_save_path)
print("=== PERFECT SCENE CREATED AND RENDERED ===")
