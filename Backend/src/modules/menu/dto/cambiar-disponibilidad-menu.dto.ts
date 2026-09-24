import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class CambiarDisponibilidadMenuDto {
  @ApiProperty({ type: Boolean })
  @IsBoolean()
  disponibilidad: boolean;
}
