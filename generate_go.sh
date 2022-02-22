java -jar openapi-generator-cli.jar generate -g go -o ../doggy-sdk-go/doggy \
  -c configs/go.json \
  -i swagger.json \
  --git-user-id mr-doggy \
  --git-repo-id doggy-sdk-go \
  --release-note update

cd ../doggy-sdk-go/
mv doggy/go.mod .
mv doggy/go.sum .
git add .
git commit -a -m "update"
git push origin master
cd ../doggy-sdk-generator/