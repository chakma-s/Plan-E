FROM nginx:alpine

COPY nginx.conf /etc/nginx/nginx.conf

# Copy static web portals into Nginx doc root
COPY ../web_portal/vendor /usr/share/nginx/html/vendor
COPY ../web_portal/admin /usr/share/nginx/html/admin

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
