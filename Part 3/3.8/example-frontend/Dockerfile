FROM node:16-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

FROM node:16-alpine

WORKDIR /app

COPY --from=builder /app/build ./build

RUN npm install -g serve --unsafe-perm

ENV REACT_APP_BACKEND_URL=http://localhost/api/

EXPOSE 5000

RUN adduser -D appuser
USER appuser

CMD ["npx","serve","-s","-l","5000","build"]
