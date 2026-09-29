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

fbx_model_path = r"E:\JyGameRemake\Assets\Art\Character\A_043_展晏\A_043_Zhanyan_LOD.FBX"
tex_dir = r"E:\JyGameRemake\Assets\Art\Character\A_043_展晏\Textures"
weapon_fbx_path = r"E:\JyGameRemake\Assets\Art\Character\F_武器\Model\A_043_Zhanyan_Weapon_01.FBX"
idle_anim_path = r"E:\JyGameRemake\Assets\BuildSource\animations_3d\Humanoid\A_043_展晏\Battle\A_043_Zhanyan_Anim_Battle_Idle.FBX"

output_dir = r"E:\SwordCultivator\assets\characters\zhanyan"
os.makedirs(output_dir, exist_ok=True)
blend_save_path = r"E:\SwordCultivator\resources\zhanyan_8way_flight_poses.blend"

bpy.ops.import_scene.fbx(filepath=fbx_model_path)

armature_obj = None
mesh_objs = []
for obj in bpy.data.objects:
    if obj.type == 'ARMATURE':
        armature_obj = obj
    elif obj.type == 'MESH':
        mesh_objs.append(obj)

if armature_obj:
    armature_obj.name = "Armature_Zhanyan_Base"

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
    
    output_node = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf_node = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf_node.inputs['Roughness'].default_value = 0.8
    bsdf_node.inputs['Specular IOR Level'].default_value = 0.1
    links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])
    
    tex_path = None
    for key, path in tex_mapping.items():
        if key.lower() in mat.name.lower() and os.path.exists(path):
            tex_path = path
            break
            
    if tex_path:
        tex_image = bpy.data.images.load(tex_path)
        tex_node = nodes.new(type='ShaderNodeTexImage')
        tex_node.image = tex_image
        links.new(tex_node.outputs['Color'], bsdf_node.inputs['Base Color'])

bpy.ops.import_scene.fbx(filepath=weapon_fbx_path)
weapon_obj = None
for obj in bpy.data.objects:
    if "Weapon" in obj.name and obj.type == 'MESH':
        weapon_obj = obj
        break

if weapon_obj and armature_obj:
    weapon_tex_path = os.path.join(tex_dir, "A_043_Zhanyan_Tex_Weapon_D.TGA")
    if os.path.exists(weapon_tex_path):
        w_mat = bpy.data.materials.new(name="Material_Zhanyan_Weapon")
        w_mat.use_nodes = True
        w_nodes = w_mat.node_tree.nodes
        w_links = w_mat.node_tree.links
        w_nodes.clear()
        w_out = w_nodes.new(type='ShaderNodeOutputMaterial')
        w_bsdf = w_nodes.new(type='ShaderNodeBsdfPrincipled')
        w_links.new(w_bsdf.outputs['BSDF'], w_out.inputs['Surface'])
        w_tex_img = bpy.data.images.load(weapon_tex_path)
        w_tex_node = w_nodes.new(type='ShaderNodeTexImage')
        w_tex_node.image = w_tex_img
        w_links.new(w_tex_node.outputs['Color'], w_bsdf.inputs['Base Color'])
        weapon_obj.data.materials.clear()
        weapon_obj.data.materials.append(w_mat)

    hand_bone_name = "S_hand_r"
    if hand_bone_name in armature_obj.data.bones:
        weapon_obj.parent = armature_obj
        weapon_obj.parent_type = 'BONE'
        weapon_obj.parent_bone = hand_bone_name
        weapon_obj.location = (0, 0, 0)
        weapon_obj.rotation_euler = (0, 0, 0)

bpy.ops.import_scene.fbx(filepath=idle_anim_path)
imported_arm = None
for obj in bpy.data.objects:
    if obj.type == 'ARMATURE' and obj != armature_obj:
        imported_arm = obj
        break

if imported_arm and imported_arm.animation_data and imported_arm.animation_data.action:
    base_action = imported_arm.animation_data.action
    base_action.name = "Action_Zhanyan_Battle_Idle"
    if not armature_obj.animation_data:
        armature_obj.animation_data_create()
    armature_obj.animation_data.action = base_action
    bpy.data.objects.remove(imported_arm, do_unlink=True)

def duplicate_character(name, x_offset):
    bpy.ops.object.select_all(action='DESELECT')
    armature_obj.select_set(True)
    for m in mesh_objs:
        m.select_set(True)
    if weapon_obj:
        weapon_obj.select_set(True)
    bpy.context.view_layer.objects.active = armature_obj
    bpy.ops.object.duplicate()
    
    new_arm = bpy.context.active_object
    new_arm.name = f"Armature_{name}"
    new_arm.location.x = x_offset
    return new_arm

arm_hover = duplicate_character("01_Hover_LowSpeed", -2.2)
arm_cruise = duplicate_character("02_Cruise_MidSpeed", 0.0)
arm_boost = duplicate_character("03_Boost_HighSpeed", 2.2)

