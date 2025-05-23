# jupyterlab
Notas para la instalación y configuración de jupyterlab


~~~bash
export MAMBA_ROOT_PREFIX=/opt/jupyter-4.3.6
cd $MAMBA_ROOT_PREFIX
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
eval "$(./bin/micromamba shell hook -s bash)"
micromamba activate
micromamba install jupyterhub jupyterlab jupyterhub-idle-culler jupyter-resource-usage 
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
        ],
        # "admin": True,
    }
]

~~~
