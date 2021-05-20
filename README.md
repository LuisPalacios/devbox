# Developer Box

Este repositorio contiene todo lo necesario para crear, usando [Vagrant](https://www.vagrantup.com/), una máquina virtual orientada al Desarrollo de Software. Está configurada para funcionar con los proveedores VirtualBox o KVM. Además podrá utilizarse para conectar con servicios adicionales de Bases de Datos, cuadernos Jupyter de ejercicios, etc... (mira al final de este README)

<br/>

## Instalación

Clona este repositorio en un ordenador donde tengas VirtualBox o KVM (Libvirt).

```
git clone https://github.com/LuisPalacios/devbox.git
cd devbox
```

* Pega la(s) clave(s) pública SSH de tu ordenador cliente al fichero `bootstrap/public-keys.txt` (mira el ejemplo a continuación).

```
cat ~/.ssh/id_rsa.pub >> bootstrap/public-keys.txt
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

| Nota sobre el Networking: Si te fijas en el fichero `Vagrantfile` verás que he optado por dos estrategias distintas para el Networking. En el caso de un Host Linux opto por establecer una dirección IP fija a la máquina virtual, mientras que en el caso del proveedor VirtualBox utilizo por forwarding, es decir networking privado. |

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

**Conectar con Jupyter Lab**

Conecto con JupyterLab desde la red LAN (o incluso en local). En mi ejemplo utilicé la IP 192.168.1.13 en la sección `override.vm.network "public_network"` del `Vagrantfile`: 

- http://127.0.0.1:8001
- http://192.168.1.13:8001

<br/>

### HOST Mac (o Windows) con VirtualBox

* Otro ejemplo, si lo monto en un Mac o un Windows, configuro el cliente SSH para conectar con la VirtualBox (localhost). Configuro el fichero ~/.ssh/config del cliente y a esta opción la llamo `coderlocal`.

```console
Host coderlocal
  HostName 127.0.0.1
  User luis
  Port 2222
```

**Conecta vía SSH**

Si la estableciste, recuerda que la contraseña es la de tu clave pública/privada

```console
luis @ idefix ➜  ~  ssh coderlocal
Enter passphrase for key '/Users/luis/.ssh/id_rsa':
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

**Conectar con Jupyter Lab**

A partir de ahora ya puedes conectar con los servicios de esta máquina virtual. Observa en el fichero `Vagrantfile` los puertos mapeados, entre ellos el de JupyterLab, por lo tanto podrás acceder en local (desde tu propio ordenador) o desde la red LAN a la que estes conectado:

- http://127.0.0.1:8001
- http://mi-ordernador.dominio.local:8001
  


### Conexión al HOST por internet vía SSH 

Un caso típico es conectar a tu HOST vía un servidor intermedia con SSH. Supongamos el siguiente caso: 

```config
                                                 ┌─┬────────────┬─┐
                                                 │ ├────────────┤ │
                                                 │ │            │ │
                                                 │ │ coder VM   │ │
                                                 │ │            │ │
┌──────────┐               ┌───────────┐         │ └────────────┘ │
│          │   INTERNET    │           │  LOCAL  │                │
│ Cliente  ├──────────────►│ SSHServer ├───────► │  KVM HOST      │
│          │               │           │  LAN    │                │
└──────────┘               └───────────┘         └────────────────┘
                       miserver.midom.org           192.168.1.13

```

El cliente configura port forwarding: 

<br/>
```console
Host coder-via-internet
  HostName miserver.midom.org
  User luis
  Port 12345
  LocalForward 8001 192.168.1.13:8001
```

```console
luis @ idefix ➜  ~  ssh coder-via-internet
luis@coder:~$
```

En el caso de querer mapear el puerto (no necesitas la Shell): 

```console
luis @ idefix ➜  ~  ssh -N coder-via-internet
```

<br/>

**Conectar con Jupyter Lab**

En este caso tendrás acceso vía: 

- http://127.0.0.1:8001

<br/>

## Proyecto relacionados.

Para poder sacarle provecho a esta máquina virtual y al entorno `JupyterLab`necesitarás contenido. Aquí tienes un proyecto interesante, que puedes usar para dotar de contenido a tu máquina virtual. 

* [Taller de Bases de Datos](https://github.com/dvillaj/Taller_BBDD) de Daniel Villanueva. Desde la shell de tu máquina virtual ejecuta el comando `curl` que puedes ver en el siguiente ejemplo. Te permitirá instalar servidores Postgres, Riak, Cassandra, Mongodb, Neo4j, etc. usando Docker

```console
 $ ssh luis@coder
 $ curl -s https://raw.githubusercontent.com/dvillaj/NoSQL-Services/master/scripts/setup.sh | bash
```

