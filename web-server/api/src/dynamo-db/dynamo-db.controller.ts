import { Controller, Get, Param, Post, Body } from '@nestjs/common';
import { DynamoDBService } from 'src/dynamo-db/dynamo-db.service';

@Controller('dynamodb')
export class DynamoDbController {
  constructor(private readonly dynamoDbService: DynamoDBService) {}

  @Get('all')
  async getAll() {
    const items = await this.dynamoDbService.getAllItems();
    return { data: items };
  }
  
  @Get(':id')
  async getItem(@Param('id') id: string) {
    const item = await this.dynamoDbService.getItemById(id);
    return { data: item };
  }

}