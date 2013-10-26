#!/bin/bash

#set -x

reponame=swift
sshaccess=fabien@192.168.56.102
port=6666
repo_url=git://192.168.56.102:$port/$reponame

function add_files() {
    local dir=`mktemp -d -p .`
    for i in {1..10}; do
        local f=`mktemp -p $dir`
        head -c ${i}k </dev/urandom > $f
    done
    echo $dir
}

function add_commit() {
    local dir=`add_files`
    git add $dir
    git commit -a -m"Commit of $dir directory"
}

function generate_commits() {
    for i in {1..100}; do
        add_commit
    done
    find . -name "*.py" -exec sed -i s/Copyright/COPYRIGHT/ {} \;
    git commit -a -m"Change Copyrights"
}

# Initialise a base repo
ssh $sshaccess "mkdir cgitrepos"
scp $reponame.tgz $sshaccess:cgitrepos/$reponame.tgz
ssh $sshaccess \
    "cd cgitrepos; rm -Rf $reponame; tar -xzf $reponame.tgz; \
     cd $reponame; git config --bool core.bare true"

# Clone the Repo from swift
mkdir -p /tmp/perf_test
cd /tmp/perf_test
rm -Rf $reponame
rm -Rf clone$reponame

echo -e "\nStart cloning $reponame"
/usr/bin/time -f 'Cloning took %e seconds' \
    git clone -b master $repo_url > /dev/null

# Copy the original clone
cp -Rf $reponame clone$reponame

# Generate commits and push data
cd $reponame
echo -e "\nGenerate 100 commits with 10 files in it..."
generate_commits > /dev/null 2>&1
echo -e "\nPushing that commits in $reponame"
/usr/bin/time -f 'Push commits took %e seconds' \
    git push origin master > /dev/null

# Fetch newest commits
cd ../clone$reponame
echo -e "\nPull changes form $reponame"
/usr/bin/time -f 'Pulling changes took %e seconds' \
    git pull > /dev/null

