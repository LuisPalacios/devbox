# Developer Box

Este repositorio contiene todo lo necesario para crear una máquina virtual (VM: Virtual Machine) con [Vagrant](https://www.vagrantup.com/). Esta VM en particular está orientada al Desarrollo de Software con Python y [JupyterLabs](https://jupyter.org/). 


El repositorio está basado en [NoSQL-box](https://github.com/dvillaj/NoSQL-box) de Daniel Villanueva, con modificaciones y literatura adicional que he añadido. Podrás utilizar esta VM para conectar con servicios adicionales de Bases de Datos, cuadernos Jupyter de ejercicios. Más información al final de este README.

<br/>

## Preparar Vagrant y el Proveedor

Vagrant es una utilidad de línea de comandos que permite gestionar el ciclo de vida de las máquinas virtuales. Necesitas instalar un Software de Vrtualización, el propio Vagrant y conectar ambos entre sí con un Proveedor. El `Vagrantfile` de este repositorio está preparado para trabajar con los proveedores VirtualBox, Parallels o KVM. 

- (1) Software de Virtualización, te paso algunos enlaces: 
  - Guía oficial sobre la [instalación de VirtualBox](https://www.virtualbox.org/wiki/Downloads). 
  - Si usas Parallels Desktop, aquí está [su documentación](https://www.parallels.com/es/products/desktop/download-documents/) para instalarlo.
  - En el caso de KVM/libvirt hay cientos de referencias en internet. Aquí tienes mi [apunte técnico sobre la instalación de KVM y Vagrant](https://www.luispa.com/virtualizaci%C3%B3n/2021/05/15/vagrant-kvm.html)
- (2) Instalación de Vagrant: Sigue la [guía oficial de instalación de Vagrant](https://www.vagrantup.com/docs). Puedes instalarlo en Linux, MacOS, Windows...
- (3) Proveedor: 
  - **Proveedor para VirtualBox**: Vagrant trae soporte nativo para VirtualBox, por lo tanto no necesitas hacer nada especial. 
  - **Proveedor para Parallels Desktop**: En [este sitio](https://parallels.github.io/vagrant-parallels/docs/) documentan cómo Vagrant puede usar las máquinas virtuales basadas en Parallels Desktop para Mac. Es sencillísimo: 
    - Instalación: `$ vagrant plugin install vagrant-parallels`
    - Actualización: `$ vagrant plugin update vagrant-parallels`
    - Uso: `$ vagrant up` o si tienes multi-proveedor `$ vagrant up --provider=parallels`
  - **Proveedor para KVM/libvirt**: Cada distribución de Linux tiene sus peculiaridades, así que lo mejor es que busques los manuales de la tuya. En mi [apunte técnico sobre la instalación de KVM y Vagrant](https://www.luispa.com/virtualizaci%C3%B3n/2021/05/15/vagrant-kvm.html) describo cómo lo instalé en un Ubuntu 20.10 (Groovy Gorilla). 

<br/>

## Instalación de la VM

Clona este repositorio en un ordenador donde tengas VirtualBox (Windows, Linux, MacOS,Solaris), Parallels Desktop (MacOS) o KVM (Libvirt en Linux).

```
git clone https://github.com/LuisPalacios/devbox.git
cd devbox
```

* Pega la(s) clave(s) pública SSH de tu ordenador cliente al fichero `bootstrap/public-keys.txt`:

```
cat ~/.ssh/id_rsa.pub >> bootstrap/public-keys.txt
```

* Revisa el fichero `bootstrap/bootstrap.yaml` y adáptalo a tus necesidades. Dentro del fichero tienes instrucciones para generar la contraseña de tu usuario.

```config
usuario: luis
password: $6$x...
boxname: 'generic/ubuntu2010'
hostname: 'coder'
timezone: 'Europe/Madrid'
teclado: 'es'
```

* Arranca la máquina virtual:

```console
luis@jupiter:~/devbox$ vagrant up


# Si estás en un MacOS con multiproveedor: 

luis@jupiter:~/devbox$ vagrant up --provider=parallels   
```

* Conecta con `vagrant ssh`. Esta opción siempre te va a funcionar, más adelante veremos más opciones.
  
```console
luis @ idefix $ vagrant ssh
vagrant@coder:~$
vagrant@coder:~$ sudo su - luis
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

 _______________________________
< Bienvenido a mi servidor luis >
 -------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

luis@coder:~$
```

<br/>

## Trabajo con la máquina virtual

**Conectar con Jupyter Lab**

A partir de ahora ya puedes conectar con los servicios de esta máquina virtual. Observa en el fichero `Vagrantfile` los puertos mapeados, entre ellos el de JupyterLab. Dependiendo del tipo de proveedor utilizado podrás acceder en local (desde tu propio ordenador) o desde la LAN. Aquí tienes algunos ejemplos: 

- http://127.0.0.1:8001
- http://A.B.C.D:8001
- http://tu.dominio.com:8001

<br/>

**Configurar GIT**

Una vez dentro de JupyterLab puedes arrancar el Terminal y configurar GIT: 

```console
$  git config --global user.email "you@example.com"
$  git config --global user.name "Tu Nombre"
```

![GIT en JupyterLab](vagrant-git.png?raw=true "GIT en JupyterLab")

<br/>


## Configuración SSH 

El fichero `Vagrantfile` está preparado para configurar dos estrategias distintas dependiendo de quién sea tu proveedor (KVM o VirtualBox / Parallels Desktop): 

* VM en un HOST Linux con KVM/Libvirt - Uso networking público: Asigno una Dirección IP Fija a la VM 
* VM en un HOST local con VirtualBox  - Uso networking privado: PORT FORWARDING
* VM en un HOST local con Parallels Desktop  - Uso networking privado: PORT FORWARDING

<br/>

### HOST Linux con KVM/Libvirt

* Una vez que tienes la máquina virtual funcionando en tu Host Linux deberías poder ver algo parecido a esto desde `virt-manager`:

![VM en Linux](vagrant-kvm.png?raw=true "VM en Linux")

Configuro `.ssh/config` para facilitar la conexión. Uso IP fija porque en KVM/Libvirt configuré networking público en el `Vagrantfile`:

```config
Host coder
  HostName 192.168.1.13    <== Cámbialo por la IP de tu VM
  User luis                <== Cámbialo por tu usuario
  Port 22
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  LogLevel=error
```

**Conexión vía SSH**

La contraseña es la de tu clave pública/privada

```console
luis @ idefix ➜  ~  ssh coder
Enter passphrase for key '/Users/luis/.ssh/id_rsa':

luis@coder:~$
```

<br/>

### HOST Mac (o Windows) con VirtualBox

* Otro ejemplo, si lo monto en un Mac o un Windows, configuro el cliente SSH para conectar con la VirtualBox (localhost). Configuro el fichero ~/.ssh/config del cliente y a esta opción la llamo `coder-vb`.

![VM en Virtualbox](vagrant-vb.png?raw=true "VM en Virtualbox")


```console
Host coder-vb
  HostName 127.0.0.1
  User luis
  Port 2222
```

**Conecta vía SSH**

Si la estableciste, recuerda que la contraseña es la de tu clave pública/privada

```console
luis @ idefix ➜  ~  ssh coder-vb
Enter passphrase for key '/Users/luis/.ssh/id_rsa':

luis@coder:~$
```
 
<br/>

### HOST con Parallels Desktop

* En este caso he configurado un MacOS con Parallels Desktop como Host. Configuro el cliente SSH para conectar con la VM en Parallels (localhost). Configuro el fichero ~/.ssh/config del cliente y a esta opción la llamo `coder-prl`.

![VM en Parallels](vagrant-prl.png?raw=true "VM en Parallels Desktop")


```console
Host coder-prl
  HostName 127.0.0.1
  User luis
  Port 2222
```

**Conecta vía SSH**

Si la estableciste, recuerda que la contraseña es la de tu clave pública/privada

```console
luis @ idefix ➜  ~  ssh coder-prl
Enter passphrase for key '/Users/luis/.ssh/id_rsa':

luis@coder:~$
```

<br/>

### Conexión al HOST por internet vía SSH 

Si quieres conectar con tu VM desde internet una posible solución es hacer SSH a un equipo intermedio (tu firewall) y que este pueda llegar a tu Host/VM a través de tu la LAN privada. Sería algo así: 


```config
                                                 ┌─┬────────────┬─┐
                                                 │ │ coder VM   │ │
                                                 │ │            │ │
┌──────────┐               ┌───────────┐         │ └────────────┘ │
│          │   INTERNET    │           │  LAN    │                │
│ Cliente  ├──────────────►│ SSHServer ├───────► │  KVM HOST      │
│          │               │           │  LOCAL  │                │
└──────────┘               └───────────┘         └────────────────┘
                       miserver.midom.org           192.168.1.13

```

* Configuramos SSH para llegar al SSHServer y además preparamos "port forwarding", de modo que él pueda reenviar el puerto 8001 al HOST/VM

```console
Host coder-via-internet
  HostName miserver.midom.org
  User luis
  Port 12345
  LocalForward 8001 192.168.1.13:8001
```

* Conectamos con el SSHServer, tendremos acceso al terminal (shell) y el reenvío del puerto activo. 
  
```console
luis @ idefix ➜  ~ ssh coder-via-internet
luis@coder:~$
```

> **Alternativa**: usar `-N` que activa el reenvío del puerto SIBN terminal: `ssh -N coder-via-internet` 

* Conectamos con Jupyter Lab: http://127.0.0.1:8001

<br/>


## Integración con GIT (Github o Gitlab)

Si queremos conectar con servidores de Git externos (github o gitlab) podemos preparar nuestra máquina virtual. 

- Abrimos un terminal. 
- Ejecutamos: `ssh-keygen -t rsa -b 2048`
- Guardamos `~/.ssh/id_rsa.pub` en github o gitlab

Si vamos a trabajar contra esos servidores, también es recomendable configurar el cliente git

- `git config --global user.name "Coder Parchis"`
- `git config --global user.email "coderparchis@gmail.com"`


<br/>

## Proyectos relacionados.

Para poder sacarle provecho a esta máquina virtual y al entorno `JupyterLab`necesitarás contenido. Aquí tienes un proyecto interesante, [Taller de Bases de Datos](https://github.com/dvillaj/Taller_BBDD) de Daniel Villanueva. Desde la shell de tu máquina virtual ejecuta el comando `curl` que puedes ver en el siguiente ejemplo. Te permitirá instalar servidores Postgres, Riak, Cassandra, Mongodb, Neo4j, etc. usando Docker

```console
 $ ssh luis@coder
 $ curl -s https://raw.githubusercontent.com/dvillaj/NoSQL-Services/master/scripts/setup.sh | bash
```

