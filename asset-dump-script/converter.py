import os

def detect_file_type(filepath):
    with open(filepath, 'rb') as f:
        header = f.read(10)
        if header.startswith(b'\x89PNG'):
            return 'png'
        elif header.startswith(b'OggS'):
            return 'ogg'
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
