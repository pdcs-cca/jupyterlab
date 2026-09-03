#!/bin/bash

cd /root
dnf -y remove VirtualBox-7.2-7.2.2_170484_el9-1.x86_64 
dnf -y install epel-release
test ! -x /opt/VirtualBox/VirtualBox && wget https://download.virtualbox.org/virtualbox/7.2.16/VirtualBox-7.2.16-174877-Linux_amd64.run && bash /root/VirtualBox-7.2.16-174877-Linux_amd64.run
dnf install -y qt6-qtwebview
systemctl --now disable rpcbind.service 
systemctl --now disable rpcbind.socket
systemctl --now disable cups.service 
timedatectl set-timezone America/Mexico_City
systemctl --now disable firewalld.service  

echo "=========================================="
echo "Instalación de NoVNC + Nginx + SSL"
echo "Rocky Linux 9"
echo "=========================================="

# Variables de configuración
DOMAIN="localhost"
PORT_NOVNC="6080"
PORT_NGINX="443"
PORT_VNC="5900"
CERT_DIR="/etc/nginx/ssl"
CERT_FILE="$CERT_DIR/novnc.crt"
KEY_FILE="$CERT_DIR/novnc.key"
NOVNC_DIR="/opt/novnc"
WEBSOCK_DIR="/opt/websockify"
NOVNC_USER="alumno"

# Paso 1: Actualizar sistema
echo "[1/8] Actualizando sistema..."
dnf update -y

# Paso 2: Instalar dependencias
echo "[2/8] Instalando dependencias..."
dnf install -y \
    nginx \
    git \
    python3 \
    python3-pip \
    openssl \
    wget \
    curl

# Paso 3: Crear usuario para NoVNC
echo "[3/8] Creando usuario NoVNC..."
if ! id -u $NOVNC_USER > /dev/null 2>&1; then
    useradd -r -s /bin/bash $NOVNC_USER
    echo "Usuario $NOVNC_USER creado"
else
    echo "Usuario $NOVNC_USER ya existe"
fi

# Paso 4: Descargar e instalar NoVNC
echo "[4/8] Instalando NoVNC..."
if [ ! -d "$NOVNC_DIR" ]; then
    mkdir -p $NOVNC_DIR
    cd $NOVNC_DIR
    git clone https://github.com/novnc/noVNC.git .
    ln -s vnc.html index.html  
    # Instalar dependencias Python de NoVNC
    pip3 install numpy 
else
    echo "NoVNC ya está instalado en $NOVNC_DIR"
fi

echo "[4/8] Instalando websockify..."
if [ ! -d "$WEBSOCK_DIR" ]; then
    mkdir -p $WEBSOCK_DIR
    cd $WEBSOCK_DIR
    git clone https://github.com/novnc/websockify.git .
    # Instalar dependencias Python de NoVNC
    pip3 install numpy 
else
    echo "NoVNC ya está instalado en $NOVNC_DIR"
fi



chown -R $NOVNC_USER:$NOVNC_USER $NOVNC_DIR

# Paso 5: Crear directorio SSL
echo "[5/8] Creando certificados SSL autofirmados..."
mkdir -p $CERT_DIR

# Generar certificado autofirmado válido por 365 días
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $KEY_FILE \
    -out $CERT_FILE \
    -subj "/C=ES/ST=State/L=City/O=Organization/CN=$DOMAIN"

chmod 600 $KEY_FILE
chmod 644 $CERT_FILE

echo "Certificados creados:"
echo "  Certificado: $CERT_FILE"
echo "  Clave privada: $KEY_FILE"

# Paso 6: Configurar Nginx como proxy inverso
echo "[6/8] Configurando Nginx..."

# Crear configuración de Nginx
cat > /etc/nginx/conf.d/novnc.conf << 'EOF'
upstream novnc_backend {
    server 127.0.0.1:6080;
}

server {
    listen 443 ssl http2;
    server_name localhost;

    # Certificados SSL
    ssl_certificate /etc/nginx/ssl/novnc.crt;
    ssl_certificate_key /etc/nginx/ssl/novnc.key;

    # Configuración SSL segura
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Tamaño máximo de cuerpo
    client_max_body_size 10M;

    # Logs
    access_log /var/log/nginx/novnc_access.log;
    error_log /var/log/nginx/novnc_error.log;

    # Configuración de proxy
    location / {
        proxy_pass http://novnc_backend;
        proxy_http_version 1.1;
        
        # Headers para WebSocket
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Headers estándar
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket específicamente
    location /websockify {
        proxy_pass http://novnc_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }
}

# Redirigir HTTP a HTTPS
server {
    listen 80;
    server_name localhost;
    return 301 https://$server_name$request_uri;
}
EOF

# Validar configuración de Nginx
nginx -t
systemctl restart nginx
systemctl enable nginx

echo "Nginx configurado"

# Paso 7: Crear servicio systemd para NoVNC
echo "[7/8] Creando servicio systemd..."

cat > /etc/systemd/system/novnc.service << EOF
[Unit]
Description=NoVNC WebSocket VNC proxy
After=network.target

[Service]
Type=simple
User=$NOVNC_USER
WorkingDirectory=$NOVNC_DIR
ExecStart=/opt/websockify/run --web=$NOVNC_DIR 0.0.0.0:6080 localhost:$PORT_VNC
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd y habilitar servicio
systemctl daemon-reload
systemctl enable novnc
systemctl restart novnc

echo "Servicio NoVNC creado y habilitado"

# Paso 8: Información final
test -d /home/alumno/.vnc || runuser -l alumno -c "mkdir /home/alumno/.vnc/"   
#runuser -l alumno -c "echo -e localhost\\nsecuritytypes=None > /home/alumno/.vnc/config"
runuser -l alumno -c "openssl rand -hex 26 > /home/alumno/.vncpasswd"
runuser -l alumno -c "cat /home/alumno/.vncpasswd | vncpasswd -f >  /home/alumno/.vnc/passwd"
runuser -l alumno -c "chmod 600 /home/alumno/.vnc/passwd "
runuser -l alumno -c "vncserver -kill :0"
runuser -l alumno -c "vncserver :0"

echo "https://$(curl -s ifconfig.me)/?resize=scale&reconnect=1&autoconnect=1&password=$(cat /home/alumno/.vncpasswd)&show_dot=1"  > /home/alumno/.url 
cat /home/alumno/.url
echo "Port 9022" > /etc/ssh/sshd_config.d/50-local.conf
service sshd reload 
useradd -ms /bin/bash -G wheel soporte


