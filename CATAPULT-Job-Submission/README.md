# General job submitter for CATAPULT

A general job submission script for parallel programs for the SLURM batch system on group cluster CATAPULT. Based on Linux Bash Shell.

## Quick reference

Here the configuration of 'VASP6' is used as the example. 

### Commands and corresponding in-line flags

**Nomenclature**  

Upper case letter(s) for job definition + lower case letters for executable + version number

| COMMAND     | FLAGS                                                  | DEFINITION                                               |
|:------------|:------------------------------------------------------:|:---------------------------------------------------------|
| `Pvasp6`    | -in -nd -nc -nt -mem -wt -ref -qos -partition          | Run parallel VASP6 standard version                      |
| `Pvasp6_nc` | -in -nd -nc -nt -mem -wt -ref -qos -partition          | Run parallel VASP6 non-collinear version                 |
| `Xvasp6`    | -x -name -in -nd -nc -nt -mem -wt -ref -qos -partition | Run user-defined multiple jobs (see advanced section)    |
| `SETvasp6`  | No flag                                                | Print the local (user-defined) 'settings' file on screen |
| `HELPvasp6` | No flag                                                | Print instructions on screen                             |

### Command-line flags

In the table below are listed command line flags for script `gen_sub`. The sequence of flags is arbitrary.

| FLAG         | FORMAT | DEFINITION                                                                            |
|:-------------|:------:| :-------------------------------------------------------------------------------------|
| `-name`      | str    | optional, name of the job submission file (default: basename of the first input file) |
| `-x`         | str    | executable lables; see the `LABEL` column of `EXE_TABLE`                              |
| `-qos`       | str    | optional, quality of service (default: the first entry of `QOS`)                      |
| `-partition` | str    | optional, job partition (default: the first entry of `PARTITION`)                     |
| `-nd`        | int    | optional, total number of nodes (default: 1)                                          |
| `-nc`        | int    | optional, total number of cores (default: `Nnode * NCPU_PER_NODE`)                    |
| `-nt`        | int    | optional, number of threads per process (default: `NTHREAD_PER_PROC`)                 |
| `-ng`        | int    | optional, total number of GPUs (default: `Nnode * NGPU_PER_NODE`)                     |
| `-mem`       | int    | optional, total memory request in GB (default: `Nnode * MEM_PER_NODE`)                |
| `-wt`        | str    | walltime in `hh:mm`                                                                   |
| `-in`        | str    | input file                                                                            |
| `-ref`       | str    | optional, name of the previous run                                                    |
| `-set`       | str    | path to the settings file that define the variables                                   |
| `-help`      | -      | Print instructions. Already integrated in command `HELPvasp6`                         |

### Keywords and default values

Parameters are defined in local 'settings' file.
By default it is in the `${HOME}/etc/runVASP6/` directory.

| KEYWORD                   | DEFAULT VALUE            | DEFINITION                                                               |
|:--------------------------|:------------------------:|:-------------------------------------------------------------------------|
| `SUBMISSION_EXT`          | .slurm                   | The extension of job submission script                                   |
| `NCPU_PER_NODE`           | 96                       | Max number of processors per node                                        |
| `MEM_PER_NODE`            | 384                      | Max memory request per node                                              |
| `NTHREAD_PER_PROC`        | 1                        | Number of threads. Multi-threading within 1 CPU is prohibited            |
| `NGPU_PER_NODE`           | -                        | Default number of GPUs per node. Left empty for CPU executables          |
| `GPU_TYPE`                | -                        | Default type of GPUs. Left empty for CPU executables                     |
| `BUDGET_CODE`             | -                        | Not used                                                                 |
| `QOS`                     | normal short interactive | Acceptable Quality of service. By default the code reads the first entry |
| `PARTITION`               | normal gpu               | Acceptable job partition. By default the code reads the first entry      |
| `TIME_OUT`                | 1                        | Unit: min. Time spared for post processing                               |
| `JOB_TMPDIR`              | \[depends\]              | The temporary directory for data files generated during a job            |
| `EXEDIR`                  | \[depends\]              | Directory of executable / Module load command                            |
| `MPIDIR`                  | -                        | Directory of MPI / Module load command, left empty if it is auto-loaded  |
| `EXE_TABLE`               | \[Table\]                | Label (for -x flag) + MPI & executable option combinations               |
| `PRE_CALC`                | \[Table\]                | Saved and temporary names of input files (see following sections)        |
| `REF_FILE`                | \[Table\]                | Saved and temporary names of reference files (see following sections)    |
| `POST_CALC`               | \[Table\]                | Saved and temporary names of output files (see following sections)       |
| `JOB_SUBMISSION_TEMPLATE` | \[script\]               | Template for job submission scripts                                      |

