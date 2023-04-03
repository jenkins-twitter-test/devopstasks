FROM node:16-alpine AS nodeapi-build
WORKDIR /app
COPY ./src /app
RUN npm install

FROM node:16-alpine
WORKDIR /app
COPY --from=nodeapi-build /app ./
ENTRYPOINT [ "npm" ]
CMD ["run" , "dev"] 