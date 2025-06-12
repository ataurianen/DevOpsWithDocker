FROM node:16-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build && npm install -g server
ENV REACT_APP_BACKEND_URL=http://localhost/api/

EXPOSE 5000

RUN adduser -D appuser
USER appuser

CMD ["npx","serve","-s","-l","5000","build"]