## New user: Basic instructions

Here the configuration of 'VASP6' is used as the example. 

### Configure the job submission script

Taking 'VASP6' as the example. The following steps are necessary to set up a local 'settings' file, where values of keywords are configured according to your local environment:

1. To be safe, visiting other user's directory is not allowed. Clone the repository to a local directory, for example, `${HOME}/scripts/CATAPULT-Job-Submission`. 

``` console
$ bash ${HOME}/scripts/CATAPULT-Job-Submission/VASP6/config_VASP6.sh
```

2. Specify the directory of 'settings' file. By default, it is `${HOME}/etc/runVASP6/settings`.  
3. Specify the directory / command of executable. Typically default value is sufficient. Press 'Enter' to continue.  
4. Specify the directory / command of MPI executable. Typically default value is sufficient. Press 'Enter' to continue.  
5. After the instruction is printed out, use the following command to enable commands:

```
$ source ~/.bashrc
```

### Use commands

After configuration, commands to generate the corresponding job submission file (slurm file) are defined in `~/.bashrc`.
Detailed definitions of commands can be found in the previous section and by `HELPvasp6` command.
For example, the following command generates and submits a slurm file for input file 'mgo.in'.
The job uses 1 node and the number of CPUs per node is read from the `NCPU_PER_NODE` keyword in settings file.
The maximum time allowance for this job is 1 hour.

``` console
$ Pvasp6 -in mgo.in -nd 1 -wt 01:00
$ sbatch mgo.slurm
```

Alternatively, `-nc` flag can be specify the total number of CPUs used.
If `-nc` < `NCPU_PER_NODE`, a single node is used; otherwise CPUs are equally partitioned over the minimum nodes needed.
When both `-nd` and `-nc` are specified, `-nc/-nd` is compared with `NCPU_PER_NODE` and the former one must be smaller.
`-nc` CPUs are equally partitioned over `-nd` nodes.
If neither of them is specified, `NCPU_PER_NODE` is read from settings file and `-nd` = 1.
Warning message will be given.
The following job requests 2 nodes of 12 CPUs and a 'short' QoS job.

``` console
$ Pvasp6 -in mgo.in -nc 24 -nd 2 -wt 01:00 -qos short
```

It is highly recommended to generate slurm files in the same directory as input files, though in principle, the user can generate slurm files and get the SLURM output file in a separate directory.
This feature is rarely tested and might lead to unexpected results --- and somewhat meaningless because all the job-related files, including the software output, are stored in the input directory.

`-nt` flag specifies number of threads per process.
If not specified, `NTHREAD_PER_PROC` are read from settings file.
Number of processes = Total number of CPUs / `-nt`.
Multi/Sub-CPU threading is forbidden.
The following example requests 2 CPUs but 4 threads per process, which leads to error:

``` console
$ Pvasp6 -in mgo.in -nc 2 -nt 4 -wt 01:00
```

The following example requests 8 CPUs distributed on 2 nodes.
On each node, there are: 4 CPUs, 1 process.
Each process containes 4 threads and each thread is run on 1 CPU.
The memory request is 4GB

``` console
$ Pvasp6 -in mgo.in -nc 8 -nt 4 -nd 2 -wt 01:00 -mem 4
```

If `-nc` is not an integer multiply of `-nd` or `-nt`, the number of CPUs requested might change accordingly by rounding it to the nearest integer that is smaller than the specified one.
For example, 4 CPUs instead of 5 are used:

``` console
$ Pvasp6 -in mgo.in -nc 5 -nd 2 -wt 01:00
```

