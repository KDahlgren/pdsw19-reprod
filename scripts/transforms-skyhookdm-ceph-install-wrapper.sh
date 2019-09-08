#!/bin/bash
# set  -e

if [ $# -le 1 ]
then
  echo "Usage:"
  echo "./this <number-of-osds> <path-to-your-id_rsa>"
  echo "forcing program exit..."
  exit 1
else
  echo "using nosds as '${1}'"
  echo "using sshkeypath as '${2}'"
fi
nosds=$1
sshkeypath=$2
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
touch nodes.txt
rm nodes.txt
touch postreqs.sh
rm postreqs.sh
touch cluster_setup_copy_ssh_keys.sh
rm cluster_setup_copy_ssh_keys.sh

# setup common ssh key for all client/osd nodes.
# this should be provided by the user,
# it is the key they use to ssh into their cloudlab profile machines.
echo "setup ssh keys..."
cd $HOME
touch  $HOME/.ssh/id_rsa
cp $HOME/.ssh/id_rsa ~/.ssh/id_rsa.bak
cp $sshkeypath  ~/.ssh/id_rsa
chmod 0600 $HOME/.ssh/id_rsa;

echo "create nodes.txt file for ssh key copy/setup"
cd $HOME
echo "client0" > nodes.txt;
for ((i = 0 ; i < $nosds ; i++)); do
  echo "osd${i}" >> nodes.txt;
done;

echo "Setting up ssh keyless between all machines..."
cp $scripts_dir/cluster_setup_copy_ssh_keys.sh . ;
sh cluster_setup_copy_ssh_keys.sh;

echo "copy scripts to all nodes"
cd $HOME
for n in  `cat nodes.txt`; do
  echo "copy scripts dir to node ${n}";
  scp -r ${scripts_dir}/*  ${n}:~/ ;
done;

echo "setup ansible prereqs via script, and install other small stuff locally...";
bash postreqs.sh;

echo "specify correct num osds for this cluster in ansible hosts file";
cd $HOME
for ((i = 0 ; i < $nosds ; i++)); do
  echo "osd${i}" >> $ansible_dir/hosts;
done;
cp $ansible_dir/hosts $ansible_dir/lib/ceph-deploy-ansible/ansible/hosts;

echo "VERIFY osds all there"
cat $ansible_dir/lib/ceph-deploy-ansible/ansible/hosts;

echo "update the max_osd here /vars/extra_vars.yml  as well."
head -n 4 $ansible_dir/lib/ceph-deploy-ansible/ansible/vars/extra_vars.yml >>   $ansible_dir/lib/ceph-deploy-ansible/ansible/vars/tmp.yml;
echo "num_osds: ${nosds}" >>$ansible_dir/lib/ceph-deploy-ansible/ansible/vars/tmp.yml;
mv $ansible_dir/lib/ceph-deploy-ansible/ansible/vars/tmp.yml $ansible_dir/lib/ceph-deploy-ansible/ansible/vars/extra_vars.yml;
rm -rf $ansible_dir/lib/ceph-deploy-ansible/ansible/vars/tmp.yml;

echo "visually  verify all sda4 mounted at /mnt/sda4.";
cd $HOME
for n in `cat nodes.txt`; do
  echo $n
  ssh $n "df -h | grep sda4;";
done;
sleep 3s;

# INSTALLING VANILLA CEPH LUMINOUS on all nodes client+osds and cls_tabular lib
echo `date`;
echo "run ansible playbook to install vanilla ceph luminous on cluster!";
cd $ansible_dir;
time ansible-playbook transforms_setup_playbook.yml ;
echo `date`;
echo "ansible playbook done.";
