#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=8GB
#SBATCH --time=00:10:00
#SBATCH --output=fccSi_band.log
#SBATCH --error=fccSi_band.log

# Replace [budget code] below with your full project code
#SBATCH --partition=normal
#SBATCH --qos=short
#SBATCH --gres=gpu:0
#SBATCH --export=none

echo "============================================"
echo "SLURM Job Report"
echo "--------------------------------------------"
echo "  Start Date : $(date)"
echo "  SLURM Job ID : $SLURM_JOB_ID"
echo "  Status"
squeue -j $SLURM_JOB_ID 2>&1
echo "============================================"
echo ""

# number of cores per node used
export NCORES=4
# number of processes
export NPROCESSES=4

# Set number of threads and OMP level
export OMP_NUM_THREADS=1
export OMP_PLACES=cores

module purge
# start calculation: command added below by gen_sub
timeout 4m /home/zhouhuanyu/GitHub/HPC-job-submission/CATAPULT-Job-Submission/run_exec -set /home/zhouhuanyu/etc/runVASP6/settings -in fccSi.in -ref no -- 'unset I_MPI_PMI_LIBRARY; mpirun -np 4 vasp_std'
/home/zhouhuanyu/GitHub/HPC-job-submission/CATAPULT-Job-Submission/post_proc -in fccSi.in -set /home/zhouhuanyu/etc/runVASP6/settings
timeout 4m /home/zhouhuanyu/GitHub/HPC-job-submission/CATAPULT-Job-Submission/run_exec -set /home/zhouhuanyu/etc/runVASP6/settings -in fccSi_band.in -ref fccSi -- 'unset I_MPI_PMI_LIBRARY; mpirun -np 4 vasp_std'
/home/zhouhuanyu/GitHub/HPC-job-submission/CATAPULT-Job-Submission/post_proc -in fccSi_band.in -set /home/zhouhuanyu/etc/runVASP6/settings