When a GPU queue is chosen, `-ng` becomes valid.
The total number of GPUs divided by the total number of nodes should not be larger than the value given in `NGPU_PER_NODE` of settings file.
If `-ng` is not given, by default the code uses `NGPU_PER_NODE` times number of nodes.
The following example uses a GPU version of VASP, 1 GPU per node:

``` console
$ Gvasp6 -partition gpu -in mgo.in -nd 2 -ng 2 -wt 01:00
```

### Common Outputs

Although codes/software differ from each other, 2 common outputs are generated. 

**.out file**  
Output information of the code.
Also includes the input file and basic information from the job submission script, such as the path to the ephemeral directory and files copied.

**slurm-`${SLURM_JOB_ID}`.out file / .log file**  
A verbose version output, error and warning messages (screen outputs) of job submission script & MPI, for debugging.
Besides the basic information included in .out file, it includes the list of scripts and commands used, synchronization of files and the list of files in the ephemeral directory.
The specific name of this output, either 'slurm-`${SLURM_JOB_ID}`.out' or '.log' or anything else, depends on the specifications in the `JOB_SUBMISSION_TEMPLATE` field of settings file.

### When a job terminates

There are 4 probable occasions of job termination. If an ephemeral directory is defined, i.e., `JOB_TMPDIR` in settings is not 'nodir', temporary files generated during calculation might be either in the output directory or in the ephemeral directory.

1. For normal termination, all the non-empty files are kept in the output directory, with `SAVED` names. The ephemeral directory will be removed.  
2. If the job is terminated due to exceeding walltime, same as normal termination.  
3. If the job is terminated due to error, same as normal termination.  
4. If the job is killed by user, the ephemeral directory remains intact when `JOB_TMPDIR` is not 'node' (see sections below). The user can refer to '.out' file or '.log' file for the path to ephemeral directory and manually move them to output directory. Note that all the inputs are copied from local so there is not need to copy inputs back.  

### How to use settings file

The settings file is a dictionary for reference.
Although all the necessary keywords are configured automatically, the user can always change the value of keywords according to their needs.
Refer to advanced section for more information.


## Experienced user & Developer: Advanced instructions

### Multiple jobs and 'X' command

The 'X' command allows the maximum flexibility for users to define a batch job.
Taking VASP6 as the example, using `Xvasp6` can sequentially run multiple jobs.
The following code illustrates how to integrate SCF and band calculations of mgo into a single slurm file:

``` console
$ Xvasp6 -name mgo-band -qos short -nd 1 -mem 8 -x std -in mgo.in -wt 01:00 -ref no -x std -in band.in -wt 00:30 -ref mgo
```

To run `Xvasp6` command, the number of in-line flags should follow certain rules:

1. `-name` flag should appear at most only once, otherwise the last one will cover the previous entries. If left blank, the slurm file will be named as `mgo_et_al.slurm` (taking the previous line as an example).  
2. `-nd` `-nc` `-nt` `-ng` `-mem` flags should appear at most once. If not specified, `NCPU_PER_NODE`, `NTHREAD_PER_PROC`, `NGPU_PER_NODE` and `MEM_PER_NODE` are read from settings file and `-nd` is set to 1.  
3. `-x` `-in` `-wt` flags should be always in the same length, otherwise error is reported. 
4. `-wt` flag defines the walltime for individual jobs. For each job, by default 1 minute are spared for post-processing. Check the `TIME_OUT` keyword in settings file.   
5. `-ref` flags should have either 0 length or the same length as `-x`. If no reference is needed, that flag should be matched with value 'no'. See the line above.  

