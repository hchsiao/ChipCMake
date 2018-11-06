include(VCS)

# VCS_EXECUTABLE: which starts the vcs program
set(VCS_EXECUTABLE /opt/CIC/bin/vcs)
# VCS_ENV_FILE: path to the script that let you do "source $VCS_ENV_FILE; vcs &"
set(VCS_ENV_FILE /opt/CIC/snps/vcs.bash)
set(RTL_SIMULATOR_FOUND 1)
