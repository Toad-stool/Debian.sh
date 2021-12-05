sudo apt install nginx -y
sudo rm /etc/nginx/sites-enabled/default
sudo cat>/etc/nginx/sites-available/${dm}<<EOF
server {
    listen 127.0.0.1:80 default_server;

    server_name ${dm};

    location / {
        proxy_pass https://pan.baidu.com;
    }

}

server {
    listen 127.0.0.1:80;

    server_name ${ip};

    return 301 https://${dm}$request_uri;
}

server {
    listen 0.0.0.0:80;
    listen [::]:80;

    server_name _;

    location / {
        return 301 https://$host$request_uri;
    }

    location /.well-known/acme-challenge {
       root /var/www/acme-challenge;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/${dm} /etc/nginx/sites-enabled/
sudo systemctl restart nginx
sudo systemctl enable trojan
sudo chmod +x /etc/init.d/nginx
sudo update-rc.d -f nginx defaults
lsmod | grep bbr
echo "Trojan部署完成，请重启VPS"