# jupyterlab
Notas para la instalación y configuración de jupyterlab


~~~bash
#!/bin/bash
export MAMBA_ROOT_PREFIX=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

_setup(){
#cd $MAMBA_ROOT_PREFIX
curl -L# https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -C $MAMBA_ROOT_PREFIX -xvj bin/micromamba
}

_init(){
eval "$($MAMBA_ROOT_PREFIX/bin/micromamba shell hook -s bash)"
micromamba activate
}

test ! -f $MAMBA_ROOT_PREFIX/bin/micromamba && _setup
_init
~~~

~~~bash
micromamba install python=3.12 jupyterlab jupyterhub jupyterhub-idle-culler pytest-playwright jupyter-lsp-python jupyter-resource-usage 
pip install jupyterlab-theme-toggler
~~~

~~~bash
micromamba create -n tflow-2.18.0 tensorflow=2.18.0 deepxde pyDOE scipy matplotlib \
numpy ipykernel
micromamba run -n tflow-2.18.0 python -m ipykernel install  --name tflow-2.18.0 --display-name "TFlow 2.18.0" --prefix=$MAMBA_ROOT_PREFIX
~~~

---

jupyterhub_config.py

~~~python
import sys                                                                                                             
                                                                                                                       
c.Authenticator.allow_all = True                                                                                       
c.PAMAuthenticator.admin_groups = {'sudo'}                 
                                                           
c.JupyterHub.load_roles = [                                
    {                                                      
        "name": "jupyterhub-idle-culler-role",             
        "scopes": [                                        
            "list:users",                                  
            "read:users:activity",                         
            "read:servers",                                
            "delete:servers",                              
            # "admin:users", # if using --cull-users       
        ],                                                 
        # assignment of role's permissions to:         
        "services": ["jupyterhub-idle-culler-service"],
    }
]

c.JupyterHub.services = [
    {
        "name": "jupyterhub-idle-culler-service",
        "command": [sys.executable,
            "-m", "jupyterhub_idle_culler",
            "--timeout=3600",
            "--cull-every=300",
        ],
        # "admin": True,
    }
]

c.Spawner.args = [
    '--MappingKernelManager.cull_idle_timeout=900',   # 15 min
    '--MappingKernelManager.cull_interval=300',      # Cada 5 min
    '--MappingKernelManager.cull_connected=False',   # No cullar si hay pestaña abierta
]

c.JupyterHub.log_level = 'DEBUG'
c.JupyterHub.extra_log_file = '/var/log/jupyterhub.log'

c.Spawner.environment = {
        "MWI_SHUTDOWN_ON_IDLE_TIMEOUT": "60",
        "MWI_USE_EXISTING_LICENSE": "True",
        "MLM_LICENSE_FILE": "27000@server.mx",
}

~~~

registra-kernel.sh 

~~~bash
#!/bin/bash

MAMBA=micromamba

test $# -le 1 && echo "Uso: $0 entorno Nombre-kernel" && exit 123 
PREFIX=$(dirname $0)

export MAMBA_ROOT_PREFIX=$(dirname $0)
eval "$($MAMBA_ROOT_PREFIX/bin/$MAMBA shell hook -s bash)"
$MAMBA activate

ENV=$1
shift
DISPLAY="$*"


test ! -d $MAMBA_ROOT_PREFIX/envs/$ENV && echo -e "No se encuentea el entorno $ENV en $MAMBA_ROOT_PREFIX/envs:\n$(ls $MAMBA_ROOT_PREFIX/envs | cat -n )" && exit 123 

$MAMBA run -n $ENV python -m ipykernel install --name $ENV --display-name "$DISPLAY" --user

~~~
