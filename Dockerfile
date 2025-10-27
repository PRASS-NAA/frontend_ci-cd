FROM node:alpine AS build

WORKDIR /frontendApp

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

FROM nginx:alpine

COPY --from=build /frontendApp/build /usr/share/nginx/html

EXPOSE 80
