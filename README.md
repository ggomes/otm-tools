# otm-tools
Tools for [Open Traffic Models](https://github.com/ggomes/otm-sim).

# Installation #

+ Java
```
$ java -version
java version "11.0.5" 2019-10-15 LTS
Java(TM) SE Runtime Environment 18.9 (build 11.0.5+10-LTS)
Java HotSpot(TM) 64-Bit Server VM 18.9 (build 11.0.5+10-LTS, mixed mode)
```

+ [Download the latest OTM jar file](https://mymavenrepo.com/repo/XtcMAROnIu3PyiMCmbdY/edu/berkeley/ucbtrans/otm-sim/1.0-SNAPSHOT/). This is the most recent file of the form `otm-sim-1.0-YYYYMMDD.HHMMSS-N-jar-with-dependencies.jar`. 

+ Download the [source code](https://github.com/ggomes/otm-tools).

## Python ##

**1.** `otm-tools` uses `py4j` to communicate between OTM and Python code. The `python/javacnct` folder contains the connector class for the Java side. You will need Apache [Maven](https://maven.apache.org/) to build this code. Follow [these instructions](https://maven.apache.org/install.html) to install Maven if you do not already have it. It can be helpful to set JAVA_HOME to your Java 11 installation if you have multiple versions of Java installed.

**2.** Copy `otm-tools/settings.xml` to `~/.m2`. If you do not have this folder in your home directory, then run the `mvn` command to create it.

**3.** Install the required Python packages, for example with the `conda` YAML file:
```BASH
conda env create -f otmenv.yml 
conda activate otm
```
or using a virtualenv, pip and the requirements.txt file (Java dependencies need to be installe separately):
```BASH
python -m venv otm
source otm/bin/activate
cd otm-tools/python
pip install -r requirements.txt
```

**4.** Build the `py4j` connector. From `otm-tools/python` folder, run 
```BASH
python setup.py develop
```

**5.** Test the installation by running the demos.
```BASH
python demo_load.py
python demo_osm.py
python demo_run_step.py
python demo_run.py
```

## Matlab (not supported) ##

**NOTE** Problems pop up when you change Matlab's Java. These are version-dependent, and difficult to deal with. I will support this again when Matlab upgrades its native Java environment to version 11.

**1.** Change Matlab's Java version to 11.0.5. This is done by setting the `MATLAB_JAVA` environment variable to the full path of the Java 11 folder. For example, on Linux `echo $MATLAB_JAVA` might return
```BASH
/usr/lib/jvm/jdk-11.0.5
```
Here are some additional links on this topic: [MacOS](https://www.mathworks.com/matlabcentral/answers/103056-how-do-i-change-the-java-virtual-machine-jvm-that-matlab-is-using-on-macos), [Windows](https://www.mathworks.com/matlabcentral/answers/130359-how-do-i-change-the-java-virtual-machine-jvm-that-matlab-is-using-on-windows), [Linux](https://www.mathworks.com/matlabcentral/answers/130360-how-do-i-change-the-java-virtual-machine-jvm-that-matlab-is-using-for-linux).

**2.** Point Matlab to the OTM jar file. Follow these [instructions](https://www.mathworks.com/help/matlab/matlab_external/static-path.html) to include the OTM jar file in Matlab's static class path. You will need to restart Matlab after doing this. 

**3.** Add `otm-tools/matlab` (with subfolders) to Matlab's path. See instructions [here](https://www.mathworks.com/help/matlab/matlab_env/add-remove-or-reorder-folders-on-the-search-path.html). 

**4.** Run `otm-tools/matlab/sample_script.m`. If this runs without error, you have succeeded in installing the package.
