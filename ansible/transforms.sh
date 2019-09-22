#!/bin/bash
# set  -e

# -------------------------------------------------------------------- #
# SETUP AND INSTALL CEPH
# -------------------------------------------------------------------- #
nosds=$1
max_osd=$((nosds-1))

echo "START:"
echo `date`

cd $HOME
# get all the scripts and sample data from public repo.
echo "also assumes your cluster ssh generic privkey is avail at absolute path provided as arg (for node to node ssh)."
sleep 5s

# hardcoded vars for now.
ansible_dir="${HOME}/skyhook-ansible/ansible/"
echo "clear out prev data dirs and scripts."
scripts_dir="${HOME}/pdsw19-reprod/scripts/"
data_dir="${HOME}/pdsw19-reprod/data/"
reprod_dir="${HOME}/pdsw19-reprod/"
touch nodes.txt
rm nodes.txt
touch postreqs.sh
rm postreqs.sh

echo "create nodes.txt file for ssh key copy/setup"
cd $HOME
echo "client0" > nodes.txt;
for ((i = 0 ; i < $nosds ; i++)); do
  echo "osd${i}" >> nodes.txt;
done;

echo "nodes.txt:"
cat nodes.txt
cat /etc/hosts ;
