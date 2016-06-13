#!/bin/bash
if [ -d ".git" ]; then
  rm -rf .git
  echo "git repo removed"
fi
find . -type f -name "extrafile_*" -delete
find . -type d -name "add_dir_*" -delete

### Variable Declaration ###

amount_of_repos=30 #the amount of github repo's to scan
github_curl_authentication=$(cat authentication.json | jq "{github_curl_authentication}" | jq -r ".[]")

repo_iteration=0
total_size_count=0
total_stargazers_count=0
total_subscribers_count=0
total_watchers_count=0
total_open_issues_count=0
total_forks_count=0
total_branch_count=0
total_readmelines_count=0
total_readmelines_perlineword_count=0
total_readmelines_emptylinescount=0
total_amountgitfilesclean_count=0

### Functions ###

repo_full_names=$( \
curl -s -G $github_curl_authentication https://api.github.com/search/repositories \
--data-urlencode 'q=created:>2000-01-01' \
--data-urlencode 'sort=stars' \
--data-urlencode 'order=desc' \
-H 'Accept: application/vnd.github.preview' \
| jq ".items[range($amount_of_repos)] | {full_name}" | jq -r ".[]" \
)

for line in $repo_full_names
do
  echo "{"
  repo_iteration=$(($repo_iteration + 1)) # should be the same as $amount_of_repos
  echo "  \"starred_rank\": $repo_iteration,"

  full_name="$line"
  echo "  \"full_name\": \"$full_name\","

  size=$( \
      curl -s -G $github_curl_authentication https://api.github.com/repos/$line \
      --data-urlencode 'q=created:>2000-01-01' --data-urlencode 'order=desc' \
      -H "Accept: application/vnd.github.preview" | jq "{size}" | jq -r ".[]" \
  )
  total_size_count=$(($total_size_count + $size))
  echo "  \"size\": $size,"

  stargazers_count=$( \
      curl -s -G $github_curl_authentication https://api.github.com/repos/$line \
      --data-urlencode 'q=created:>2000-01-01' --data-urlencode 'order=desc' \
      -H "Accept: application/vnd.github.preview" | jq "{stargazers_count}" | jq -r ".[]" \
  )
  total_stargazers_count=$(($total_stargazers_count + $stargazers_count))
  echo "  \"stargazers_count\": $stargazers_count,"

  subscribers_count=$( \
      curl -s -G $github_curl_authentication https://api.github.com/repos/$line \
      --data-urlencode 'q=created:>2000-01-01' --data-urlencode 'order=desc' \
      -H "Accept: application/vnd.github.preview" | jq "{subscribers_count}" | jq -r ".[]" \
  )
  total_subscribers_count=$(($total_subscribers_count + $subscribers_count))
  echo "  \"subscribers_count\": $subscribers_count,"

  watchers_count=$( \
      curl -s -G $github_curl_authentication https://api.github.com/repos/$line \
      --data-urlencode 'q=created:>2000-01-01' --data-urlencode 'order=desc' \
      -H "Accept: application/vnd.github.preview" | jq "{watchers_count}" | jq -r ".[]" \
  )
  total_watchers_count=$(($total_watchers_count + $watchers_count))
  echo "  \"watchers_count\": $watchers_count,"

  open_issues_count=$( \
      curl -s -G $github_curl_authentication https://api.github.com/repos/$line \
      --data-urlencode 'q=created:>2000-01-01' --data-urlencode 'order=desc' \
      -H "Accept: application/vnd.github.preview" | jq "{open_issues_count}" | jq -r ".[]" \
  )
  total_open_issues_count=$(($total_open_issues_count + $open_issues_count))
  echo "  \"open_issues_count\": $open_issues_count,"

  forks_count=$( \
      curl -s -G $github_curl_authentication https://api.github.com/repos/$line \
      --data-urlencode 'q=created:>2000-01-01' --data-urlencode 'order=desc' \
      -H "Accept: application/vnd.github.preview" | jq "{forks_count}" | jq -r ".[]" \
  )
  total_forks_count=$(($total_forks_count + $forks_count))
  echo "  \"forks_count\": $forks_count,"

  branch_count=$( \
      curl -s -G $github_curl_authentication https://api.github.com/repos/$line/branches \
      --data-urlencode 'q=created:>2000-01-01' --data-urlencode 'order=desc' \
      -H "Accept: application/vnd.github.preview" | jq "length" \
  )
  total_branch_count=$(($total_branch_count + $branch_count))
  echo "  \"branch_count\": $branch_count,"

  name=$( \
      curl -s -G $github_curl_authentication https://api.github.com/repos/$line \
      --data-urlencode 'q=created:>2000-01-01' --data-urlencode 'order=desc' \
      -H "Accept: application/vnd.github.preview" | jq "{name}" | jq -r ".[]" \
  )
  git_url=$( \
      curl -s -G $github_curl_authentication https://api.github.com/repos/$line \
      --data-urlencode 'q=created:>2000-01-01' --data-urlencode 'order=desc' \
      -H "Accept: application/vnd.github.preview" | jq "{git_url}" | jq -r ".[]" \
  )
  echo "  \"git_url\": $git_url,"
  if [ -d "$name" ]; then
    rm -rf $name
  fi
  git clone -q --depth 1 $git_url
  amountgitfiles=$(ls -a $name | wc -l)
  amountgitfilesclean=$(($amountgitfiles - 4))
  rm -rf $name
  echo "  \"amountgitfilesclean\": $amountgitfilesclean,"
  total_amountgitfilesclean_count=$(($total_amountgitfilesclean_count + $amountgitfilesclean))

  readme_url=$( \
      curl -s -G $github_curl_authentication https://api.github.com/repos/$line/readme \
      --data-urlencode 'q=created:>2000-01-01' --data-urlencode 'order=desc' \
      -H "Accept: application/vnd.github.preview" | jq "{download_url}" | jq -r ".[]" \
  )
  readme_file=$(wget -O- -q $readme_url)
  readmelines_count=$(echo "$readme_file" | wc -l)
  total_readmelines_count=$(($total_readmelines_count + $readmelines_count))

  readmelines_emptylines_count=$(echo "$readme_file" | grep -c "^$")
  total_readmelines_emptylines_count=$(($total_readmelines_emptylines_count + $readmelines_emptylines_count))

  echo "  \"readmelines_count\": $readmelines_count,"
  echo "  \"readmelines_emptylines_count\": $readmelines_emptylines_count"
  echo "}"
