#!/bin/bash

function welcome_msg {
    core_version=$(grep 'core' $CTRLDIR/version_control.txt | awk '{printf("%s", substr($0,22,11))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1')
    core_date=$(grep 'core' $CTRLDIR/version_control.txt | awk '{printf("%s", substr($0,33,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1')
    core_author=$(grep 'core' $CTRLDIR/version_control.txt | awk '{printf("%s", substr($0,54,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1')
    core_contact=$(grep 'core' $CTRLDIR/version_control.txt | awk '{printf("%s", substr($0,75,31))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1')
    core_acknolg=$(grep 'core' $CTRLDIR/version_control.txt | awk '{printf("%s", substr($0,106,length($0)))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1')
    code_version=$(grep 'VASP6' $CTRLDIR/version_control.txt | awk '{printf("%s", substr($0,22,11))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1')
    code_date=$(grep 'VASP6' $CTRLDIR/version_control.txt | awk '{printf("%s", substr($0,33,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1')
    code_author=$(grep 'VASP6' $CTRLDIR/version_control.txt | awk '{printf("%s", substr($0,54,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1')
    code_contact=$(grep 'VASP6' $CTRLDIR/version_control.txt | awk '{printf("%s", substr($0,75,31))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1')
    code_acknolg=$(grep 'VASP6' $CTRLDIR/version_control.txt | awk '{printf("%s", substr($0,106,length($0)))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1')
    cat << EOF
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
    _   _   _   _______   _          ___        ___       _______    _______   
   | | | | | | |  _____| | |       / ___ \    / ___ \    / _   _ \  |  _____|  
   | | | | | | | |       | |      / /   \_\  / /   \ \  | / \ / \ | | |        
   | | | | | | | |____   | |     | |        | |     | | | | | | | | | |____    
   | | | | | | | |____|  | |     | |        | |     | | | | | | | | | |____|   
   | | | | | | | |       | |     | |     __ | |     | | | | | | | | | |        
   | \_/ \_/ | | |_____  | |_____ \ \___/ /  \ \___/ /  | | |_| | | | |_____   
    \__/\___/  |_______| |_______| \ ___ /    \ ___ /   |_|     |_| |_______|  

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VASP6 job submission script for CATAPULT - Setting up

Job submission script installed date : $(date)
Batch system                         : SLURM
Job submission script version        : $code_version ($code_date)
Job submission script author         : $code_author ($code_contact)
Core script version                  : $core_version ($core_date)
Job submission script author         : $core_author ($core_contact)

$code_acknolg
$core_acknolg

EOF
}

