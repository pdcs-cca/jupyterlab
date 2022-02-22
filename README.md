# jupyterlab
Notas para la instalación y configuración de jupyterlab



Usuario root
~~~bash
mkdir -pv /opt/software/apps/python/mambaforge/
chown soporte:soporte /opt/software/apps/python/mambaforge/
~~~

Usuario soporte
~~~bash 
cd /opt/software/apps/python/mambaforge/
curl -LO https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh
bash Mambaforge-Linux-x86_64.sh -b -f -p /opt/software/apps/python/mambaforge
~~~

Instalación install jupyterlab jupyterhub
~~~bash
source /opt/software/apps/python/mambaforge/etc/profile.d/mamba.sh
mamba install jupyterlab jupyterhub nb_conda_kernels
~~~


Creación entorno PAPIME
~~~bash
source /opt/software/apps/python/mambaforge/etc/profile.d/mamba.sh
mamba create -n PAPIME 
mamba install -n PAPIME pynio pyngl  matplotlib xarray netcdf4 cartopy plotly scipy pandas
mamba install -n  PAPIME ipykernel
~~~



