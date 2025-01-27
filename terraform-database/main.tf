

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      BatchID = "DevOps"
    }
  }
}

# DynamoDb Provisioning
resource "aws_dynamodb_table" "marketing" {
  name         = var.dynamodb_table_name # If spinning up multiple stacks, you will want to change this to simply be a prefix
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Brand"

  attribute {
    name = "Brand"
    type = "S"
  }
}

# The following are populating the table with some default data.
resource "aws_dynamodb_table_item" "item1" {
  table_name = aws_dynamodb_table.marketing.name
  hash_key   = aws_dynamodb_table.marketing.hash_key
  item       = <<ITEM
{
  "Brand": { "S": "Apple" },
  "ServicesProvided": { "S": "Social Media Campaigns, Content Creation" },
  "ProjectDescription": { "S": "Developed and managed social media campaigns for the launch of the new iPhone." }
}
ITEM
}

resource "aws_dynamodb_table_item" "item2" {
  table_name = aws_dynamodb_table.marketing.name
  hash_key   = aws_dynamodb_table.marketing.hash_key
  item       = <<ITEM
{
  "Brand": { "S": "Nike" },
  "ServicesProvided": { "S": "Influencer Marketing, Event Management" },
  "ProjectDescription": { "S": "Coordinated influencer partnerships and managed the global Nike Run events." }
}
ITEM
}

resource "aws_dynamodb_table_item" "item3" {
  table_name = aws_dynamodb_table.marketing.name
  hash_key   = aws_dynamodb_table.marketing.hash_key
  item       = <<ITEM
{
  "Brand": { "S": "Coca-Cola" },
  "ServicesProvided": { "S": "Brand Strategy, Digital Advertising" },
  "ProjectDescription": { "S": "Revamped the brand strategy and executed digital ad campaigns for the summer season." }
}
ITEM
}

resource "aws_dynamodb_table_item" "item4" {
  table_name = aws_dynamodb_table.marketing.name
  hash_key   = aws_dynamodb_table.marketing.hash_key
  item       = <<ITEM
{
  "Brand": { "S": "Samsung" },
  "ServicesProvided": { "S": "SEO Optimization, Email Marketing" },
  "ProjectDescription": { "S": "Enhanced SEO strategies and launched targeted email marketing campaigns for the Galaxy series." }
}
ITEM
}

resource "aws_dynamodb_table_item" "item5" {
  table_name = aws_dynamodb_table.marketing.name
  hash_key   = aws_dynamodb_table.marketing.hash_key
  item       = <<ITEM
{
  "Brand": { "S": "Starbucks" },
  "ServicesProvided": { "S": "Content Marketing, Social Media Management" },
  "ProjectDescription": { "S": "Created engaging content and managed social media channels to increase brand engagement." }
}
ITEM
}

resource "aws_dynamodb_table_item" "item6" {
  table_name = aws_dynamodb_table.marketing.name
  hash_key   = aws_dynamodb_table.marketing.hash_key
  item       = <<ITEM
{
  "Brand": { "S": "Hyundai" },
  "ServicesProvided": { "S": "Video Production, PR Campaigns" },
  "ProjectDescription": { "S": "Produced high-impact videos and orchestrated PR campaigns for the Model 3 launch." }
}
ITEM
}

resource "aws_dynamodb_table_item" "item7" {
  table_name = aws_dynamodb_table.marketing.name
  hash_key   = aws_dynamodb_table.marketing.hash_key
  item       = <<ITEM
{
  "Brand": { "S": "Microsoft" },
  "ServicesProvided": { "S": "Web Development, PPC Advertising" },
  "ProjectDescription": { "S": "Developed microsites and managed pay-per-click advertising for the Surface lineup." }
}
ITEM
}