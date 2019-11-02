ARG ACR_NAME=demo42t
FROM ${ACR_NAME}.azurecr.io/base-images/node:9-alpine
EXPOSE 80
COPY . /src 
RUN cd /src && npm install
CMD ["node", "/src/server.js"]
