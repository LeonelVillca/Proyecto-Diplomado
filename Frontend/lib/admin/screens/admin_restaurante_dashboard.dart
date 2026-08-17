import 'package:flutter/material.dart';
import '../../movil/providers/auth_provider.dart';
import 'gestion_menus_screen.dart';
import 'gestion_mesas_screen.dart';
import 'gestion_reservas_screen.dart';
import 'gestion_resenas_screen.dart';
import 'perfil_restaurante_screen.dart';
import 'admin_restaurante/soporte_restaurante_screen.dart';
import 'admin_restaurante/reportes_restaurante_screen.dart';

class AdminRestauranteDashboard extends StatefulWidget {
  const AdminRestauranteDashboard({super.key});

  @override
  State<AdminRestauranteDashboard> createState() => _AdminRestauranteDashboardState();
}

class _AdminRestauranteDashboardState extends State<AdminRestauranteDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PerfilRestauranteScreen(),
    const GestionMesasScreen(),
    const GestionMenusScreen(),
    const Center(child: Text('Promociones (F4)', style: TextStyle(fontSize: 24, fontFamily: 'Karla'))),
    const GestionReservasScreen(),
    const GestionResenasScreen(),
    const SoporteRestauranteScreen(),
    const ReportesRestauranteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthScope.of(context);
    final nombre = authProvider.displayName ?? 'Restaurantero';
    final correo = authProvider.email ?? 'restaurante@mesachapaca.com';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_outlined, color: Color(0xFF6B1A35), size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Mesa Chapaca',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BodoniModa',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'NEGOCIO',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontFamily: 'Karla'),
                  ),
                ),
                _buildSidebarItem(Icons.restaurant_outlined, 'Perfil', 0),
                _buildSidebarItem(Icons.table_restaurant_outlined, 'Mesas', 1),
                _buildSidebarItem(Icons.menu_book_outlined, 'Menús', 2),
                _buildSidebarItem(Icons.local_offer_outlined, 'Promociones', 3),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'OPERACIÓN',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontFamily: 'Karla'),
                  ),
                ),
                _buildSidebarItem(Icons.calendar_month_outlined, 'Reservas', 4),
                _buildSidebarItem(Icons.star_outline, 'Reseñas', 5),
                _buildSidebarItem(Icons.support_agent_outlined, 'Soporte', 6),
                _buildSidebarItem(Icons.bar_chart_outlined, 'Reportes', 7),
                const Spacer(),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                _buildSidebarItem(Icons.logout, 'Cerrar Sesión', -1, isDanger: true),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Navbar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Panel de Restaurante',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Karla', color: Colors.black87),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B1A35).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Admin Restaurante',
                          style: TextStyle(color: Color(0xFF6B1A35), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Karla'),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Badge(child: Icon(Icons.notifications_outlined, color: Colors.black54)),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 16),
                      PopupMenuButton<String>(
                        offset: const Offset(0, 50),
                        tooltip: 'Perfil',
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'logout') AuthScope.of(context).signOut();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Karla', fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(correo, style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 13)),
                                const SizedBox(height: 8),
                                const Divider(),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 20, color: Colors.redAccent),
                                SizedBox(width: 12),
                                Text('Cerrar Sesión', style: TextStyle(fontFamily: 'Karla', color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF6B1A35),
                              radius: 18,
                              child: Text(nombre[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: _screens[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index, {bool isDanger = false}) {
    final isSelected = _selectedIndex == index;
    final color = isDanger ? Colors.redAccent : (isSelected ? const Color(0xFF6B1A35) : Colors.grey.shade700);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          if (index == -1) {
            AuthScope.of(context).signOut();
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6B1A35).withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'Karla',
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
