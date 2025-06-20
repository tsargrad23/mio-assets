import os

def detect_shader_type(text):
    lower = text.lower()
    if "gl_fragcolor" in lower or "gl_fragcoord" in lower or "out vec4" in lower:
        return "fsh"
    elif "gl_position" in lower or "in vec3" in lower or "in vec2" in lower:
        return "vsh"
    else:
        return "glsl"

def detect_file_type(filepath):
    with open(filepath, 'rb') as f:
        header = f.read(40)
        if header.startswith(b'\x89PNG'):
            return 'png'
        elif header.startswith(b'OggS'):
            return 'ogg'
        elif header.strip().startswith(b'{') or header.strip().startswith(b'['):
            return 'json'
        elif header.startswith(b'#version'):
            f.seek(0)
            text = f.read().decode(errors='ignore')
            return detect_shader_type(text)
        else:
            return None

for filename in os.listdir('.'):
    if filename.endswith('.bin'):
        ftype = detect_file_type(filename)
        if ftype:
            new_name = filename.replace('.bin', f'.{ftype}')
            os.rename(filename, new_name)
            print(f"{filename} → {new_name}")
        else:
            print(f"{filename} türü belirlenemedi.")
