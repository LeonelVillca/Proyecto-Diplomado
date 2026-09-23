import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { tap } from 'rxjs';
import { DataSource } from 'typeorm';

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  private readonly logger = new Logger('SecurityAudit');

  constructor(private readonly dataSource: DataSource) {}

  intercept(context: ExecutionContext, next: CallHandler) {
    if (context.getType() !== 'http') return next.handle();
    const request = context.switchToHttp().getRequest();
    const response = context.switchToHttp().getResponse();
    if (!['POST', 'PATCH', 'PUT', 'DELETE'].includes(request.method))
      return next.handle();
    // Nunca guardar body, query, cabeceras, correo, PIN ni tokens.
    const record = (outcome: string, statusCode: number) => {
      const audit = {
        action: request.method,
        route: request.route?.path ?? 'unknown',
        actor: request.user?.id ?? null,
        resourceId: request.params?.id ? String(request.params.id) : null,
        outcome,
        statusCode,
        time: new Date().toISOString(),
      };
      this.logger.log(JSON.stringify(audit));
      void this.dataSource
        .query(
          `INSERT INTO auditoria_evento
             (id_usuario, accion, ruta, id_recurso, resultado, codigo_estado)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [
            audit.actor,
            audit.action,
            audit.route,
            audit.resourceId,
            audit.outcome,
            audit.statusCode,
          ],
        )
        .catch((error: unknown) =>
          this.logger.error(
            `No se pudo persistir auditoría: ${error instanceof Error ? error.message : String(error)}`,
          ),
        );
    };
    return next.handle().pipe(
      tap({
        next: () => record('success', response.statusCode),
        error: (error) => record('failure', error?.getStatus?.() ?? 500),
      }),
    );
  }
}
