# Predicting the early symptoms of Dementia

*Modelling machine learning techniques using kdb+ to predict the early onset/symptoms of Dementia &amp; Alzheimer's Disease*


## Disclaimer ⚠️

This project was created ~ 2018.

It was recently migrated to this repo. *It was a lift & shift where no logic was optimised or updated.*

`Python3.6` is unfortunately **EOL** now 😔

Also, the `q` logic used in this project is *disorganised*. The lack of namespacing triggers me 🤨

> *Time permitting*, I'll get around to updating the `q` code and updating to a different version of python!

## Getting Started 🎬

Everything is containerised 🐳

Docker must be installed for this project to run successfully. 

If you have **Docker installed** please create a directory called `q` and place your `kc.lic` and `l64` files into this. *For e.g.*:

```bash
$ git clone git@github.com:jdickson1992/predicting_dementia_kdb.git && cd predicting_dementia_kdb

$ mkdir -p q && cp -r $QHOME/* q/

$ tree q -a -L 2
q
├── kc.lic
├── l64
│   └── q
└── q.k

1 directory, 3 files
```

*where `QHOME` is the path to your q installation*

To bring up the `Jupyterq` notebook:

```bash
$ docker-compose up -d
```

The logs of the jupyter container should output a `URL+Token`. 

Grab that value and access it via a browser... *for e.g.:*

```bash
$ docker logs `docker ps --format "{{.Names}}" --filter name=notebook` 2>&1 | grep '127.0' | tail -n 1
     or http://127.0.0.1:8888/?token=ea3bae6a687c231dd2ca41dbba3edf653f92392eebc7a512
```

This should bring up a Jupyter homepage with a list of files. Select `predictingDementia.ipynb`:

