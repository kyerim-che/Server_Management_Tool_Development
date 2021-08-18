#!/bin/bash

# Change kyerim as your conda environment
source activate kyerim

unset XDG_RUNTIME_DIR
echo "done."
echo "*** Setting Jupyter interrupt character to Ctrl-T instead of Ctrl-C"
echo "*** to avoid conflicts with Slurm."
stty intr ^T
echo ""
echo "*** Starting Jupyter on: " $(hostname)
jupyter notebook --no-browser --ip='0.0.0.0' --port=9876
