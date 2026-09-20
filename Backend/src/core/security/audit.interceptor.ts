import { CallHandler, ExecutionContext, Injectable, Logger, NestInterceptor } from '@nestjs/common';
import { tap } from 'rxjs';

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  private readonly logger = new Logger('SecurityAudit');
  intercept(context: ExecutionContext, next: CallHandler) {
    if (context.getType() !== 'http') return next.handle();
    const request = context.switchToHttp().getRequest();
    const response = context.switchToHttp().getResponse();
    if (!['POST', 'PATCH', 'PUT', 'DELETE'].includes(request.method)) return next.handle();
    // Nunca guardar body, query, cabeceras, correo, PIN ni tokens.
    const record = (outcome: string, statusCode: number) => this.logger.log(JSON.stringify({
      action: request.method, route: request.route?.path ?? 'unknown',
      actor: request.user?.id ?? null, outcome, statusCode, time: new Date().toISOString(),
    }));
    return next.handle().pipe(tap({
      next: () => record('success', response.statusCode),
      error: (error) => record('failure', error?.getStatus?.() ?? 500),
    }));
  }
}
