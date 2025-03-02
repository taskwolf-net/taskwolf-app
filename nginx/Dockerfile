FROM nginx

ARG SERVER_NAME
ENV SERVER_NAME=${SERVER_NAME}

COPY linux/dulno.deb /home/dulno/app/linux/dulno.deb
COPY windows/dulno.exe /home/dulno/app/windows/dulno.exe

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/app /etc/nginx/sites-available/app
RUN mkdir -p /etc/nginx/sites-enabled
RUN ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app

CMD ["/bin/sh", "-c", "envsubst '$SERVER_NAME' < /etc/nginx/sites-available/app > /tmp/app && mv /tmp/app /etc/nginx/sites-available/app && exec nginx -g 'daemon off;'"]