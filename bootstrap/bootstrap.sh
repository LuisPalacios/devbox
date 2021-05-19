#!/bin/bash
#
# Script que se ejecutará durante el primer boot de la Máquina virtual.
#
# Este directorio del proyecto debe haberse montado como /vagrant
# dentro de la VM (y se sincroniza automáticamente).
#
export TERM=vt100
export BOOTSTRAP_DIR="/vagrant/bootstrap"
export BOOTSTRAP_YAML=${BOOTSTRAP_DIR}"/bootstrap.yaml"
export BOOTSTRAP_KEYS=${BOOTSTRAP_DIR}"/bootstrap.keys"

# Mostrar por dónde vamos...
step=1
step() {
    echo "Paso $step: $1"
    step=$((step+1))
}

# Función que utilia sed/awk para parsear ficheros Yaml muy simples
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("export %s%s%s='\''%s'\''\n", "'${prefix}'", vn, $2, $3);
      }
   }'
}

# Leer el fichero de configuración
function leeConfigYAML {
    step "Analizando ${BOOTSTRAP_YAML}"
    if [ ! -f ${BOOTSTRAP_YAML} ]
    then
	echo "ERROR: Necesito el fichero ${BOOTSTRAP_YAML} :-("
        exit 1
    fi

    # Saco a un script externo las variables y hago 'source'
    # para que se exporten adecuadamente
    parse_yaml ${BOOTSTRAP_YAML} "CONF_" > /tmp/conf.sh
    source /tmp/conf.sh
}

# Comprobar la versión de Linux
function compruebaLinux {
    step "Comprobando la versión de Linux"

    # Espero encontrar Ubuntu 20.10
    grep 'Groovy Gorilla' /etc/os-release > /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "ERROR: Esperaba encontrar Ubuntu 20.10 :-("
        exit 1
    fi
}

#
# Estoy en Madrid
#
function configuraTimezone {
    step "Configurando el timezone"

    timedatectl set-timezone ${CONF_timezone}
    if [ ! $? -eq 0 ]
    then
        echo "AVISO: Configurando el timezone"
    fi    
}

#
# Cambio el tipo de teclado que utilizo
#
function configuraTeclado {
    step "Configurando el teclado"

    sed -ie '/^XKBLAYOUT=/s/".*"/"${CONF_teclado}"/' /etc/default/keyboard
    if [ ! $? -eq 0 ]
    then
        echo "AVISO: Configurando el teclado"
    fi
    udevadm trigger --subsystem-match=input --action=change
}

#
# Creo al usuario que me pasan en el yaml
#
function addLocalUser {
    step "Añadiendo usuario '${CONF_usuario}'..."

    # Creo el usuario 
    useradd -m -s /bin/bash ${CONF_usuario}

    # Cambio la contraseña del usuario. 
    echo "${CONF_usuario}:${CONF_password}" | chpasswd -e

    #rsync --archive --chown=$LOCAL_USER:$LOCAL_USER $ACTUAL_DIR/resources/localuser/home/ /home/$LOCAL_USER
    #rsync --archive --chown=$LOCAL_USER:$LOCAL_USER ~/.ssh /home/$LOCAL_USER

    #cat $ACTUAL_DIR/resources/localuser/profile/bashrc >> /home/$LOCAL_USER/.bashrc
   
    usermod -aG sudo ${CONF_usuario}
    echo  "${CONF_usuario} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${CONF_usuario}

    #mkdir -p /opt/compose
    #chown $LOCAL_USER:$LOCAL_USER /opt/compose

    su - ${CONF_usuario} -c "mkdir ~/notebooks; touch ~/notebooks/.install"

    #
    # Una vez que he copiado la clave pública me aseguro que
    # el daemon SSHD solo acepta al usuario "CONF_usuario"
    # 
    su - ${CONF_usuario} -c "mkdir ~/.ssh; cat ${BOOTSTRAP_KEYS} > ~/.ssh/authorized_keys"
    #
    # Copio el fichero sshd_config que está bajo bootstrap y
    # es muy restrictivo. Solo acepta claves públicas
    rsync --archive --chown=root:root ${BOOTSTRAP_DIR}/ssh/sshd_config /etc/ssh/
    /etc/init.d/ssh reload
}

#
# Locale a es_ES.UTF-8
#
function configuraLocale {
    step "Configuro Locale"
    locale-gen --purge es_ES.UTF-8
    echo -e 'LANG="es_ES.UTF-8"\n' > /etc/default/locale
}