function get_scriptdir {
    WORK="/work/${HOME#*/home/}"
    cat << EOF
================================================================================
    Note: all scripts should be placed into the same directory!
    Please specify your installation path.

    Default Option
    $WORK/etc/runVASP6

EOF

    read -p " " SCRIPTDIR

    if [[ -z $SCRIPTDIR ]]; then
        SCRIPTDIR=$WORK/etc/runVASP6
    fi

    if [[ ${SCRIPTDIR: -1} == '/' ]]; then
        SCRIPTDIR=${SCRIPTDIR%/*}
    fi

    SCRIPTDIR=$(realpath "$SCRIPTDIR" 2>&1 | sed -r 's/.*\:(.*)\:.*/\1/' | sed 's/[[:space:]]//g') # Ignore errors
    source_dir=$(realpath "$(dirname "$0")")
    if [[ $source_dir == $SCRIPTDIR ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    ERROR: You cannot specify source directory as your working directory. 
    Your option:  $SCRIPTDIR

EOF
        exit
    else
        ls $SCRIPTDIR > /dev/null 2>&1
        if [[ $? == 0 ]]; then
            cat << EOF
--------------------------------------------------------------------------------
    Warning: Directory exists - currnet folder will be removed.

EOF
            rm -r $SCRIPTDIR
        fi
    fi
}

# function get_budget_code {
#     cat << EOF
# ================================================================================
#     Please specify your budget code:

# EOF

#     read -p " " BUDGET_CODE

#     if [[ -z $BUDGET_CODE ]]; then
#         cat << EOF
# --------------------------------------------------------------------------------
#     Error: Budget code must be specified. Exiting current job. 

# EOF
#         exit
#     fi
# }

function set_exe {
    cat << EOF
================================================================================
    Please specify the directory of VASP6 exectuables, 
    or the command to load VASP6 modules

    Default Option
    module load vasp/6.5.0-mkl

EOF

    read -p " " EXEDIR

    if [[ -z $EXEDIR ]]; then
        EXEDIR='module load vasp/6.5.0-mkl'
    fi

    if [[ ! -d $EXEDIR && ($EXEDIR != *'module load'*) ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    Error: Directory or command does not exist. Check your input: $EXEDIR

EOF
        exit
    fi

    if [[ $EXEDIR == *'module load'* ]]; then
        $EXEDIR > /dev/null 2>&1
        if [[ $? != 0 ]]; then
            cat << EOF
--------------------------------------------------------------------------------
    Error: Module specified not available. Check your input: $EXEDIR

EOF
            exit
        fi
        # Remove modules to avoid conflicts
        printf '%s\n' "$EXEDIR" | sed 's|load|rm|g' | bash > /dev/null 2>&1
    fi
}

function set_mpi {
    cat << EOF
================================================================================
    Please specify the directory of MPI executables or mpi modules

    Default Option
    <empty>

EOF

    read -p " " MPIDIR

    if [[ -z $MPIDIR ]]; then
        MPIDIR=''
    else
        if [[ ! -d $MPIDIR && ($MPIDIR != *'module load'*) ]]; then
            cat << EOF
--------------------------------------------------------------------------------
    Error: Directory or command does not exist. Check your input: $MPIDIR

EOF
            exit
        fi
    fi

    if [[ $MPIDIR == *'module load'* ]]; then
        $MPIDIR > /dev/null 2>&1
        if [[ $? != 0 ]]; then
            cat << EOF
--------------------------------------------------------------------------------
    Error: Module specified not available. Check your input: $MPIDIR

EOF
            exit
        fi
        # Remove modules to avoid conflicts
        printf '%s\n' "$MPIDIR" | sed 's|load|rm|g' | bash > /dev/null 2>&1
    fi
}

function copy_scripts {
    mkdir -p $SCRIPTDIR
    cp $CTRLDIR/settings_template $SCRIPTDIR/settings

    cat << EOF
================================================================================
    Moving and modifying scripts at $SCRIPTDIR/
EOF
}

# Configure settings file

function set_settings {
    SETFILE=$SCRIPTDIR/settings

    # Values for keywords
    sed -i "/SUBMISSION_EXT/a\.slurm" $SETFILE
    sed -i "/NCPU_PER_NODE/a\96" $SETFILE
    sed -i "/MEM_PER_NODE/a\384" $SETFILE
    sed -i "/NTHREAD_PER_PROC/a\ 1" $SETFILE
    sed -i "/NGPU_PER_NODE/a\ 1" $SETFILE
    # sed -i "/BUDGET_CODE/a\ $BUDGET_CODE" $SETFILE
    sed -i "/QOS/a\normal" $SETFILE
    sed -i "/PARTITION/a\normal" $SETFILE
    sed -i "/TIME_OUT/a\1" $SETFILE
    sed -i "/JOB_TMPDIR/a\/tmp" $SETFILE
    sed -i "/EXEDIR/a\ $EXEDIR" $SETFILE
    sed -i "/MPIDIR/a\ $MPIDIR" $SETFILE

    # Executable table

    LINE_EXE=$(grep -nw 'EXE_TABLE' $SETFILE)
    LINE_EXE=$(( ${LINE_EXE%%:*}+3 ))
    sed -i "${LINE_EXE}a\std        srun --distribution=block:block                              vasp_std                                                     Standard parallel VASP" $SETFILE
    sed -i "${LINE_EXE}a\ncl        srun --distribution=block:block                              vasp_ncl                                                     Non-collinear parallel VASP" $SETFILE
    sed -i "${LINE_EXE}a\gam        srun --distribution=block:block                              vasp_gam                                                     Gamma-only VASP" $SETFILE

    # Input file table

    LINE_PRE=$(grep -nw 'PRE_CALC' $SETFILE)
    LINE_PRE=$(( ${LINE_PRE%%:*}+3 ))
    sed -i "${LINE_PRE}a\[job].vasp           POSCAR               Geometry input" $SETFILE
    sed -i "${LINE_PRE}a\[job].in             INCAR                Input parameters" $SETFILE
    sed -i "${LINE_PRE}a\[job].kpt            KPOINTS              K point grid" $SETFILE
    sed -i "${LINE_PRE}a\[job].pp             POTCAR               Pseudopotential file" $SETFILE
    sed -i "${LINE_PRE}a\[job].in.h5          vaspin.h5            Input file in H5 format" $SETFILE

    # Reference file table

    LINE_REF=$(grep -nw 'REF_FILE' $SETFILE)
    LINE_REF=$(( ${LINE_REF%%:*}+3 ))
    sed -i "${LINE_REF}a\[ref].chg            CHGCAR               Charge density file" $SETFILE
    sed -i "${LINE_REF}a\[ref].wave           WAVECAR              Wavefunction file" $SETFILE
    sed -i "${LINE_REF}a\[ref].wave.h5        vaspwave.h5          Wavefunction file in H5 format" $SETFILE

    # Post-processing file table

    LINE_POST=$(grep -nw 'POST_CALC' $SETFILE)
    LINE_POST=$(( ${LINE_POST%%:*}+3 ))

    sed -i "${LINE_POST}a\[job].plt.chg        CHG                  Charge density file for visualization" $SETFILE
    sed -i "${LINE_POST}a\[job].chg            CHGCAR               Charge density file" $SETFILE
    sed -i "${LINE_POST}a\[job].opt.vasp       CONTCAR              Optimized atomic positions" $SETFILE
    sed -i "${LINE_POST}a\[job].dos            DOSCAR               Density of states file" $SETFILE
    sed -i "${LINE_POST}a\[job].eigen          EIGENVAL             Eigenvalue file" $SETFILE
    sed -i "${LINE_POST}a\[job].elf            ELFCAR               Electron localization function file" $SETFILE
    sed -i "${LINE_POST}a\[job].1bz.kpt        IBZKPT               Explicit 1st Brillouin zone k-points" $SETFILE
    sed -i "${LINE_POST}a\[job].pot            LOCPOT               Local potential file" $SETFILE
    sed -i "${LINE_POST}a\[job].oszi           OSZICAR              Information on each electronic and ionic SCF step" $SETFILE
    sed -i "${LINE_POST}a\[job].out            OUTCAR               Output file" $SETFILE
    sed -i "${LINE_POST}a\[job].par.chg        PARCHG               Partial charge densities" $SETFILE
    sed -i "${LINE_POST}a\[job].corr           PCDAT                Pair correlation function" $SETFILE
    sed -i "${LINE_POST}a\[job].md.out         REPORT               MD output" $SETFILE
    sed -i "${LINE_POST}a\[job].tmp            TMPCAR               Temporary file" $SETFILE
    sed -i "${LINE_POST}a\[job].xml            vasprun.xml          Output file in XML format" $SETFILE
    sed -i "${LINE_POST}a\[job].out.h5         vaspout.h5           Output file in H5 format" $SETFILE
    sed -i "${LINE_POST}a\[job].wave           WAVECAR              Wavefunction file" $SETFILE
    sed -i "${LINE_POST}a\[job].wave.h5        vaspwave.h5          Wavefunction file in H5 format" $SETFILE
    sed -i "${LINE_POST}a\[job].dwave          WAVEDER              Derivative of wave functions with respect to k point" $SETFILE
    sed -i "${LINE_POST}a\[job].traj.vasp      XDATCAR              Ionic configuration for each output step of MD" $SETFILE

    # Job submission file template - should be placed at the end of file
    cat << EOF >> $SETFILE
----------------------------------------------------------------------------------------
#!/bin/bash
#SBATCH --nodes=\${V_ND}
#SBATCH --ntasks-per-node=\${V_PROC}
#SBATCH --cpus-per-task=\${V_TRED}
#SBATCH --mem=\${V_MEM}
#SBATCH --time=\${V_TWT}
#SBATCH --output=\${V_JOBNAME}.log
#SBATCH --error=\${V_JOBNAME}.log

# Replace [budget code] below with your full project code
#SBATCH --partition=\${V_PARTITION}
#SBATCH --qos=\${V_QOS}
#SBATCH --export=none

echo "============================================"
echo "SLURM Job Report"
echo "--------------------------------------------"
echo "  Start Date : \$(date)"
echo "  SLURM Job ID : \${SLURM_JOB_ID}"
echo "  Status"
squeue -j \${SLURM_JOB_ID} 2>&1
echo "============================================"
echo ""

# Set number of threads and OMP level
export OMP_NUM_THREADS=\${V_TRED}
export OMP_PLACES=cores
# Ensure the cpus-per-task option is propagated to srun commands
export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK

# start calculation: command added below by gen_sub
\${V_GENSUB}
----------------------------------------------------------------------------------------

EOF
    cat << EOF
================================================================================
    Paramters specified in $SETFILE.

EOF
}

# Configure user alias

function set_commands {
    bgline=$(grep -nw "# >>> begin VASP6 job submitter settings >>>" $HOME/.bashrc)
    edline=$(grep -nw "# <<< finish VASP6 job submitter settings <<<" $HOME/.bashrc)

    if [[ ! -z $bgline && ! -z $edline ]]; then
        bgline=${bgline%%:*}
        edline=${edline%%:*}
        sed -i "$bgline,${edline}d" $HOME/.bashrc
    fi

    echo "# >>> begin VASP6 job submitter settings >>>" >> $HOME/.bashrc
    echo "alias Pvasp6='$CTRLDIR/gen_sub -x std -set $SCRIPTDIR/settings'" >> $HOME/.bashrc
    echo "alias Pvasp6_g='$CTRLDIR/gen_sub -x gam -set $SCRIPTDIR/settings'" >> $HOME/.bashrc
    echo "alias Pvasp6_nc='$CTRLDIR/gen_sub -x ncl -set $SCRIPTDIR/settings'" >> $HOME/.bashrc
    echo "alias Xvasp6='$CTRLDIR/gen_sub -set $SCRIPTDIR/settings'" >> $HOME/.bashrc
    echo "alias SETvasp6='cat $SCRIPTDIR/settings'" >> $HOME/.bashrc
    echo "alias HELPvasp6='source $CONFIGDIR/run_help gensub'" >> $HOME/.bashrc
    echo "chmod -R 'u+r+w+x' $CTRLDIR" >> $HOME/.bashrc
    echo "chmod 'u+r+w+x' $CONFIGDIR/run_help" >> $HOME/.bashrc
    echo "# <<< finish VASP6 job submitter settings <<<" >> $HOME/.bashrc

    bash $CONFIGDIR/run_help
}

# Main I/O function
## Disambiguation : Here is a historical problem
## Variables and functions with 'script' in configure script refer to the user's local settings file and its directory
## In the current implementation, $SCRIPTDIR only has 1 file, i.e., user-defined settings file
## Executable scripts are now centralized and shared in $CTRLDIR
## For executable scripts, $SCRIPTDIR refer to their own directory. $SETTINGS refers to local settings file. 
CONFIGDIR=$(realpath "$(dirname "$0")")
CTRLDIR=$(realpath "$CONFIGDIR/../")

welcome_msg
get_scriptdir
copy_scripts
get_budget_code
set_exe
set_mpi
set_settings
set_commands
