import os

def fix_dollars(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content.replace('\\$', '$')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)

files = [
    'd:/Proyecto_Diplomado/Frontend/lib/admin/services/menu_admin_service.dart',
    'd:/Proyecto_Diplomado/Frontend/lib/admin/screens/menus/gestion_menus_screen.dart',
    'd:/Proyecto_Diplomado/Frontend/lib/admin/screens/menus/formulario_menu_screen.dart',
    'd:/Proyecto_Diplomado/Frontend/lib/admin/screens/menus/detalles_menu_screen.dart'
]

for file in files:
    if os.path.exists(file):
        fix_dollars(file)
