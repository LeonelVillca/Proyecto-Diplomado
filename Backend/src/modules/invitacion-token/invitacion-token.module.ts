import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InvitacionTokenService } from './invitacion-token.service';
import { InvitacionToken } from './invitacion-token.entity';

@Module({
  imports: [TypeOrmModule.forFeature([InvitacionToken])],
  providers: [InvitacionTokenService],
  exports: [InvitacionTokenService],
})
export class InvitacionTokenModule {}
