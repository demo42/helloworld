ARG REGISTRY_NAME=jengademos.azurecr.io/
FROM ${REGISTRY_NAME}baseimages/node:9
COPY . /src
RUN cd /src && npm install
ENV foo=bar
EXPOSE 80
CMD ["node", "/src/server.js"]
