# Developer Box

Este repositorio contiene todo lo necesario para crearte una máquina virtual utilizando `Vagrant`. Está preparada para funcionar con los proveedores VirtualBox o KVM.

Además podrá utilizarse para conectar con servicios adicionales, aunque esa parte está todavía Work-In-Progress...

* [Servicios Jupyter-Labs](https://github.com/LuisPalacios/devbox-db-jupyterlabs)

- JupyterLabs

* [Servicios de bases de datos](https://github.com/LuisPalacios/devbox-db-services)

- Postgres
- Riak
- Cassandra
- Mongodb
- Neo4j

## Instalación

Clona este repositorio en un ordenador donde tengas VirtualBox o KVM (Libvirt).

```
git clone https://github.com/LuisPalacios/devbox.git
cd devbox
```

* Pega la(s) clave(s) pública SSH de tu ordenador cliente al fichero `bootstrap/bootstrap.keys` (mira el ejemplo a continuación).

```
cat ~/.ssh/id_rsa.pub >> bootstrap/bootstrap.keys
```

* A continuación revisa el fichero `bootstrap/bootstrap.yaml` y adáptalo a tus necesidades.

```config
usuario: luis
password: $6$x...
boxname: 'generic/ubuntu2010'
hostname: 'coder'
timezone: 'Europe/Madrid'
teclado: 'es'
```

* Por último ya puedes arrancar la máquina virtual:

```console
luis@jupiter:~/devbox$ vagrant up
```

<br/>

## SSH 

### Conexión a VM corriendo en HOST Linux (KVM/Libvirt)

* Veamos cómo configurar el cliente SSH para el caso de conectar con la VM cuando la hemos levantado en un HOST Linux con dirección IP fija pública.

```config
Host coder
  HostName 192.168.1.13		<== Cámbialo por la IP de tu VM
  User luis			<== Cámbialo por tu usuario
  Port 22
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  LogLevel=error
```

* Jupyter Lab

Ya puedes conectar con JupyterLabs... (esta IP es la estática que yo puse)

* [http://192.168.1.13:8001](http://192.168.1.13:8001)

* Conexión vía SSH

```console
luis@jupiter:~$ ssh coder
Enter passphrase for key '/home/luis/.ssh/id_rsa':
luis@coder:~$
```

<br/>

### Conexión a VM corriendo en HOST local en VirtualBox

* Configuración en un cliente SSH en mi Mac para conectar con VM en mi Mac (localhost). Miro el comando `vagrant ssh-config` para confirmar y luego configuro el fichero ~/.ssh/config del cliente, lo llamo `coderlocal`.

```console
Host coderlocal
  HostName 10.20.30.40
  User luis
  Port 22
  LocalForward 8001 127.0.0.1:8001
  LocalForward 3100 127.0.0.1:3100
  LocalForward 27017 127.0.0.1:27017
  LocalForward 7474 127.0.0.1:7474
  LocalForward 5050 127.0.0.1:5050
  LocalForward 8098 127.0.0.1:8098
  LocalForward 8082 127.0.0.1:8082
  LocalForward 7687 127.0.0.1:7687
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  LogLevel=error  
```

* Conecto con la VM en local

```console
luis @ idefix ➜  ~ ssh coderlocal
luis@coder:~$
```

* Jupyter Lab

Una vez que has abierto una sesión SSH se activa el forwarding de puertos, por lo tanto podrás conectar con el servicio JupyterLab simplemente con: 

* [http://127.0.0.1:8001](http://127.0.0.1:8001)

<br/>

### Proyecto relacionados.

* Instalarte el [Taller BBDD](https://github.com/dvillaj/Taller_BBDD) de Daniel Villanueva. Entra en tu VM vía SSH con tu usuario y ejecuta el comando `curl` que puedes ver en el siguiente ejemplo:

```console
 $ ssh luis@coder
 $ curl -s https://raw.githubusercontent.com/dvillaj/NoSQL-Services/master/scripts/setup.sh | bash
```
