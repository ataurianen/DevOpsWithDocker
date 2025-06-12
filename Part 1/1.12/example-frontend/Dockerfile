FROM node:16

COPY . .

RUN npm install

ENV REACT_APP_BACKEND_URL=http://localhost/api/

RUN npm run build

RUN npm install -g server

EXPOSE 5000

CMD ["npx","serve","-s","-l","5000","build"]
