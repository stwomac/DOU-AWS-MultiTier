import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DynamoDbController } from 'src/dynamo-db/dynamo-db.controller';
import { DynamoDBService } from 'src/dynamo-db/dynamo-db.service';

@Module({
    imports: [ConfigModule],
    controllers: [DynamoDbController],
    providers: [DynamoDBService],
    exports: [DynamoDBService]
})
export class DynamoDbModule {}
