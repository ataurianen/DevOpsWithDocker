FROM node:16

WORKDIR /app

COPY . .

RUN npm install

ENV REACT_APP_BACKEND_URL=http://localhost/api/

RUN npm run build

RUN npm install -g server

EXPOSE 5000

RUN useradd -m appuser

RUN chown appuser .

USER appuser

CMD ["npx","serve","-s","-l","5000","build"]
