**TOC**: 

1. [ ๐ Introduction ](#desc)
2. [ โ ๏ธ Disclaimer ](#disclaimer)
3. [๐ฌ Getting Started](#start)
4. [๐ฃ Issues](#issues)

<a name="desc"></a>
# Predicting the early symptoms of Dementia ๐ง 

*Modelling machine learning techniques using kdb+ to predict the early symptoms of Dementia &amp; Alzheimer's Disease*.

I created a series of blogs describing this project over at https://jdickson.dev/ ๐

The full Jupyter notebook can be found here https://jdickson.dev/files/predictingdementia ๐

Datasets used in this project have been provided by the **Open Access Series of Imaging Studies (OASIS)**. Acknowledgements:

> OASIS-1: Cross-Sectional: Principal Investigators: D. Marcus, R, Buckner, J, Csernansky J. Morris; P50 AG05681, P01 AG03991, P01 AG026276, R01 AG021910, P20 MH071616, U24 RR021382
> 
> OASIS-2: Longitudinal: Principal Investigators: D. Marcus, R, Buckner, J. Csernansky, J. Morris; P50 AG05681, P01 AG03991, P01 AG026276, R01 AG021910, P20 MH071616, U24 RR021382

<a name="disclaimer"></a>
## Disclaimer โ ๏ธ

This project was created ~ 2018.

It was recently migrated to this repo. *It was a lift & shift where no logic was optimised or updated.*

`Python3.6` is unfortunately **EOL** now ๐

Also, the `q` logic used in this project is *disorganised*. The lack of namespacing triggers me ๐คจ. 

Similarly, I would like to think I've grasped `q` better since there ... so the logic could almost certainly be improved.

> *Time permitting*, I'll get around to updating the `q` code and updating to a different version of python!

Oh, this has **only** been tested on `amd64`, **not** M1 (`arm64`) chips (see [here](https://github.com/jupyter/docker-stacks/issues/1549) for possible issues)

**Update**
- Tested successfully on `M1` and `Linix` using **Docker Desktop 4.16.2**

<a name="start"></a>
## Getting Started ๐ฌ

Everything is containerised ๐ณ

Docker must be installed for this project to run successfully. 

If you have **Docker installed** please create a directory called `q` and place your `kc.lic` and `l64` files into this. *For e.g.*:

```bash
$ git clone git@github.com:jdickson1992/predicting_dementia_kdb.git && cd predicting_dementia_kdb

$ mkdir -p q && cp -r $QHOME/* q/

$ tree q -a -L 2
q
โโโ kc.lic
โโโ l64
โ   โโโ q
โโโ q.k

1 directory, 3 files
```

*where `QHOME` is the path to your q installation*

---

### Jupyter notebook ๐
To bring up the `Jupyterq` notebook:

```bash
$ docker-compose up -d
```

*The base image that is used to create the jupyter container takes a few minutes*

The logs of the jupyter container should output a `<url?token>` path. Grab that value and paste it in a browser... *for e.g.:*

```bash
$ docker logs `docker ps --format "{{.Names}}" --filter name=notebook` 2>&1 | grep '127.0' | tail -n 1
  http://127.0.0.1:8888/?token=ea3bae6a687c231dd2ca41dbba3edf653f92392eebc7a512
```

Voilร , this should bring up a homepage where a notebook called `predictingDementia.ipynb` exists. Click on the file to access the notebook.

*Tip*: `Ctrl + Enter` will execute each cell within the notebook. If you just want the whole notebook to run:

<img width="749" alt="Screenshot 2023-02-16 at 12 21 39" src="https://user-images.githubusercontent.com/47530786/219366279-be601843-221d-43c4-91a4-cf4dc81564d3.png">

---

### Web GUI ๐

A container should have also been created that houses a web application.

It should be accessible via a browser by going to the address: http://localhost:8080.

The *placeholder* connection field **should** be populated with the correct connection details to the notebook. 

*Just click **connect*** ๐ฑ๏ธ

> If the *models are being trained*, the q process **could be blocked** momentarily. Try again in a few minutes.
>
> If models are yet to be trained. You'll receive a message back in the GUI whenever you attempt to submit values.

---

***Not exhibiting signs of Dementia*** โ

![image](https://user-images.githubusercontent.com/47530786/219424089-c1562125-38d8-43c7-b2cc-8d028844e9e5.png)

***Exhibiting signs of Dementia*** โ

![image](https://user-images.githubusercontent.com/47530786/219424571-92750fe4-9ffb-4355-8e44-8eb77a2019cd.png)

*The GUI supports predictions using different algos*

<details open>
<summary>โ ๏ธ Note: this application does not actually predict Dementia ๐ โ ๏ธ</summary>

*Itโs important to remember that the dataset used for this experiment was small, and as a result, models trained on this set, ran the risk of overfitting where models were more susceptible to seeing patterns that didnโt exist, resulting in high variance and poor generalisation on a test dataset.*

</details>

<a name="issues"></a>
## Issues ๐ฏ


- [ ] Have you dropped your `l64` and `kc.lic` in the `q` directory ๐
  - The base image uses CentOS which is a **Linux distribution**. `m64` wont work here!
 
- [ ] Have you installed the latest Docker update? ๐ณ
  - This has been tested on Docker Desktop `4.16.2` / `4.16.3`.

- [ ] Is the evaluation taking too long? ๐
  - There's an environment variable called `THREADS` defined in the docker-compose [file](https://github.com/jdickson1992/predicting_dementia_kdb/blob/main/docker-compose.yml#L11).
  - This **controls** how many parallel jobs run during *hyperparameter* tuning (GridSearch etc).
  - Generally, *more threads = better performance*.
  - How much resources are available to Docker?
    - *Can you give more CPU / Memory?*
