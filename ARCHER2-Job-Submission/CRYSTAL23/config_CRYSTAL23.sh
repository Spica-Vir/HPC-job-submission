#!/bin/bash

function welcome_msg {
    core_version=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,22,11))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_date=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,33,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_author=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,54,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_contact=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,75,31))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    core_acknolg=`grep 'core' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,106,length($0)))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_version=`grep 'CRYSTAL23' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,22,11))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_date=`grep 'CRYSTAL23' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,33,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_author=`grep 'CRYSTAL23' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,54,21))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_contact=`grep 'CRYSTAL23' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,75,31))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
    code_acknolg=`grep 'CRYSTAL23' ${CTRLDIR}/version_control.txt | awk '{printf("%s", substr($0,106,length($0)))}' | awk '{sub(/^ */, ""); sub(/ *$/, "")}1'`
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
CRYSTAL23 job submission script for ARCHER2 - Setting up

Job submission script installed date : `date`
Batch system                         : SLURM
Job submission script version        : ${code_version} (${code_date})
Job submission script author         : ${code_author} (${code_contact})
Core script version                  : ${core_version} (${core_date})
Job submission script author         : ${core_author} (${core_contact})

${code_acknolg}
${core_acknolg}

EOF
}

function get_scriptdir {
    WORK=`echo "/work/${HOME#*/home/}"`
    cat << EOF
================================================================================
    Note: all scripts should be placed into the same directory!
    Please specify your installation path.

    Default Option
    ${WORK}/etc/runCRYSTAL23

EOF

    read -p " " SCRIPTDIR

    if [[ -z ${SCRIPTDIR} ]]; then
        SCRIPTDIR=${WORK}/etc/runCRYSTAL23
    fi

    if [[ ${SCRIPTDIR: -1} == '/' ]]; then
        SCRIPTDIR=${SCRIPTDIR%/*}
    fi

    SCRIPTDIR=`realpath $(echo ${SCRIPTDIR}) 2>&1 | sed -r 's/.*\:(.*)\:.*/\1/' | sed 's/[[:space:]]//g'` # Ignore errors
    source_dir=`realpath $(dirname $0)`
    if [[ ${source_dir} == ${SCRIPTDIR} ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    ERROR: You cannot specify source directory as your working directory. 
    Your option:  ${SCRIPTDIR}

EOF
        exit
    else
        ls ${SCRIPTDIR} > /dev/null 2>&1
        if [[ $? == 0 ]]; then
            cat << EOF
--------------------------------------------------------------------------------
    Warning: Directory exists - currnet folder will be removed.

EOF
            rm -r ${SCRIPTDIR}
        fi
    fi
}

function get_budget_code {
    cat << EOF
================================================================================
    Please specify your budget code:

EOF

    read -p " " BUDGET_CODE
    BUDGET_CODE=`echo ${BUDGET_CODE}`

    if [[ -z ${BUDGET_CODE} ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    Error: Budget code must be specified. Exiting current job. 

EOF
        exit
    fi
}

function set_exe {
    cat << EOF
================================================================================
    Please specify the directory of CRYSTAL exectuables, 
    or the command to load CRYSTAL modules

    Default Option
    module load other-software crystal/23-1.0.1-3

EOF

    read -p " " EXEDIR
    EXEDIR=`echo ${EXEDIR}`

    if [[ -z ${EXEDIR} ]]; then
        EXEDIR='module load other-software crystal/23-1.0.1-3'
    fi

    if [[ ! -d ${EXEDIR} && (${EXEDIR} != *'module load'*) ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    Error: Directory or command does not exist. Check your input: ${EXEDIR}

EOF
        exit
    fi

    if [[ ${EXEDIR} == *'module load'* ]]; then
        ${EXEDIR} > /dev/null 2>&1
        if [[ $? != 0 ]]; then
            cat << EOF
--------------------------------------------------------------------------------
    Error: Module specified not available. Check your input: ${EXEDIR}

EOF
            exit
        fi
        # Remove modules to avoid conflicts
        echo ${EXEDIR} | sed 's|load|rm|g' | bash > /dev/null 2>&1
    fi
}

function set_mpi {
    cat << EOF
================================================================================
    Please specify the directory of MPI executables or mpi modules

    Default Option
    module load PrgEnv-gnu/8.3.3 gcc/11.2.0 cray-mpich/8.1.23 cray-libsci/22.12.1.1

EOF

    read -p " " MPIDIR
    MPIDIR=`echo ${MPIDIR}`

    if [[ -z ${MPIDIR} ]]; then
        MPIDIR='module load PrgEnv-gnu/8.3.3 gcc/11.2.0 cray-mpich/8.1.23 cray-libsci/22.12.1.1'
    fi

    if [[ ! -d ${MPIDIR} && (${MPIDIR} != *'module load'*) ]]; then
        cat << EOF
--------------------------------------------------------------------------------
    Error: Directory or command does not exist. Check your input: ${MPIDIR}

EOF
        exit
    fi

    if [[ ${MPIDIR} == *'module load'* ]]; then
        ${MPIDIR} > /dev/null 2>&1
        if [[ $? != 0 ]]; then
            cat << EOF
--------------------------------------------------------------------------------
    Error: Module specified not available. Check your input: ${MPIDIR}

EOF
            exit
        fi
        # Remove modules to avoid conflicts
        echo ${MPIDIR} | sed 's|load|rm|g' | bash > /dev/null 2>&1
    fi
}

function copy_scripts {
    mkdir -p ${SCRIPTDIR}
    cp ${CTRLDIR}/settings_template ${SCRIPTDIR}/settings

    cat << EOF
================================================================================
    Moving and modifying scripts at ${SCRIPTDIR}/
EOF
}

# Configure settings file

function set_settings {
    SETFILE=${SCRIPTDIR}/settings

    # Values for keywords
    sed -i "/SUBMISSION_EXT/a\.slurm" ${SETFILE}
    sed -i "/NCPU_PER_NODE/a\128" ${SETFILE}
    sed -i "/NTHREAD_PER_PROC/a\ 1" ${SETFILE}
    sed -i "/BUDGET_CODE/a\ ${BUDGET_CODE}" ${SETFILE}
    sed -i "/QOS/a\standard" ${SETFILE}
    sed -i "/PARTITION/a\standard" ${SETFILE}
    sed -i "/TIME_OUT/a\3" ${SETFILE}
    sed -i "/JOB_TMPDIR/a\/tmp" ${SETFILE}
    sed -i "/EXEDIR/a\ ${EXEDIR}" ${SETFILE}
    sed -i "/MPIDIR/a\ ${MPIDIR}" ${SETFILE}

    # Executable table

    LINE_EXE=`grep -nw 'EXE_TABLE' ${SETFILE}`
    LINE_EXE=`echo "scale=0;${LINE_EXE%:*}+3" | bc`
    sed -i "${LINE_EXE}a\mppprop    srun --hint=nomultithread --distribution=block:block         MPPproperties                                                Massive parallel properties calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\pprop      srun --hint=nomultithread --distribution=block:block         Pproperties                                                  Parallel properties calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\mppcrysomp srun --distribution=block:block                              MPPcrystalOMP                                                Massive parallel crystal calculation - OMP" ${SETFILE}
    sed -i "${LINE_EXE}a\mppcrys    srun --hint=nomultithread --distribution=block:block         MPPcrystal                                                   Massive parallel crystal calculation" ${SETFILE}
    sed -i "${LINE_EXE}a\pcrysomp   srun --distribution=block:block                              PcrystalOMP                                                  Parallel crystal calculation - OMP" ${SETFILE}
    sed -i "${LINE_EXE}a\pcrys      srun --hint=nomultithread --distribution=block:block         Pcrystal                                                     Parallel crystal calculation" ${SETFILE}

    # Input file table

    LINE_PRE=`grep -nw 'PRE_CALC' ${SETFILE}`
    LINE_PRE=`echo "scale=0;${LINE_PRE%:*}+3" | bc`
    sed -i "${LINE_PRE}a\[job].POINTCHG       POINTCHG.INP         Dummy atoms with 0 mass and given charge" ${SETFILE}
    sed -i "${LINE_PRE}a\[job].gui            fort.34              Geometry input" ${SETFILE}
    sed -i "${LINE_PRE}a\[job].d3             INPUT                Properties input file" ${SETFILE}
    sed -i "${LINE_PRE}a\[job].d12            INPUT                Crystal input file" ${SETFILE}

    # Reference file table

    LINE_REF=`grep -nw 'REF_FILE' ${SETFILE}`
    LINE_REF=`echo "scale=0;${LINE_REF%:*}+3" | bc`
    sed -i "${LINE_REF}a\[ref].f31            fort.32              Derivative of density matrix" ${SETFILE}
    sed -i "${LINE_REF}a\[ref].f80            fort.81              Wannier funcion - input" ${SETFILE}
    sed -i "${LINE_REF}a\[ref].f28            fort.28              Binary IR intensity restart data" ${SETFILE}
    sed -i "${LINE_REF}a\[ref].f13            fort.13              Binary reducible density matrix" ${SETFILE}
    sed -i "${LINE_REF}a\[ref].TENS_RAMAN     TENS_RAMAN.DAT       Raman tensor" ${SETFILE}
    sed -i "${LINE_REF}a\[ref].TENS_IR        TENS_IR.DAT          IR tensor" ${SETFILE}
    sed -i "${LINE_REF}a\[ref].BORN           BORN.DAT             Born tensor" ${SETFILE}
    sed -i "${LINE_REF}a\[ref].FREQINFO       FREQINFO.DAT         Frequency restart data" ${SETFILE}
	sed -i "${LINE_REF}a\[ref].freqtsk/       *                    Frequency multitask restart data" ${SETFILE}
	sed -i "${LINE_REF}a\[ref].EOSINFO        EOSINFO.DAT          Equation of state restart data" ${SETFILE}
    sed -i "${LINE_REF}a\[ref].OPTINFO        OPTINFO.DAT          Optimisation restart data" ${SETFILE}
    sed -i "${LINE_REF}a\[ref].f9tsk/         *                    Last step wavefunction - multitask" ${SETFILE}
    sed -i "${LINE_REF}a\[ref].f9             fort.9               Last step wavefunction - properties input" ${SETFILE}
    sed -i "${LINE_REF}a\[ref].f9             fort.20              Last step wavefunction - crystal input" ${SETFILE}

    # Post-processing file table

    LINE_POST=`grep -nw 'POST_CALC' ${SETFILE}`
    LINE_POST=`echo "scale=0;${LINE_POST%:*}+3" | bc`

    sed -i "${LINE_POST}a\[job].SIGMA          SIGMA.DAT            Electrical conductivity" ${SETFILE}
    sed -i "${LINE_POST}a\[job].SEEBECK        SEEBECK.DAT          Seebeck coefficient" ${SETFILE}
    sed -i "${LINE_POST}a\[job].SIGMAS         SIGMAS.DAT           SigmaS" ${SETFILE}
    sed -i "${LINE_POST}a\[job].KAPPA          KAPPA.DAT            Thermal conductivity" ${SETFILE}
    sed -i "${LINE_POST}a\[job].TDF            TDF.DAT              Distribution function" ${SETFILE}
    sed -i "${LINE_POST}a\[job].POTC           POTC.DAT             Electrostatic potential and derivatives" ${SETFILE}
    sed -i "${LINE_POST}a\[job]_POT.CUBE       POT_CUBE.DAT         3D electrostatic potential CUBE format  " ${SETFILE}
    sed -i "${LINE_POST}a\[job]_SPIN.CUBE      SPIN_CUBE.DAT        3D spin density CUBE format" ${SETFILE}
    sed -i "${LINE_POST}a\[job].RHOLINE        RHOLINE.DAT          1D charge density and gradient" ${SETFILE}
    sed -i "${LINE_POST}a\[job]_CHG.CUBE       DENS_CUBE.DAT        3D charge density Gaussian CUBE format" ${SETFILE}
    sed -i "${LINE_POST}a\[job].DOSS           DOSS.DAT             DOS xmgrace format" ${SETFILE}
    sed -i "${LINE_POST}a\[job].BAND           BAND.DAT             Band xmgrace format " ${SETFILE}
    sed -i "${LINE_POST}a\[job].DIEL           DIEL.DAT             Dielectric constants" ${SETFILE}
    sed -i "${LINE_POST}a\[job].KRED           KRED.DAT             K space information for cryapi_inp" ${SETFILE}
    sed -i "${LINE_POST}a\[job].GRED           GRED.DAT             Real space information for cryapi_inp" ${SETFILE}
    sed -i "${LINE_POST}a\[job].f31            fort.31              Derivative of density matrix / Proeprties 3D grid data" ${SETFILE}
    sed -i "${LINE_POST}a\[job].EOSINFO        EOSINFO.DAT          QHA and equation of states information" ${SETFILE}
    sed -i "${LINE_POST}a\[job].TENS_RAMAN     TENS_RAMAN.DAT       Raman tensor" ${SETFILE}
    sed -i "${LINE_POST}a\[job].RAMSPEC        RAMSPEC.DAT          Raman spectra" ${SETFILE}
    sed -i "${LINE_POST}a\[job].TENS_IR        TENS_IR.DAT          IR tensor" ${SETFILE}
    sed -i "${LINE_POST}a\[job].BORN           BORN.DAT             Born tensor" ${SETFILE}
    sed -i "${LINE_POST}a\[job].IRSPEC         IRSPEC.DAT           IR absorbance and reflectance" ${SETFILE}
    sed -i "${LINE_POST}a\[job].IRREFR         IRREFR.DAT           IR refractive index" ${SETFILE}
    sed -i "${LINE_POST}a\[job].IRDIEL         IRDIEL.DAT           IR dielectric function" ${SETFILE}
    sed -i "${LINE_POST}a\[job].PHONBANDS      PHONBANDS.DAT        Phonon bands xmgrace format" ${SETFILE}
    sed -i "${LINE_POST}a\[job].f25            fort.25              Data in Crgra2006 format" ${SETFILE}
    sed -i "${LINE_POST}a\[job].scan/          SCAN*                Displaced geometry of scanning" ${SETFILE}
    sed -i "${LINE_POST}a\[job].f80            fort.80              Wannier funcion - output" ${SETFILE}
    sed -i "${LINE_POST}a\[job].f28            fort.28              Binary IR intensity restart data" ${SETFILE}
    sed -i "${LINE_POST}a\[job].f13            fort.13              Binary reducible density matrix" ${SETFILE}
    sed -i "${LINE_POST}a\[job].HESSFREQ       HESSFREQ.DAT         Hessian matrix from frequency calculation" ${SETFILE}
    sed -i "${LINE_POST}a\[job].FREQINFO       FREQINFO.DAT         Frequency restart data" ${SETFILE}
	sed -i "${LINE_POST}a\[job].freqtsk/       FREQINFO.DAT.tsk*    Frequency multitask restart data" ${SETFILE}
    sed -i "${LINE_POST}a\[job].optstory/      opt*                 Optimised geometry per step " ${SETFILE}
    sed -i "${LINE_POST}a\[job].HESSOPT        HESSOPT.DAT          Hessian matrix per optimisation step" ${SETFILE}
    sed -i "${LINE_POST}a\[job].OPTINFO        OPTINFO.DAT          Optimisation restart data" ${SETFILE}
    sed -i "${LINE_POST}a\[job].SCFLOG         SCFOUT.LOG           SCF output per step" ${SETFILE}
    sed -i "${LINE_POST}a\[job].f53            fort.53              Optimised Basis Set Output" ${SETFILE}
    sed -i "${LINE_POST}a\[job].PPAN           PPAN.DAT             Mulliken population" ${SETFILE}
    sed -i "${LINE_POST}a\[job].f9tsk/         fort.9.tsk*          Wavefunction restart data - multitask" ${SETFILE}
    sed -i "${LINE_POST}a\[job].f98            fort.98              Formatted wavefunction" ${SETFILE}
    sed -i "${LINE_POST}a\[job].f9             fort.9               Last step wavefunction - crystal output" ${SETFILE}
    sed -i "${LINE_POST}a\[job].STRUC          STRUC.INCOOR         Geometry, STRUC.INCOOR format" ${SETFILE}
    sed -i "${LINE_POST}a\[job].GAUSSIAN       GAUSSIAN.DAT         Geometry, for Gaussian98/03" ${SETFILE}
    sed -i "${LINE_POST}a\[job].FINDSYM        FINDSYM.DAT          Geometry, for FINDSYM" ${SETFILE}
    sed -i "${LINE_POST}a\[job].cif            GEOMETRY.CIF         Geometry, cif format (CIFPRT/CIFPRTSYM)" ${SETFILE}
    sed -i "${LINE_POST}a\[job].xyz            fort.33              Geometry, non-periodic xyz format" ${SETFILE}
    sed -i "${LINE_POST}a\[job].gui            fort.34              Geometry, CRYSTAL fort34 format" ${SETFILE}
    sed -i "${LINE_POST}a\[job].ERROR          fort.87              Error report" ${SETFILE}

    # Job submission file template - should be placed at the end of file
    cat << EOF >> ${SETFILE}
----------------------------------------------------------------------------------------
#!/bin/bash
#SBATCH --nodes=\${V_ND}
#SBATCH --ntasks-per-node=\${V_PROC}
#SBATCH --cpus-per-task=\${V_TRED}
#SBATCH --time=\${V_TWT}
#SBATCH --output=\${V_JOBNAME}.log
#SBATCH --error=\${V_JOBNAME}.log

# Replace [budget code] below with your full project code
#SBATCH --account=\${V_BUDGET}
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

# Address the memory leak
export FI_MR_CACHE_MAX_COUNT=0

# Set number of threads and OMP level
export OMP_NUM_THREADS=\${V_TRED}
export OMP_PLACES=cores

# start calculation: command added below by gen_sub
\${V_GENSUB}

# MultiTask wavefunction fort.9.tsk* fix
cd \${SLURM_SUBMIT_DIR}
if [[ -e \${V_JOBNAME}.f9tsk && -d \${V_JOBNAME}.f9tsk ]]; then
    files=(\$(ls \${V_JOBNAME}.f9tsk))
    for ((i=0; i<\${#files[@]}; i++)); do
        mv \${V_JOBNAME}.f9tsk/fort.9.tsk\${i} \${V_JOBNAME}.f9tsk/fort.20.tsk\${i}
    done
fi
----------------------------------------------------------------------------------------

EOF
    cat << EOF
================================================================================
    Paramters specified in ${SETFILE}.

EOF
}

# Configure user alias

function set_commands {
    bgline=`grep -nw "# >>> begin CRYSTAL23 job submitter settings >>>" ${HOME}/.bashrc`
    edline=`grep -nw "# <<< finish CRYSTAL23 job submitter settings <<<" ${HOME}/.bashrc`

    if [[ ! -z ${bgline} && ! -z ${edline} ]]; then
        bgline=${bgline%%:*}
        edline=${edline%%:*}
        sed -i "${bgline},${edline}d" ${HOME}/.bashrc
    fi

    echo "# >>> begin CRYSTAL23 job submitter settings >>>" >> ${HOME}/.bashrc
    echo "alias Pcrys23='${CTRLDIR}/gen_sub -x pcrys -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias OPcrys23='${CTRLDIR}/gen_sub -x pcrysomp -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias MPPcrys23='${CTRLDIR}/gen_sub -x mppcrys -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias OMPPcrys23='${CTRLDIR}/gen_sub -x mppcrysomp -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Pprop23='${CTRLDIR}/gen_sub -x pprop -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias MPPprop23='${CTRLDIR}/gen_sub -x mppprop -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias Xcrys23='${CTRLDIR}/gen_sub -set ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias SETcrys23='cat ${SCRIPTDIR}/settings'" >> ${HOME}/.bashrc
    echo "alias HELPcrys23='source ${CONFIGDIR}/run_help gensub'" >> ${HOME}/.bashrc
    echo "chmod -R 'u+r+w+x' ${CTRLDIR}" >> ${HOME}/.bashrc
    echo "chmod 'u+r+w+x' ${CONFIGDIR}/run_help" >> ${HOME}/.bashrc
    echo "# <<< finish CRYSTAL23 job submitter settings <<<" >> ${HOME}/.bashrc

    bash ${CONFIGDIR}/run_help
}

# Main I/O function
## Disambiguation : Here is a historical problem
## Variables and functions with 'script' in configure script refer to the user's local settings file and its directory
## In the current implementation, ${SCRIPTDIR} only has 1 file, i.e., user-defined settings file
## Executable scripts are now centralized and shared in ${CTRLDIR}
## For executable scripts, ${SCRIPTDIR} refer to their own directory. ${SETTINGS} refers to local settings file. 
CONFIGDIR=`realpath $(dirname $0)`
CTRLDIR=`realpath ${CONFIGDIR}/../`

welcome_msg
get_scriptdir
copy_scripts
get_budget_code
set_exe
set_mpi
set_settings
set_commands
