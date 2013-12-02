#!/bin/bash

# Be sure to have an empty repo (github_projet=reponame_dul) created

set -x

# Reponame and project archive name with suffix
reponame=swift
reponamedul=${reponame}_dul.git
# Github Git repository. We'll bench it
github_repo_url=git@github.com:morucci/$reponamedul

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

# Push the base repo on github
rm -Rf /tmp/base
mkdir -p /tmp/base
cp ${reponame}.tgz /tmp/base
cd /tmp/base
tar -xzf ${reponame}.tgz
git clone $reponame clone${reponame}
cd clone${reponame}
git remote add alt $github_repo_url
echo -e "\nInitial push $reponame"
/usr/bin/time -f 'Initial push took %e seconds' git push alt master

# Clone the Repo from github
mkdir -p /tmp/perf_test
cd /tmp/perf_test
rm -Rf $reponame
rm -Rf clone$reponame

echo -e "\nStart cloning $reponame"
/usr/bin/time -f 'Cloning took %e seconds' \
    git clone -b master $github_repo_url $reponame > /dev/null

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