armature_obj.hide_viewport = True
armature_obj.hide_render = True
for m in mesh_objs:
    m.hide_viewport = True
    m.hide_render = True
if weapon_obj:
    weapon_obj.hide_viewport = True
    weapon_obj.hide_render = True

def adjust_flight_pose(arm_obj, lean_angle_deg, arm_reach_deg, pitch_foot_deg):
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='POSE')
    
    for bone_name in ["Bip001 Spine", "Bip001 Spine1", "Bip001 Spine2", "Bip001"]:
        if bone_name in arm_obj.pose.bones:
            pbone = arm_obj.pose.bones[bone_name]
            pbone.rotation_mode = 'XYZ'
            pbone.rotation_euler.x += math.radians(lean_angle_deg * 0.4)
            
    for bone_name in ["Bip001 R UpperArm", "Bip001 R Forearm"]:
        if bone_name in arm_obj.pose.bones:
            pbone = arm_obj.pose.bones[bone_name]
            pbone.rotation_mode = 'XYZ'
            pbone.rotation_euler.y += math.radians(arm_reach_deg * 0.5)
            
    for bone_name in ["Bip001 L Foot", "Bip001 R Foot"]:
        if bone_name in arm_obj.pose.bones:
            pbone = arm_obj.pose.bones[bone_name]
            pbone.rotation_mode = 'XYZ'
            pbone.rotation_euler.x += math.radians(pitch_foot_deg)
            
    bpy.ops.object.mode_set(mode='OBJECT')

adjust_flight_pose(arm_hover, 5.0, 0.0, -5.0)
adjust_flight_pose(arm_cruise, 18.0, 20.0, -15.0)
adjust_flight_pose(arm_boost, 35.0, 45.0, -30.0)

directions = [
    {"id": "01_right",      "angle": 0,   "pitch": 22},
    {"id": "02_up_right",   "angle": 45,  "pitch": 45},
    {"id": "03_up",         "angle": 90,  "pitch": 50},
    {"id": "04_up_left",    "angle": 135, "pitch": 45},
    {"id": "05_left",       "angle": 180, "pitch": 22},
    {"id": "06_down_left",  "angle": 225, "pitch": 45},
    {"id": "07_down",       "angle": 270, "pitch": 45},
    {"id": "08_down_right", "angle": 315, "pitch": 45},
]

cam_objs = []
cam_dist = 7.5

for d in directions:
    cam_data = bpy.data.cameras.new(name=f"CameraData_{d['id']}")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = 6.5
    
    cam_obj = bpy.data.objects.new(name=f"Cam_{d['id']}", object_data=cam_data)
    bpy.context.collection.objects.link(cam_obj)
    
    yaw_rad = math.radians(d['angle'] - 90)
    pitch_rad = math.radians(d['pitch'])
    
    x = cam_dist * math.cos(pitch_rad) * math.cos(yaw_rad)
    y = cam_dist * math.cos(pitch_rad) * math.sin(yaw_rad)
    z = cam_dist * math.sin(pitch_rad) + 1.0
    
    cam_obj.location = (x, y, z)
    
    rot_x = math.radians(90 - d['pitch'])
    rot_z = math.radians(d['angle'] + 90)
    cam_obj.rotation_euler = (rot_x, 0, rot_z)
    
    cam_objs.append(cam_obj)

bpy.context.scene.camera = cam_objs[0]

light_data = bpy.data.lights.new(name="Sun_KeyLight", type='SUN')
light_data.energy = 2.5
light_data.color = (1.0, 0.98, 0.95)
light_obj = bpy.data.objects.new(name="Sun_KeyLight", object_data=light_data)
light_obj.rotation_euler = (math.radians(45), math.radians(15), math.radians(45))
bpy.context.collection.objects.link(light_obj)

fill_data = bpy.data.lights.new(name="Sun_FillLight", type='SUN')
fill_data.energy = 1.0
fill_data.color = (0.75, 0.88, 1.0)
fill_obj = bpy.data.objects.new(name="Sun_FillLight", object_data=fill_data)
fill_obj.rotation_euler = (math.radians(-30), math.radians(-30), math.radians(-135))
bpy.context.collection.objects.link(fill_obj)

bpy.context.scene.render.film_transparent = True
bpy.context.scene.render.resolution_x = 960
bpy.context.scene.render.resolution_y = 540

for i, d in enumerate(directions):
    cam = cam_objs[i]
    bpy.context.scene.camera = cam
    render_filepath = os.path.join(output_dir, f"zhanyan_3speeds_{d['id']}.png")
    bpy.context.scene.render.filepath = render_filepath
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {render_filepath}")

bpy.ops.wm.save_as_mainfile(filepath=blend_save_path)
print(f"=== BLEND SAVED SUCCESSFULLY: {blend_save_path} ===")
