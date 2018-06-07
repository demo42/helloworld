ARG REGISTRY_NAME=demo42.azurecr.io/
FROM ${REGISTRY_NAME}baseimages/node:9-alpine
COPY . /src
RUN cd /src && npm install
EXPOSE 80
CMD ["node", "/src/server.js"]
