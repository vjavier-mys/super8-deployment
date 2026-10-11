FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
ARG VITE_GOOGLE_CLIENT_ID
ARG VITE_VENDOR_NAME=Kasuki
ARG VITE_APP_STAGE=staging
ENV VITE_GOOGLE_CLIENT_ID=$VITE_GOOGLE_CLIENT_ID
ENV VITE_VENDOR_NAME=$VITE_VENDOR_NAME
ENV VITE_APP_STAGE=$VITE_APP_STAGE
RUN npm run build

FROM node:22-bookworm-slim
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
COPY --from=build /app/server ./server
EXPOSE 3002
CMD ["node", "server/index.js"]
