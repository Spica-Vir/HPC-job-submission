#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH --cpus-per-task=1
#SBATCH --mem=48GB
#SBATCH --time=00:30:00
#SBATCH --output=LCO_R.log
#SBATCH --error=LCO_R.log

#SBATCH --partition=xhhctdnormal

echo "============================================"
echo "SLURM Job Report"
echo "--------------------------------------------"
echo "  Start Date : $(date)"
echo "  SLURM Job ID : $SLURM_JOB_ID"
echo "  Status"
squeue -j $SLURM_JOB_ID 2>&1
echo "============================================"
echo ""

# Set number of threads and OMP level
export OMP_NUM_THREADS=1
export OMP_PLACES=cores

module purge
module load compiler/intel/2017.5.239
module load mpi/intelmpi/2017.4.239
export MKL_DEBUG_CPU_TYPE=5 #加速代码
export MKL_CBWR=AVX2 #使cpu默认支持avx2
export I_MPI_PIN_DOMAIN=numa #内存位置与cpu位置绑定，加速内存读取。对于内存带宽要求高的计算提速明显

# start calculation: command added below by gen_sub
timeout 29m /work/home/huanyuzhou/GitHub/HPC-job-submission/SUGON-Job-Submission/run_exec -set /work/home/huanyuzhou/etc/runVASP6/settings -in LCO_R.in -ref no -- 'srun --mpi=pmi2 /work/share/acm4hzo7rg/modules/vasp/6.4.2-gzbuild/vasp_std'
/work/home/huanyuzhou/GitHub/HPC-job-submission/SUGON-Job-Submission/post_proc -in LCO_R.in -set /work/home/huanyuzhou/etc/runVASP6/settings

