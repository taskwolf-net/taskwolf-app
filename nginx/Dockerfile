FROM nginx

COPY linux/dulno.deb /home/dulno/app/linux/dulno.deb
COPY windows/dulno.exe /home/dulno/app/windows/dulno.exe

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/app /etc/nginx/sites-available/app
COPY nginx/app /etc/nginx/sites-enabled/app
