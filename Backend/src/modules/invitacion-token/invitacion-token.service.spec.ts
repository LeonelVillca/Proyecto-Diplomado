import { Test, TestingModule } from '@nestjs/testing';
import { InvitacionTokenService } from './invitacion-token.service';

describe('InvitacionTokenService', () => {
  let service: InvitacionTokenService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [InvitacionTokenService],
    }).compile();

    service = module.get<InvitacionTokenService>(InvitacionTokenService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
