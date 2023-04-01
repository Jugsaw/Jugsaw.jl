# Hello World

To run this exmaple, you need to have a docker installed.

First, let's build the docker image manually.

```bash
docker build -t jugsaw/helloworld -f example/hello_world/Dockerfile .
```

Then run the docker.

```bash
docker run --network="host" jugsaw/helloworld
```

(In the future, above steps can be skipped because we'll deploy examples on the cloud.)

Now we can call those demo functions in a separate terminal.

```bash
curl --request POST \
  --url http://127.0.0.1:8081/actors/greet/jinguo/method/ \
  --data '"Jinguo"'

curl --request POST \
  --url http://127.0.0.1:8081/actors/greet/jinguo/method/fetch \
  --data '"REPLACE_ME_WITH_RESULT_FROM_ABOVE_REQUEST"'

curl --request POST \
  --url http://127.0.0.1:8081/actors/Counter/juntian/method/ \
  --data 5

curl --request POST \
  --url http://127.0.0.1:8081/actors/Counter/juntian/method/fetch \
  --data '"REPLACE_ME_WITH_RESULT_FROM_ABOVE_REQUEST"'
```

TODO: We should return result directly by default(sync mode by default).
TODO: add Python/Julia client based usages.