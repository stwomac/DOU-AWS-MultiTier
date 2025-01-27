import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { DynamoDbModule } from './dynamo-db/dynamo-db.module';

@Module({
  imports: [
    
    ConfigModule.forRoot({
      isGlobal: true, // makes ConfigService available across the entire app without importing in every module
      envFilePath: 'C:\\Users\\stwom\\Documents\\repos\\skillstorm\\dev-ops\\DOU-AWS-MultiTier\\web-server\\api\\src\\.env', // path to your .env file
    }),
    DynamoDbModule  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
