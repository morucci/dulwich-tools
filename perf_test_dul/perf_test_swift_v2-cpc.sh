#!/bin/bash

# Be sure to have an empty repo (container=reponame) created
# with swift-init-repo.py before starting this script

# swift -A http://localhost:8080/auth/v1.0 -U 'test:tester' -K testing delete swiftsync
# DULWICH_SWIFT_CFG=../dulv1.conf PYTHONPATH=../dulwich python swift-init-repo.py edeploy

set -x

# Reponame and project archive name with suffix
reponame=swift
# Dulwich Git repository. We'll bench it 
dul_repo_url=git://127.0.0.1/$reponame

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

# Push the base repo on Swift via Dulwich
rm -Rf /tmp/base
mkdir -p /tmp/base
cp ${reponame}.tgz /tmp/base
cd /tmp/base
tar -xzf ${reponame}.tgz
git clone $reponame clone${reponame}
cd clone${reponame}
git remote add alt $dul_repo_url
git push alt master

# Clone the Repo from swift
mkdir -p /tmp/perf_test
cd /tmp/perf_test
rm -Rf $reponame
rm -Rf clone$reponame

echo -e "\nStart cloning $reponame"
/usr/bin/time -f 'Cloning took %e seconds' \
    git clone -b master $dul_repo_url > /dev/null

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

