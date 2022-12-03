java -jar openapi-generator-cli.jar generate -g go -o ../puupee-api-go \
  -c configs/go.json \
  -i swagger.json \
  --git-user-id puupee \
  --git-repo-id puupee-api-go \
  --release-note update

cd ../puupee-api-go/
go mod tidy
git add .
git commit -a -m "update"
git push origin master
cd ../puupee-api-generator/