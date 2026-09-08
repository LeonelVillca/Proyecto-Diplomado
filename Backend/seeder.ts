import { DataSource } from 'typeorm';
import { fakerES as faker } from '@faker-js/faker';
import * as bcrypt from 'bcryptjs';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import * as dotenv from 'dotenv';

// Cargar variables de entorno antes de la configuración
dotenv.config();

// Importar entidades con rutas correctas
import { Usuario } from './src/modules/usuarios/usuario.entity';
import { CuentaAuth } from './src/modules/cuentas-auth/cuenta-auth.entity';
import { Rol } from './src/modules/rol/rol.entity';
import { UsuarioRol } from './src/modules/usuario-rol/usuario-rol.entity';
import { Restaurante } from './src/modules/restaurante/restaurante.entity';
import { Ubicacion } from './src/modules/ubicacion/ubicacion.entity';
import { Mesa } from './src/modules/mesa/mesa.entity';
import { HorarioAtencion } from './src/modules/horario-atencion/horario-atencion.entity';
import { Menu } from './src/modules/menu/menu.entity';
import { Plato } from './src/modules/plato/plato.entity';

async function runSeeder() {
  console.log('Iniciando Seeding Masivo...');

  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '12345',
    database: process.env.DB_NAME || 'restaurantes_tarija',
    entities: [__dirname + '/src/**/*.entity.{ts,js}'],
    synchronize: false,
  });

  await dataSource.initialize();
  const restauranteRepo = dataSource.getRepository(Restaurante);
  const usuarioRepo = dataSource.getRepository(Usuario);
  const cuentaAuthRepo = dataSource.getRepository(CuentaAuth);
  const rolRepo = dataSource.getRepository(Rol);
  const usuarioRolRepo = dataSource.getRepository(UsuarioRol);
  const ubicacionRepo = dataSource.getRepository(Ubicacion);
  const mesaRepo = dataSource.getRepository(Mesa);
  const horarioRepo = dataSource.getRepository(HorarioAtencion);
  const menuRepo = dataSource.getRepository(Menu);
  const platoRepo = dataSource.getRepository(Plato);

  console.log('Limpiando base de datos...');
  await dataSource.query(`TRUNCATE TABLE plato, menu, horario_atencion, mesa, ubicacion, restaurante, cuentas_auth, usuario_rol, usuarios, rol RESTART IDENTITY CASCADE;`);

  // Rutas de origen
  const rutaBaseOrigen = path.join(os.homedir(), 'OneDrive', 'Desktop', 'imgenes de prueba');
  
  // Limpiar el storage anterior si se quiere hacer bien (opcional)
  const baseStorage = path.join(process.cwd(), 'storage', 'publico', 'restaurantes');
  if (fs.existsSync(baseStorage)) {
    fs.rmSync(baseStorage, { recursive: true, force: true });
  }

  console.log('Leyendo imágenes desde:', rutaBaseOrigen);
  
  let archivosLogos: string[] = [];
  let archivosRestaurantes: string[] = [];
  let archivosPlatos: string[] = [];
  
  try {
    archivosLogos = fs.readdirSync(path.join(rutaBaseOrigen, 'logos')).filter(f => f.match(/\.(jpg|jpeg|png|webp)$/i)); 
    archivosRestaurantes = fs.readdirSync(path.join(rutaBaseOrigen, 'restaurantes')).filter(f => f.match(/\.(jpg|jpeg|png|webp)$/i));
    archivosPlatos = fs.readdirSync(path.join(rutaBaseOrigen, 'platos')).filter(f => f.match(/\.(jpg|jpeg|png|webp)$/i));
  } catch (err: any) {
    console.warn('Advertencia: No se encontraron las carpetas de imágenes en OneDrive.', err.message);
  }

  // Preparar Rol y Auth
  let adminRol = await rolRepo.findOneBy({ nombre: 'admin_restaurante' });
  if (!adminRol) adminRol = await rolRepo.save(rolRepo.create({ nombre: 'admin_restaurante' }));
  
  let superAdminRol = await rolRepo.findOneBy({ nombre: 'admin_sistema' });
  if (!superAdminRol) superAdminRol = await rolRepo.save(rolRepo.create({ nombre: 'admin_sistema' }));

  const defaultPasswordHash = await bcrypt.hash('MesaChapaca2026!', 10);
  const reporteCredenciales = ["=== CREDENCIALES ===\nPass Global: MesaChapaca2026!\n"];
  
  // Crear Super Admin
  const superAdminPasswordHash = await bcrypt.hash('admin123', 10);
  const superUsuario = await usuarioRepo.save(usuarioRepo.create({ 
    nombre: 'Leonel', 
    apellido: 'Villca', 
    correo: 'admin@mesachapaca.com', 
    telefono: '77777777', 
    estado: 'activo' 
  }));

  await cuentaAuthRepo.save(cuentaAuthRepo.create({ 
    usuario: superUsuario, 
    passwordHash: superAdminPasswordHash, 
    estado: true 
  }));
  
  await usuarioRolRepo.save(usuarioRolRepo.create({ 
    idUsuario: superUsuario.id, 
    idRol: superAdminRol.id 
  }));
  
  reporteCredenciales.push(`=== SUPER ADMIN ===\nEmail: admin@mesachapaca.com\nPass: admin123\n`);
  
  console.log('Generando datos...');
  for (let i = 0; i < 20; i++) {
    const nombreRest = faker.company.name() + ' Restaurant';
    const correo = `restaurante${i + 1}@mesachapaca.com`;
    const telefonoFake = faker.phone.number().substring(0, 20);

    const usuario = await usuarioRepo.save(usuarioRepo.create({ 
      nombre: faker.person.firstName(), 
      apellido: faker.person.lastName(), 
      correo, 
      telefono: telefonoFake, 
      estado: 'activo' 
    }));

    await cuentaAuthRepo.save(cuentaAuthRepo.create({ 
      usuario, 
      passwordHash: defaultPasswordHash, 
      estado: true 
    }));
    
    await usuarioRolRepo.save(usuarioRolRepo.create({ 
      idUsuario: usuario.id, 
      idRol: adminRol.id 
    }));
    
    reporteCredenciales.push(`Rest: ${nombreRest} | Email: ${correo}`);

    // Primero creamos el restaurante sin fotos para obtener su ID
    let restaurante = await restauranteRepo.save(restauranteRepo.create({
      nombre: nombreRest, 
      tipoComida: 'Comida Tradicional', 
      descripcion: faker.lorem.paragraph(2).substring(0, 255),
      telefono: telefonoFake, 
      correo, 
      estado: true
    }));

    // Ahora copiamos las fotos al storage estructurado con el ID
    const restStoragePath = path.join(baseStorage, restaurante.id.toString());
    
    let logoUrl: string | null = null;
    if (archivosLogos.length > 0) {
      const logoSel = archivosLogos[i % archivosLogos.length];
      const destFolder = path.join(restStoragePath, 'logo');
      fs.mkdirSync(destFolder, { recursive: true });
      fs.copyFileSync(path.join(rutaBaseOrigen, 'logos', logoSel), path.join(destFolder, logoSel));
      logoUrl = `/publico/restaurantes/${restaurante.id}/logo/${logoSel}`;
    }

    let portadaUrl: string | null = null;
    if (archivosRestaurantes.length > 0) {
      const portadaSel = faker.helpers.arrayElement(archivosRestaurantes);
      const destFolder = path.join(restStoragePath, 'portada');
      fs.mkdirSync(destFolder, { recursive: true });
      fs.copyFileSync(path.join(rutaBaseOrigen, 'restaurantes', portadaSel), path.join(destFolder, portadaSel));
      portadaUrl = `/publico/restaurantes/${restaurante.id}/portada/${portadaSel}`;
    }

    // Actualizamos el restaurante con las URLs finales
    if (logoUrl || portadaUrl) {
      restaurante.logo = logoUrl;
      restaurante.fotoPortada = portadaUrl;
      await restauranteRepo.save(restaurante);
    }

    await ubicacionRepo.save(ubicacionRepo.create({ 
      latitud: faker.location.latitude({ max: -21.50, min: -21.56 }), 
      longitud: faker.location.longitude({ max: -64.70, min: -64.76 }), 
      restaurante 
    }));
    
    for (let m = 1; m <= 10; m++) {
      await mesaRepo.save(mesaRepo.create({ 
        numeroMesa: `Mesa ${m}`, 
        capacidad: faker.number.int({ min: 2, max: 8 }), 
        estado: 'libre', 
        restaurante 
      }));
    }
    
    for (let dia = 1; dia <= 7; dia++) {
      await horarioRepo.save(horarioRepo.create({ 
        diaSemana: dia, 
        horaInicio: '09:00:00', 
        horaFin: '22:00:00', 
        restaurante 
      }));
    }

    const menu = await menuRepo.save(menuRepo.create({ 
      nombre: 'Menú General', 
      tipo: 'Platos Principales', 
      disponibilidad: true, 
      restaurante 
    }));
    
    const platosSel = archivosPlatos.length > 0 ? faker.helpers.shuffle([...archivosPlatos]).slice(0, 8) : [];

    if (platosSel.length > 0) {
      for (const archivoPlato of platosSel) {
        const destFolder = path.join(restStoragePath, 'platos');
        fs.mkdirSync(destFolder, { recursive: true });
        fs.copyFileSync(path.join(rutaBaseOrigen, 'platos', archivoPlato), path.join(destFolder, archivoPlato));
        
        let nombrePlato = archivoPlato.substring(0, archivoPlato.lastIndexOf('.')).replace(/[-_]/g, ' ');
        nombrePlato = nombrePlato.charAt(0).toUpperCase() + nombrePlato.slice(1);
  
        await platoRepo.save(platoRepo.create({ 
          nombre: nombrePlato, 
          descripcion: faker.food.description(), 
          precio: parseFloat(faker.commerce.price({ min: 15, max: 80 })), 
          fotoUrl: `/publico/restaurantes/${restaurante.id}/platos/${archivoPlato}`, 
          disponible: true, 
          menu 
        }));
      }
    } else {
      for (let p = 1; p <= 8; p++) {
        await platoRepo.save(platoRepo.create({
          nombre: `Plato Tradicional ${p}`,
          descripcion: faker.food.description(),
          precio: parseFloat(faker.commerce.price({ min: 15, max: 80 })),
          disponible: true,
          menu
        }));
      }
    }
  }

  fs.writeFileSync(path.join(__dirname, 'credenciales_prueba.txt'), reporteCredenciales.join('\n'));
  console.log('Seeding exitoso. Revisa credenciales_prueba.txt');
  await dataSource.destroy();
}

runSeeder().catch(err => { 
  console.error('Error fatal en el seeder:', err); 
  process.exit(1); 
});
