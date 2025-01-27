# AWS Multi-Tier Website
---
## Diagram of Architecture
![AWS Multi-tier](https://github.com/user-attachments/assets/9a8f236a-9897-4009-994a-151d93b97e58)
---
## Required Installs
- Terraform
- Docker
---
## Required .env
You will need to create a .env at web-server\api\src\\.env, 
inside it will need two variables
- TABLE_NAME="insert dynamo-db table name here"
- AWS_REGION="us-east-1"
---
## Setup
### Please Note:
Due to specific environment and cost requirements, there is no static domain for the backend api, nor is there a golden ami allowed for the ec2 instances. As such when wanting to run this in your own environment you will want to do several things.
1. Firstly you will want to push images of the backend and frontend to dockerhub with your own accounts
2. You will want to edit the names of the images in the variables IMAGE_NAME_1 (the backend image) and IMAGE_NAME_2 (the frontend image) located at terraform-main-stack\user-data.sh
3. You will also want to edit the names of the images located in the docker compose file at web-server\docker-compose.yml
4. The location of the front-end api url is at web-server\frontend\src\app\services\dynamodb.service.ts since the url is dynamic and tied to the load balancer, you will need to edit the apiUrl variable, then docker compose build and docker compose push the images as the terraform mainstack apply is finishing. You will have a window of 3-5 minutes to do so from when the load balancer begins provisioning to when the user-data script gets to the section where it pulls the images. This can be increased in terraform-main-stack\user-data.sh by adjusting the sleep time on line 46.

### Order of Setup:
1. Run terraform apply in the terraform-database directory
2. Run terraform apply in the terraform-main-stack directory perform steps 3-5 concurrently with this step
3. Edit web-server\frontend\src\app\services\dynamodb.service.ts with the load balancer's DNS name.
4. Run docker compose build in web-server\
5. Run docker compose push in web-server\
6. It will take around 12 minutes after 2 finishes for the user-data script to finish, afterwards you may go to your load balancer's url to access the website.
---
All development was done on a Windows Machine, as such some edits may be required to match your environment.