When job terminates, the output of each calculation is available in corresponding .out files.
If input files have the same name, for example, CRYSTAL17 mgo.d12 and mgo.d3, the output will be attached in the same .out file, i.e., mgo.out, with a warning message dividing the files.
Check [testcase of CRYSTAL17 Imperial HPC version](https://github.com/Spica-Vir/HPC-job-submission/tree/main/archived/Imperial-HPC-Job-Submission/CRYSTAL17/testcase).
On the other hand, SLURM-related outputs, slurm and .log files, are defined by the `-name` flag.

### Edit the local 'settings' file

In the current implementation, 'settings' is the only file in local environment that can be edited by the user according to needs.
When formatting the 'settings' file, please be noted:

1. Empty lines between keywords and their values are forbidden.  
3. Multiple-line values for keywords other than `EXE_TABLE`, `PRE_CALC`, `FILE_EXT`, `POST_CALC` and `JOB_SUBMISSION_TEMPLATE` are forbidden.  
4. Dashed lines and titles for 'table' keywords are used as separators and are not allowed to be removed.  
5. The slurm template attached during initialization is only compatible with the default settings. For user-defined executables, changes might be made accordingly in `JOB_SUBMISSION_TEMPLATE`.

**`JOB_TMPDIR`**

4 options are available for this keywords:

1. Left blank for 'default' : The temporary directory will be created as a sub-directory in the input directory, with name `jobname_${SLURM_JOB_ID}/`  
2. 'nodir' : The job will be run in the current directory and no copy/delete happens. Applicable if the code has bulit-in temporary file management system or requires minimum I/O (usually the case for serial jobs).
3. 'node' : Node-specific temporary files are distributed to the node memory `/tmp/jobname_${SLURM_JOB_ID}/`. Recommanded for large jobs. If the job is killed by the user, temporary files cannot be saved.
5. A given directory, such as `${EPHEMERAL}` : The temporary directory will be created as a sub-directory under the given one, with the name `jobname_${SLURM_JOB_ID}/`.


*Comments on the 'node' option*

It is suggested to slightly increase `TIME_OUT` when using large number of nodes, because directories on every node are scanned in serial to find the latest modificaions of the file when job terminates.
Here is an example output run on two nodes:

```
 ============================================
 Post Processing Report
 --------------------------------------------
 Begining of post processing : Tue 18 Feb 2025 09:34:39 PM
 --------------------------------------------
 List of saved files from NODE nid002413
   TEMPORARY            SAVED
 WARNING! Duplicated file: rerestart.gui is covered by fort.34.
   fort.34              rerestart.gui                                         6514     Feb 18 21:27
   SCFOUT.LOG           rerestart.SCFLOG                                      35040    Feb 18 21:28
   FREQINFO.DAT.tsk0    rerestart.freqtsk/FREQINFO.DAT.tsk0                   18235986 Feb 18 21:33
   FREQINFO.DAT.tsk1    rerestart.freqtsk/FREQINFO.DAT.tsk1                   18235986 Feb 18 21:33
   FREQINFO.DAT.tsk2    rerestart.freqtsk/FREQINFO.DAT.tsk2                   18235986 Feb 18 21:27
   FREQINFO.DAT.tsk3    rerestart.freqtsk/FREQINFO.DAT.tsk3                   18235986 Feb 18 21:27
   fort.13              rerestart.f13                                         3569544  Feb 18 21:28
 --------------------------------------------
 List of saved files from NODE nid002448
   TEMPORARY            SAVED
 WARNING! Duplicated file: rerestart.gui is the latest and kept.
 WARNING! Duplicated file: rerestart.freqtsk/FREQINFO.DAT.tsk0 is the latest and kept.
 WARNING! Duplicated file: rerestart.freqtsk/FREQINFO.DAT.tsk1 is the latest and kept.
 WARNING! Duplicated file: rerestart.freqtsk/FREQINFO.DAT.tsk2 is covered by FREQINFO.DAT.tsk2.
   FREQINFO.DAT.tsk2    rerestart.freqtsk/FREQINFO.DAT.tsk2                   18235986 Feb 18 21:33
 WARNING! Duplicated file: rerestart.freqtsk/FREQINFO.DAT.tsk3 is covered by FREQINFO.DAT.tsk3.
   FREQINFO.DAT.tsk3    rerestart.freqtsk/FREQINFO.DAT.tsk3                   18235986 Feb 18 21:33
 WARNING! Duplicated file: rerestart.f13 is the latest and kept.
 --------------------------------------------
```

**`EXE_TABLE`** 

For each job submission script, multiple executables can be placed in the same directory, `EXEDIR`.
The corresponding commands to launch the executables are listed in `EXE_TABLE`.
The following table gives information of each column. 

| NAME                  | RECOGNIZABLE LENGTH | EXPLANATION                                                               |
|:----------------------|:-------------------:| :-------------------------------------------------------------------------|
| `LABEL`               | 11                  | Alias of MPI+executable combination. Input of `-x` flag. No space allowed |
| `MPI & OPTION`        | 61                  | In-line commands of MPI, such as 'mpiexec'                                |
| `EXECUTABLE & OPTION` | 61                  | In-line commands of executable, such as `gulp-mpi < [job].gin`            |
| `DEFINITION`          | Not read            | Definitions for reference                                                 |

Variable symbols `${V_VARIABLE}` defined under keyword `JOB_SUBMISSION_TEMPLATE` are, in principle, compatible in `MPI & OPTION` and `EXECUTABLE & OPTION` columns.
But such practice is not recommended to keep the structure clear and consistent.
Using the 'pseudo' regex scheme (see below) and exporting environment variables in qsub file is preferred unless in line commands + variables are inevitable.
For the definitions of `${V_VARIABLE}`, see below.

**`PRE_CALC`, `REF_FILE` and `POST_CALC`**

Both tables function as file references before computation.
Although `PRE_CALC` and `REF_FILE` share almost the same rules (see below), it is recommended that files with the same name as input file (the value of `-in` flag) should be listed in the former and the input reference (`-ref` flag) listed in the latter.
The `SAVED` column specifies the file names in input directory, while `TEMPORARY` specifies the file names in ephemeral directory. 
Lengths of both `SAVED` and `TEMPORARY` columes should be 21 characters to ensure the values can be read.
The `DEFINITION` column will not be scanned.
This part is skipped if `JOB_TMPDIR` is 'nodir'.

In practice, `run_exec` and `post_proc` scan all the formats listed and moves all the matching files forward and backward.
Missing files will in any case not lead to abruption of jobs since file existence has been checked when generating slurm files. 
However, the priority changes when duplicate files are found in distination directory (ephemeral for `PRE_CALC` and `REF_FILE`, input for `POST_CALC`).
In all cases, that would lead to a warning message in both .out and .log files.

1. When duplicate file is defined in `PRE_CALC`, `run_exec` will cover the old one with the new entry, unless the old one is the file specified by `-in` flag.  
2. When duplicate file is defined in `REF_FILE`, `run_exec` will ignore the new entry and keep the old one.  
3. When duplicate file is defined in `POST_CALC`, `post_proc` will cover the old one with the new entry  

**A 'pesudo' regex scheme**

To ensure the generality, a 'pseudo' regex is used. Note that not all the sym

| SYMBOL  | Definition                                                                                   |
|:--------|:---------------------------------------------------------------------------------------------|
| `[job]` | Value of `-in` flag without extension and upper-level folder                                 | 
| `[ref]` | Value of `-ref` flag without extension and upper-level folder                                |
| `*`     | Match any character for any times. A single `*` in destination means keep the original name  |
| `/`     | Creat a folder rather than copy as files                                                     |

Note:

1. Typically the `text*` expression is used in `SAVED` column and `*` is used in `TEMPORARY` column. `/` can be used in both.  
2. In `SAVED` colume, both `PRE_CALC` and `POST_CALC` allow `[job]` only, while `REF_FILE` allows `[ref]` only.  
3. In practice, any text begins with `[job` or `[ref` and ends with `]` are recognized and substituted. In fact, in files configured eariler, keywords `[jobname]` and `[refname]` were used. New keywords are adopted to spare space for command options.  
4. In principle, `[job]` and `[ref]` can be placed at any part of the file name, but it is strongly recommended to keep them as the beginning of file name to keep the consistency.

**`JOB_SUBMISSION_TEMPLATE` and `${V_VARIABLE}`**

Job submission template offers a template for qsub files, which contains essential set-ups perior to the parallel jobs and post-processing commands after the parallel job is finished.
Variable symbols `${V_VARIABLE}` are defined in this block for substitution by the `gen_sub` script.
Their values and difinitions are listed in the table below.

| SYMBOL          | Definition                                           |
|:----------------|:-----------------------------------------------------|
| `${V_JOBNAME}`  | Job name                                             |
| `${V_ND}`       | Number of nodes                                      |
| `${V_NCPU}`     | Number of CPUs per node                              |
| `${V_MEM}`      | Memory allocation per node, in GB                    |
| `${V_PROC}`     | Number of processes per node                         |
| `${V_TRED}`     | Number of threads per process                        |
| `${V_NGPU}`     | Number of GPUs per node                              |
| `${V_TGPU}`     | Type of GPU node                                     |
| `${V_TWT}`      | Total wall time (timeout + post processing)          |
| `${V_TPROC}`    | Total number of processes (`${V_PROC} * ${V_ND}`)    |
| `${V_BUDGET}`   | Project budget code                                  |
| `${V_PARTITION}`| Job partition                                        |
| `${V_QOS}`      | Quality of service                                   |
| `${V_GENSUB}`   | Job execution commands given by `EXE_TABLE`          |

### Structure of the repository

Scripts in the main folder, i.e., `gen_sub`, `run_exec`, `post_proc` and `settings_template` are common scripts for job submission and post processing, of which the first 3 are executable. `settings_template` will be named as `settings` after being configured.

`gen_sub` - Process the options in command line, execute necessary checks (file existence, walltime and node format) and generate the slurm file.  
`run_exec` - Move and rename input files from the home directory to the ephemeral directory, sync nodes and launch (usually) parallel jobs.  
`post_proc` - Save output files to the home directory and remove the ephemeral directory.  
`settings_template` - A formatted empty list of keywords. It will be configured when running configure scripts such as `config_VASP6.sh`.
`version_control.txt` - Information of version numbers and authorship.

In the sub-folders with specific names of simulation codes.
Taking VASP6 as the example, the configuration file is `config_VASP6.sh`, which is called during installation.
The `run_help` script (a rather easy one) is launched by `HELPvasp6` command.
The `settings_example_VASP6` gives an example of configured settings file and the `testcase` directory contains an example run.

The basic principle of this job submission script is illustrated in the figure below (though it is used for PBS batch systems, which is quite similar in principle):

![The Structure of Job Submitter](structure.svg)

### How to generate a configuration file

Configurations scripts `config_CODE.sh` and help information `run_help` (a rather simple one) are code-specific so are stored separately in sub-folders with code names.
Typically the core sriptes `gen_sub` `run_exec` and `post_proc` do not need revision unless bug is identified.
Examples (`config_example_VASP6.sh` and `run_help_example_VASP6`) are placed in the main directory for illustrating proposes.
Several considerations suggested:

1. Title line and version number, which should be provided in a separate file [version\_control.txt](https://github.com/Spica-Vir/HPC-job-submission/blob/main/CATAPULT-Job-Submission/version_control.txt), which has clear instructions for reference.  
3. Script directory: The default directory  
4. Executable directory: The default executable directory or `module load` command  
5. MPI directory: The default executable directory or `module load` command   
6. Default parameters for parallel jobs: Cores per node and GPUs
7. `EXE_TABLE`: The correct in-line commands to launch the job and a simple alias for it  
8. `PRE_CALC`: General format of inputs  
9. `REF_FILE`: General format of references  
10. `POST_CALC`: General format of outputs  
11. `JOB_SUBMISSION_TEMPLATE`: Specific environmental setups for the code, such as other modules needed (especially when the code is dynamically linked), or important environmental variables if the executable is directly called  
12. Alias: Check the nomenclature of commands in quick reference

## Program specific instructions
### VASP6

**Default settings file**

`${HOME}/etc/runVASP6/settings`

**Default executable**

module load vasp/6.5.0-mkl (shared module)

| LABEL | ACTUAL IN-LINE COMMAND                                     |
|:-----:|:-----------------------------------------------------------|
| std   | unset I_MPI_PMI_LIBRARY; mpirun -np ${V_TPROC} vasp_std    | 
| ncl   | unset I_MPI_PMI_LIBRARY; mpirun -np ${V_TPROC} vasp_std    |
| gam   | unset I_MPI_PMI_LIBRARY; mpirun -np ${V_TPROC} vasp_std    |

**Default ephemeral directory**

`${HOME}/scratch`

**Commands**  

`Pvasp6` `Pvasp6_g` `Pvasp6_nc` `Xvasp6` `SETvasp6` `HELPvasp6`

**Command used for testcase**

``` console
$ Xvasp6 -name fccSi_band -qos short -nc 4 -mem 8 -x std -in fccSi.in -wt 00:05 -ref no -x std -in fccSi_band.in -wt 00:05 -ref fccSi
```
