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
lsmod | grep bbr