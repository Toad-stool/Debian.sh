shopt -s expand_aliases
echo -n "Enter your VPS IP:"
read ip
echo -n "Enter your VPS domain:"
read domain
apt install -y sudo
sudo apt update
sudo apt full-upgrade -y
sudo apt install socat cron curl libcap2-bin xz-utils nano -y
sudo systemctl start cron
sudo mkdir -p /usr/local/etc/certfiles
sudo curl https://get.acme.sh | sh
alias acme.sh=~/.acme.sh/acme.sh
acme.sh --set-default-ca  --server  letsencrypt
acme.sh -d ${domain} --standalone --issue --force
acme.sh --install-cert -d ${domain} --key-file /usr/local/etc/certfiles/private.key --fullchain-file /usr/local/etc/certfiles/certificate.crt --force
acme.sh  --upgrade  --auto-upgrade
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
cat>/etc/nginx/sites-available/${domain}<<EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "20211203"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/usr/local/etc/certfiles/certificate.crt",
        "key": "/usr/local/etc/certfiles/private.key",
        "key_password": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GC>
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "alpn_port_override": {
            "h2": 81
        },
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": false,
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": "",
        "key": "",
        "cert": "",
        "ca": ""
    }
}
EOF
sudo apt install nginx -y
sudo rm /etc/nginx/sites-enabled/default
cat>/etc/nginx/sites-available/${domain}<<EOF
server {
    listen 127.0.0.1:80 default_server;

    server_name ${domain};

    location / {
        proxy_pass https://pan.baidu.com;
    }

}

server {
    listen 127.0.0.1:80;

    server_name ${ip};

    return 301 https://${domain}$request_uri;
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
sudo ln -s /etc/nginx/sites-available/${domain} /etc/nginx/sites-enabled/
sudo systemctl enable trojan
sudo chmod +x /etc/init.d/nginx
sudo update-rc.d -f nginx defaults
lsmod | grep bbr