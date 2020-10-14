# Stage 1 - install node dependencies
FROM node:12.4.0-alpine as build-deps
WORKDIR /usr/src/app
COPY client/package.json client/package-lock.json ./
RUN npm i

# Stage 2 - the build react app
FROM node:12.4.0-alpine as build
COPY --from=build-deps /usr/src/app/node_modules /usr/src/app/node_modules
WORKDIR /usr/src/app

COPY client/ ./
RUN npm run build

# Stage 3 - the production environment
FROM node:12.4.0-alpine

RUN apk add --no-cache tini
ENV NODE_ENV production
WORKDIR /usr/src/app
RUN chown -R node:node /usr/src/app/
EXPOSE 4654

COPY server/package.json server/package-lock.json ./
RUN npm i --production

COPY --from=build /usr/src/app/build /usr/src/app/public
COPY /server ./

# USER 1000 is the "node" user
# This is to avoid the "container has runAsNonRoot and image has non-numeric user (node), cannot verify user is non-root"
# in clusters with PSP enabled
USER 1000

ENTRYPOINT ["/sbin/tini", "--", "node", "."]
