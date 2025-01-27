import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
// V3 client
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
// Document Client wrapper to work with JSON directly
import { DynamoDBDocumentClient, GetCommand, ScanCommand } from '@aws-sdk/lib-dynamodb';


@Injectable()
export class DynamoDBService {
    private readonly docClient: DynamoDBDocumentClient;

    //private readonly tableName = 'Womack-Marketing';

    //get the name of the dynamodb table from .env
    private readonly tableName = this.configService.get<string>('TABLE_NAME', 'Womack-Marketing');

    constructor(private configService: ConfigService) {
        // Retrieve config from environment or config service
        const region = this.configService.get<string>('AWS_REGION', 'us-east-1');

        // if not setting a iam role for the instances this is required
        // const accessKeyId = this.configService.get<string>('AWS_ACCESS_KEY_ID');
        // const secretAccessKey = this.configService.get<string>('AWS_SECRET_ACCESS_KEY');
        // const sessionToken = this.configService.get<string>('AWS_SESSION_TOKEN');
    

        const ddbClient = new DynamoDBClient({ 
            region: region,
            // credentials: {
            //     accessKeyId,
            //     secretAccessKey,
            //     sessionToken
            //   } 
        
        });
    
        // Wrap DynamoDbClient with the DocumentClient for easier JSON handling
        this.docClient = DynamoDBDocumentClient.from(ddbClient);
    }

    // recieves a singular table item from the dynamo table
    async getItemById(id: string) {
        const params = {
          TableName: this.tableName,
          Key: {
            Brand: id, 
          },
        };
        
        const result = await this.docClient.send(new GetCommand(params));
        return result.Item;
      }

      // recieves all items in the dynamodb table
      async getAllItems() {
        const params = {
          TableName: this.tableName,
        };
    
        //the collection of items
        const allItems: any[] = [];

        // intializes as undefined, otherwise holds the record of a item in the table
        let lastEvaluatedKey: Record<string, any> | undefined = undefined;
    
        do {
          if (lastEvaluatedKey) {
            params['ExclusiveStartKey'] = lastEvaluatedKey;
          }
    
          const result = await this.docClient.send(new ScanCommand(params));
          if (result.Items) {
            allItems.push(...result.Items);
          }
    
          // If LastEvaluatedKey is set, there are more items to be scanned
          lastEvaluatedKey = result.LastEvaluatedKey;
        } while (lastEvaluatedKey);
    
        return allItems;
      }
}