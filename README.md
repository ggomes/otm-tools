# otm-tools
Tools for Open Traffic Models

# INSTALLATION #

**Step 1.** Install [JAVA 8](http://www.oracle.com/technetwork/java/javase/downloads/index.html) on your computer.
See how to check your current version of JAVA [here](https://www.java.com/en/download/help/version_manual.xml).

**Step 2.** Obtain the OTM simulator jar file. Either build it from the [code](https://github.com/ggomes/otm-sim) or download it [here](https://mymavenrepo.com/repo/XtcMAROnIu3PyiMCmbdY/edu/berkeley/ucbtrans/otm-sim/1.0-SNAPSHOT/)

**Step 3.** Download the otm-tools repository to your computer. 

**Step 4. (Matlab)** Point Matlab to Java 8. The current version of Matlab uses Java 7, however OTM requires Java 8. Follow these instructions to fix this: 

* **MacOS** - Create an environment variable called `MATLAB_JAVA` in `~/.bash_profile` and set it equal to the full path of your Java installation's JRE folder. You can do so by adding the below line of code to `~/.bash_profile`, making any necessary changes to fit your computer:
```BASH
export MATLAB_JAVA="/Library/Java/JavaVirtualMachines/jdk1.8.0_60.jdk/Contents/Home/jre"
```
Note: You will only be able to use Matlab + Java 8 by opening the Matlab app via Terminal. If you open Matlab from the GUI, it will run with Java 7. <br><br>To check which version of Java your Matlab session is using, type into Matlab's command line prompt: `version -java`

* [**Windows**](https://www.mathworks.com/matlabcentral/answers/130359-how-do-i-change-the-java-virtual-machine-jvm-that-matlab-is-using-on-windows) 

* [**Linux**](https://www.mathworks.com/matlabcentral/answers/130360-how-do-i-change-the-java-virtual-machine-jvm-that-matlab-is-using-for-linux)

**Step 5. (Matlab)** Point Matlab to the OTM jar file. Follow these [instructions](https://www.mathworks.com/help/matlab/matlab_external/static-path.html) to include the OTM jar file in Matlab's static class path. You will need to restart Matlab after doing this. 

**Step 6. (Matlab)** Add otm-tools/matlab **with subfolders** to Matlab's path. See instructions [here](https://www.mathworks.com/help/matlab/matlab_env/add-remove-or-reorder-folders-on-the-search-path.html). 

**Step 7. (Matlab)** Run otm-tools/matlab/sample_script.m. If this runs without error, you have succeeded in installing the package.
