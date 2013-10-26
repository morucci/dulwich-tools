#!/bin/bash

set -x

# Reponame and project archive name with suffix
reponame=swift
# Token to authenticate on Swift
token=5a13cc2f0b4d4712ab0b8c636d285bf2
# The Swift storage URL
storage_url=https://snet-storage101.lon3.clouddrive.com/v1/MossoCloudFS_532c9f86-3240-4ff5-b3f0-033ece4debd2
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

# Initialise a base repo
echo "Remove previous repo in Swift"
swift --os-auth-token=$token \
      --os-storage-url=$storage_url delete $reponame
echo "Import bare $reponame in Swift using bulk middleware"
curl -XPUT -H"X-Auth-Token: $token" \
    "$storage_url/?extract-archive=tar.gz" \
    --data-binary @${reponame}.tgz 

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

