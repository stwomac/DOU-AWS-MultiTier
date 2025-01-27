import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
// import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const trustedOrigins = (process.env.TRUSTED_ORIGINS || '').split(',').map(origin => origin.trim());
  app.enableCors({origin: '*'});
  await app.listen(process.env.PORT ?? 3000, '0.0.0.0');
}
bootstrap();
