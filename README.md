##Purpose
The linux kernel and u-boot contains lots of files, when we want to broswe the source code,we just want to see these compiled files, and the header files which required.
So this script in this repo is to make a filelist to tell us the files compiled and the header files depended. 

Also, the script would genenate a filelist for the source code broswer IDE/Editor(source insight, Scitools Understand and SlickEdit)

If you use the source insight or Scitools Understand, or SlickEdit to broswe the linux kernel or/and U-boot source code, this script would help you to add the compiled source code(.S,.C) when you create Project.

##Usage
####Video
You may want to see the video `PF_Prj_Gen_example.mkv` in directory usge of repo.
In the video, I show the generation and the usage of the Generation file/project for Understand and SlickEdit.

Also a video(SourceInsight_Example.mkv in usage directory of this repo) shows the generation of filelist for the Source Insight.

####GIF show
######How to generate
Below is a GIF, shows how to generate the filelist and slickedit workspace/project, the parameters of command:

-   Parameter1, directory of compiled source code, here is kernel: ~/github/BBB/Sebastian-BBB-Hibernation-2 
-   Parameter2, Output directory and slickedit workspace(and project) name

![intro](https://raw.githubusercontent.com/tonyho/Generate_Kernel_Uboot_Project_forIDE/master/usage/GenProjectFilelist.gif?raw=true "Generation of filelist")

######Usage of the generation for Source Insight
Below Gif shows the procedure of generation and import
![intro](https://raw.githubusercontent.com/tonyho/Generate_Kernel_Uboot_Project_forIDE/master/usage/SourceInsight_show.gif?raw=true "Slickedit demo")

######Usage of the generation for SlickEdit
![intro](https://raw.githubusercontent.com/tonyho/Generate_Kernel_Uboot_Project_forIDE/master/usage/SlickEdit_show.gif?raw=true "Slickedit demo")

######Usage of the generation for Scitools Understand
![intro](https://raw.githubusercontent.com/tonyho/Generate_Kernel_Uboot_Project_forIDE/master/usage/Understand_show.gif?raw=true "Slickedit demo")

###Text word illustration
####0. compile
compile the kernel or u-boot source code
####1. clone

    git clone https://github.com/tonyho/Generate_Kernel_Uboot_Project_forIDE.git

####2. Generate
    
    cd Generate_kernel_uboot_project_forIDE
    ./PF_Prj_Gen.sh Path_For_Compiled_Kernel(Uboot)_Directory OutPutProjectFileName

This would create the filelist for Understand and Source Insight and the Slickedit Project in Outputprojectfilename.And you can use these output file to genenate the project.

##ToDo
-   Add Eclipse support
-   Add Source Navigator Support
-   Add the dts for kernel/uboot filelist
