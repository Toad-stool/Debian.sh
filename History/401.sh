shopt -s expand_aliases
echo -n "Enter your IP:"
read ip
echo -n "Enter your domain:"
read dm
echo -n "Enter your password:"
read pw
apt install -y sudo
sudo apt update
sudo apt upgrade -y
sudo apt install socat cron curl libcap2-bin xz-utils nano -y
sudo systemctl start cron
sudo mkdir -p /usr/local/etc/certfiles
sudo curl https://get.acme.sh | sh
alias acme.sh=~/.acme.sh/acme.sh
acme.sh --set-default-ca  --server  letsencrypt
acme.sh -d ${dm} --standalone --issue --force
acme.sh --install-cert -d ${dm} --key-file /usr/local/etc/certfiles/private.key --fullchain-file /usr/local/etc/certfiles/certificate.crt --force
acme.sh  --upgrade  --auto-upgrade
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
sudo sed -i "s:password1:${pw}:g" /usr/local/etc/trojan/config.json
sudo sed -i "s:password2:${pw}:g" /usr/local/etc/trojan/config.json
sudo sed -i "s:/path/to/certificate.crt:/usr/local/etc/certfiles/certificate.crt:g" /usr/local/etc/trojan/config.json
sudo sed -i "s:/path/to/private.key:/usr/local/etc/certfiles/private.key:g" /usr/local/etc/trojan/config.json
sudo systemctl restart trojan
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