#
# Copio scripts a /usr/local/bin
#
function copiaLocalBin {
    step "Copio scripts a /usr/local/bin"
    chmod a+x ${BOOTSTRAP_DIR}/local/bin/*
    cp ${BOOTSTRAP_DIR}/local/bin/* /usr/local/bin
    rsync --archive --chown=root:root ${BOOTSTRAP_DIR}/local/bin/ /usr/local/bin    
}

#
# Instalo todos los paquetes que tengo en el fichero paquetes.conf
#
function instalarPaquetes {
    step "Instalando paquetes del sistema"
    apt-get -qq update
    apt-get -qq -y upgrade
    apt-get install -y $(grep -vE "^\s*#" ${BOOTSTRAP_DIR}/paquetes.conf  | tr "\n" " ")
}

function instalarNodeJs {
    echo "Instalando NodeJs"
    
    curl -sL https://deb.nodesource.com/setup_14.x -o ~/nodesource_setup.sh
    bash ~/nodesource_setup.sh
    apt-get install -qq -y nodejs
    rm ~/nodesource_setup.sh
}

#
# Instalación de Docker
#
function instalarDocker {
    step "Instalo Docker"

    # Siempre es importante estar a la última
    apt-get -qq update
    apt-get -qq -y upgrade

    # Instalo paquetes para que APT pueda trabajar via HTTPS
    apt-get -qq -y install apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

    # Incluyo la clave PGP oficial de Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Instalo los paquetes
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
    apt-get -qq update
    apt-get install -qq -y docker-ce docker-ce-cli docker-compose containerd.io

    # Añado al usuario 
    usermod -aG docker ${CONF_usuario}

    systemctl daemon-reload
    systemctl restart docker    
}

#
# Instalación de paquetes Python en el usuario...
#
function instalarPaquetesPython_LocalUser {
    echo "Python: Creando el entorno virtual..."

    virtualenv -p /usr/bin/python3 ~/venv
    source ~/venv/bin/activate

    echo "Python: Instalando paquetes adicionales"
    pip install -U pip setuptools
    pip install --no-cache-dir -r ${BOOTSTRAP_DIR}/bootstrap.req.python    
}

function instalarPaquetesPython {
    export -f instalarPaquetesPython_LocalUser
    su ${CONF_usuario} -c "bash -c instalarPaquetesPython_LocalUser"
}

#
# Instalación de JupyterLabExtensions en el usuario
#
function instalarJupyterLabExtensions_LocalUser {
    echo "Instalando lab extensions ..."

    source ~/venv/bin/activate

    jupyter contrib nbextension install --user
    jupyter nbextensions_configurator enable --user
    jupyter lab build
}

function instalarJupyterLabExtensions {
    export -f instalarJupyterLabExtensions_LocalUser
    su ${CONF_usuario} -c "bash -c instalarJupyterLabExtensions_LocalUser"

}

#
# Habilito el arranque de JupyterLabs durante el boot
#
function servicioJupyterLab {
    echo "Configurando Jupyter Lab ..."

    # Preparo los ficheros necesarios para el daemon
    mkdir /etc/jupyter
    envsubst < ${BOOTSTRAP_DIR}/jupyter.sh.template  > /usr/local/bin/jupyter.sh
    chmod a+x /usr/local/bin/jupyter.sh
    envsubst <  ${BOOTSTRAP_DIR}/jupyter.service.template  > /etc/systemd/system/jupyter.service

    # Configuro el servicio para que arranque durante el boot
    systemctl daemon-reload
    systemctl enable jupyter.service
    systemctl start jupyter.service
}

#
# Cambio el mensaje de bienvenida en la shell
#
configuraBienvenida() {
    step "Mensaje de bienvenida"

    apt-get install -qq -y cowsay
    echo -e "\necho \"Bienvenido a mi servidor ${CONF_usuario}\" | cowsay\n" >> /home/${CONF_usuario}/.bashrc
    echo -e "\necho\n" >> /home/${CONF_usuario}/.bashrc
    ln -s /usr/games/cowsay /usr/local/bin/cowsay
}


#
# Función principal
#
main() {

    leeConfigYAML
    compruebaLinux
    configuraTimezone
    configuraTeclado
    configuraLocale
    copiaLocalBin
    addLocalUser
    instalarPaquetes
    instalarNodeJs
    instalarDocker
    instalarPaquetesPython
    instalarJupyterLabExtensions
    servicioJupyterLab
    configuraBienvenida
}

# Punto de entrada al programa
#
main
