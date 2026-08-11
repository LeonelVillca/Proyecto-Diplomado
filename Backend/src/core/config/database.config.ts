import { registerAs } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export default registerAs('database', (): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: process.env.DB_HOST ?? 'localhost',
  port: parseInt(process.env.DB_PORT ?? '5432', 10),
  username: process.env.DB_USER ?? 'postgres',
  password: process.env.DB_PASSWORD ?? '12345',
  database: process.env.DB_NAME ?? 'restaurantes_tarija',
  entities: [__dirname + '/../../**/*.entity.{ts,js}'],
  autoLoadEntities: true,
  synchronize: false,
  retryAttempts: 3,
  retryDelay: 3000,
}));
