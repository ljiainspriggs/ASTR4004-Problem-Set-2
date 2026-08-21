
#!/bin/bash

# (set -e) close/exit script if smth fails (prevent corrupted commits)
# (set -u) force missing/undefined variables to return an error (prevent empty string substitution)
# (pipefail) force pipe functions to return an error if conditional cmd fails
# see https://medium.com/@nitin.satyan/fail-fast-fail-loud-set-euo-pipefail-isnt-optional-5b8002593037
# for full description/justification
set -euo pipefail

# confirm correct number of inputs to avoid later errors
if [[ $# -ne 3 ]]; then
  echo "$0 requires <target-repo-name> <branch-name> <merge-condition [T/F]>."
  echo "Scripted aborted."
  exit 1
fi

## CONFIRM CMD LINE INPUTS ##

# save cmd line inputs to variables
reponame="$1"
branchname="$2" 
merge_cond="$3" # T for merge; F for no merge

# github location of repo
gitdir="git@github.com:ljiainspriggs/${reponame}.git"

# local location of repo (current dir, ensure in problem set folder)
localdir="$PWD"

# print variables
echo "Local Repo: $localdir"
echo "Target Repo: $gitdir"
echo "Branch: $branchname"
echo "Merge to main? $merge_cond"

# confirm variable correct with user (input from user)
read -p "Are the above correct? [Y/N] " confirm

if [[ "$confirm" == "Y" || "$confirm" == "y" ]]; then
  echo "Proceeding..." # if Y or y, continue
else
  echo "Script aborted." # else, abort
  exit 1 # close/exit script in error state
fi

## CHECK GITHUB REPO EXISTS ##

# try to access github repo, discard cmd std output/err
# true if cmd successful (status 0), false else
if git ls-remote "$gitdir" &>/dev/null; then 
  echo "$reponame exists."
else
  echo "$reponame not found. Script aborted."
  exit 1
fi

## CHECK LOCAL REPO EXISTS ##

# set variable to know whether this is the initial commit
initial_commit=true

# true if directory .git exists
if [[ -d ".git" ]]; then
  echo "Working dir in git repo."
  initial_commit=false
else # if local repo not found, clone github repo to folder of repo name
  echo "Working dir not in git repo. Creating git repo..."
  git init # create git dir
  git branch -M main # define main as main branch
  git remote add origin "$gitdir" # define github loc for origin
  touch .gitignore # create git ignore file
  touch README.md # create read me file
  echo "Working log for ASTR4004 assignments." > README.md # add beginning/placeholder text
  echo "Local git repo created."
  git add -A # stage/cache all new files
  git commit -m "Initial commit." # commit initially to main
  git push -u origin main # push to github
  echo "Initial commit completed."
fi

# if NOT initial commit, check for desired branch on repo
if [[ "$initial_commit" == false ]]; then

  ## CHECK BRANCH EXISTS ON GITHUB REPO ##

  # try to access github repo branch, discard cmd std output/err
  # true if cmd successful (status 0), false else
  if git ls-remote --exit-code --branches origin "$branchname" &>/dev/null; then
    git switch "$branchname" # switch to branch
    echo "$branchname exists."
  else
    echo "$branchname not found. Creating..."
    git switch main
    git switch -c "$branchname" # create and switch to branch
    git push -u origin "$branchname" # push branch to github repo
    echo "$branchname created."
  fi

fi  

## COMMIT CHANGES ##

git add -A # stage/cache all file changes in local repo for commit

# identify differences between cached repo (diff --cached), mute outputs of changes (--quiet)
# true if no changes (status 0), false else
if git diff --cached --quiet; then
  echo "No changes detected."
else
  echo "Changes detected."

  read -p "Commit message: " commit_message # await input of commit message from user

  git commit -m "$commit_message" # commit to local repo with commit message
  git push # push local repo to github
  echo "Successfully committed to github repo."
fi

## MERGE WITH MAIN ##

# true if merge_cond set to "T"
if [[ "$merge_cond" == "T" || "$merge_cond" == "t" ]]; then
  echo "Proceeding with merge to main..."
  git switch main # switch to main branch
  git merge "$branchname" # merge branch name with current branch (main)
  git push origin main # push updated main branch to github repo
  echo "Merging completed."
else
  echo "Merge not requested."
fi

# confirm completion of script
echo "Automated commit process completed with the following."
echo "Local Repo: $localdir"
echo "Target Repo: $gitdir"
echo "Branch: $branchname"
echo "Merge to main? $merge_cond"