done
echo "{"
average_size_count=$(($total_size_count / $repo_iteration))
echo "  \"average_size_count\": $average_size_count,"
average_stargazers_count=$(($total_stargazers_count / $repo_iteration))
echo "  \"average_stargazers_count\": $average_stargazers_count,"
average_subscribers_count=$(($total_subscribers_count / $repo_iteration))
echo "  \"average_subscribers_count\": $average_subscribers_count,"
average_watchers_count=$(($total_watchers_count / $repo_iteration))
echo "  \"average_watchers_count\": $average_watchers_count,"
average_open_issues_count=$(($total_open_issues_count / $repo_iteration))
echo "  \"average_open_issues_count\": $average_open_issues_count,"
average_forks_count=$(($total_forks_count / $repo_iteration))
echo "  \"average_forks_count\": $average_forks_count,"
average_branch_count=$(($total_branch_count / $repo_iteration))
echo "  \"average_branch_count\": $average_branch_count,"
average_amountgitfilesclean_count=$(($total_amountgitfilesclean_count / $repo_iteration))
echo "  \"average_amountgitfilesclean_count\": $average_amountgitfilesclean_count,"
average_readmelines_count=$(($total_readmelines_count / $repo_iteration))
echo "  \"average_readmelines_count\": $average_readmelines_count,"
average_readmelines_emptylines_count=$(($total_readmelines_emptylines_count / $repo_iteration))
echo "  \"average_readmelines_emptylines_count\": $average_readmelines_emptylines_count"
echo "}"

### create readme.md file with amount of lines and words
# echo "{"
prependreadmelines_count=$(cat prepend_readme.md | wc -l)

lineswithcontent=$(($average_readmelines_count - $average_readmelines_emptylines_count - $prependreadmelines_count - 1))
# echo "lineswithcontent: $lineswithcontent,"
nthemptyline=0
nthemptyline=$(($lineswithcontent / $average_readmelines_emptylines_count))
# echo "nthemptyline: $nthemptyline"

echo -e "$(cat prepend_readme.md)\n" > README.md
./lorem.py -l $lineswithcontent | awk -v n=$nthemptyline '1; NR % n == 0 {print ""}' >> README.md
# echo "}"


### create files to immitate full repo length
half_of_average_amountgitfilesclean_count=$(($average_amountgitfilesclean_count / 2))
for fileordir in $(seq 1 $half_of_average_amountgitfilesclean_count)
do
  echo "additional file" > extrafile_$fileordir.md
  mkdir add_dir_$fileordir
  cd add_dir_$fileordir
  echo "additional file" > extrafile_$fileordir.md
  cd ../
done

## create git repo ###
git init
git add .
git commit -m "initial commit"

### add all remotes ###
# gitlab
git remote add gitlab $(cat authentication.json | jq "{gitlab}" | jq -r ".[]")
# github
git remote add github $(cat authentication.json | jq "{github}" | jq -r ".[]")
# heroku
heroku git:remote -a $(cat authentication.json | jq "{heroku}" | jq -r ".[]")
# beanstalk
git remote add beanstalk $(cat authentication.json | jq "{beanstalk}" | jq -r ".[]")
# bitbucket
git remote add bitbucket $(cat authentication.json | jq "{bitbucket}" | jq -r ".[]")

# create branches
for branch in $(seq 1 $average_branch_count)
do
  git checkout -b "branch-$branch"
done
git checkout master

### push to all remotes ###
git push --all gitlab
git push --all github
git push --all heroku
git push --all beanstalk
git push --all bitbucket
