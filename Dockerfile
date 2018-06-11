ARG REGISTRY_NAME=demo42.azurecr.io/
FROM stevelasker/node:9-alpine
EXPOSE 80
COPY . /src 
RUN cd /src && npm install
CMD ["node", "/src/server.js"]
