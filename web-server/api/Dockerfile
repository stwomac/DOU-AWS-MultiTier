#last version i can tell that doesnt cause issues with installing nest at the same time in a container, lts will lead to nest hang
FROM node:22.4.0-alpine
#ENV NODE_ENV=production
WORKDIR /usr/src/app
COPY ["package.json", "package-lock.json*", "npm-shrinkwrap.json*", "./"]
RUN echo "npm install"
RUN npm install 
RUN echo "nest install"
RUN npm install -g @nestjs/cli
RUN echo "moving modules"  
RUN mv node_modules ../ 
COPY . .
EXPOSE 3000
# USER node
CMD ["npm", "start"]