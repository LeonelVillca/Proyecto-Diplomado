part of '../../../screens/admin/perfil/perfil_restaurante_screen.dart';

extension _SelectorTiposComida on _PerfilRestauranteScreenState {
  Widget _buildTiposComidaSelector() {
    if (_catalogoTiposComida.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('No se pudieron cargar los tipos de comida.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tipos de comida',
            style: AdminTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: AdminTheme.textDark,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Puedes elegir varios para que aparezcan en los filtros.',
            style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _catalogoTiposComida.map((tipo) {
            final id = int.tryParse(tipo['id']?.toString() ?? '');
            if (id == null) return const SizedBox.shrink();
            final selected = _tiposComidaSeleccionados.contains(id);
            return FilterChip(
              label: Text(tipo['nombre']?.toString() ?? ''),
              selected: selected,
              showCheckmark: true,
              checkmarkColor: AdminTheme.primaryDark,
              selectedColor: AdminTheme.primaryLight,
              backgroundColor: Colors.white,
              labelStyle: AdminTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? AdminTheme.primaryDark : AdminTheme.textMuted,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected ? AdminTheme.primaryColor : AdminTheme.border,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
              onSelected: (value) => setState(() {
                _isDirty = true;
                if (value) {
                  if (tipo['slug'] != 'por-definir') {
                    _tiposComidaSeleccionados.removeWhere(
                      (selectedId) => _catalogoTiposComida.any(
                        (entry) =>
                            entry['id'] == selectedId &&
                            entry['slug'] == 'por-definir',
                      ),
                    );
                  } else {
                    _tiposComidaSeleccionados.clear();
                  }
                  _tiposComidaSeleccionados.add(id);
                } else {
                  _tiposComidaSeleccionados.remove(id);
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class SelectorTiposComidaPerfil extends StatelessWidget {
  const SelectorTiposComidaPerfil({super.key, required this.pantalla});
  final _PerfilRestauranteScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildTiposComidaSelector();
}
