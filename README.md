# build our docker registry & create git action for build to our registry 
1. create forlder for repository
	mkdir docker-repository
2. greate folders tree 
	mkdir -p docker-registry/{nginx,auth,data}
	mkdir -p docker-registry/nginx/{conf.d,ssl}
3. create login password for registry
	cd auth
		htpasswd -Bc registry.passwd [username]
4. generate ssl sertificates for registry
	sudo apt install nginx 
	sudo service nginx restart
	sudo apt install certbot python3-certbot-nginx 
	sudo certbot --nginx -d [your-domain.com] -d [www.your-domain.com]
5. copy sertificates to ssl folder and disable nginx on computer
	sudo cp /etc/letsencrypt/live/[your-domain.com]/fullchain.pem > to docker-registry/nginx/ssl/ 
	sudo cp /etc/letsencrypt/live/[your-domain.com]/privkey.pem > to docekr-registry/nginx/ssl/
	sudo systemctl stop nginx
	sudo systemctl disable nginx
6. create  nginx configuration file 
	cd /nginx/conf.d/
	nano registry.conf

		upstream docker-registry {
		    server registry:5000;
		}
		
		server {
		    listen 80;
		    server_name registry.[your.domain.com];
		    return 301 https://[your-domain.com]$request_uri;
		}
		
		server {
		    listen 443 ssl http2;
		    server_name registry.[your-domain.com];
		
		    ssl_certificate /etc/nginx/ssl/fullchain.pem;
		    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
		
		    error_log  /var/log/nginx/error.log;
		    access_log /var/log/nginx/access.log;
		    client_max_body_size 5G;
		
		    location / {
		        if ($http_user_agent ~ "^(docker\/1\.(3|4|5(?!\.[0-9]-dev))|Go ).*$" )  {
		            return 404;
		        }
		
		        proxy_pass                          http://docker-registry;
		        proxy_set_header  Host              $http_host;
		        proxy_set_header  X-Real-IP         $remote_addr;
		        proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
		        proxy_set_header  X-Forwarded-Proto $scheme;
		        proxy_read_timeout                  900;
		    }
		
		}
	
7. create docker compose file 
	cd docker registry
	nano docker-compose.yml
	
		version: '3'
		services:
		  registry:
		    image: registry:2
		    restart: always
		    ports:
		    - "5000:5000"
		    environment:
		     - REGISTRY_HTTP_TLS_CERTIFICATE:/ssl/fullchain.pem
		     - REGISTRY_HTTP_TLS_KEY:/ssl/privkey.pem
		     - REGISTRY_AUTH:htpasswd
		     - REGISTRY_AUTH_HTPASSWD_REALM:Registry-Realm
		     - REGISTRY_AUTH_HTPASSWD_PATH:/auth/registry.passwd
		     - REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY:/data
		    volumes:
		      - ./nginx/ssl:/ssl
		      - ./data:/data
		      - ./auth:/auth
		    networks:
		      - mynet
		      
		  nginx:
		    image: nginx:alpine
		    container_name: nginx
		    restart: unless-stopped
		    tty: true
		    ports:
		      - "80:80"
		      - "443:443"
		    volumes:
		      - ./nginx/conf.d:/etc/nginx/conf.d/
		      - ./nginx/ssl:/etc/nginx/ssl/
		    networks:
		      - mynet
		networks:
		  mynet:
		    driver: bridge
		volumes:
		  registrydata:
		    driver: local

8. run docker compose command 
	docker compose up 
