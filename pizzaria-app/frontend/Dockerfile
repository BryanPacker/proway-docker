# frontend/Dockerfile
FROM nginx:stable-alpine

# Onde seus arquivos do React estão (pode ser ./build, ./dist, etc.)
COPY ./public /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
