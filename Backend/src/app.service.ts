import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { DataSource } from 'typeorm';

@Injectable()
export class AppService {
  constructor(private readonly dataSource: DataSource) {}

  getHello(): string {
    return 'Hello World!';
  }

  async comprobarSalud() {
    try {
      await this.dataSource.query('SELECT 1');
      return { estado: 'ok', baseDatos: 'conectada' };
    } catch {
      throw new ServiceUnavailableException({
        estado: 'error',
        baseDatos: 'no disponible',
      });
    }
  }
}
