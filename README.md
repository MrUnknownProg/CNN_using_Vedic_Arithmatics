# CNN using FPGA

## Contains two scale of code 3x3 & 5x5
## Use same MACs & multipliers for both
## Always view TCL Console after testbench simulation along with the waveform for errors

# fpga->latest has all the codes needed. It dosent contain multipliers only MAC is there.
# Refer fpga->multipliers for multipliers used in MACs

# MATLAB
Train folder has codes for training, convolution compare, Fully connected layer mimic, output verification.
Every code needs the image.mem/weights.mem/output.txt except training code.

NOTE:- Double check file names used in code if error encountered
