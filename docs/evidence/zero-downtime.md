# Zero-Downtime Deployment Evidence

**Scenario:** continuously send requests to the public gateway while switching traffic from Blue to Green.

**Command**

```bash
export PULL_IMAGES=false
./scripts/soak-test.sh http://localhost:8080 40 0.2 > /tmp/soak.log 2>&1 &
SOAK=$!
sleep 3
./scripts/bg-deploy.sh local
wait "$SOAK"
cat /tmp/soak.log
```

**Actual output**

```text
[INFO] Current active colour : blue
[INFO] Deploying new release : green (tag: local)
[INFO] Backend image         : shopnest-backend:local
[INFO] Frontend image        : shopnest-frontend:local
[INFO] Starting 'green' environment ...
 Container shopnest-green-frontend Running
 Container shopnest-green-backend Running
 Container shopnest-green-backend Waiting
 Container shopnest-green-backend Healthy
[ OK ] Service 'green-backend' is healthy
[ OK ] Service 'green-frontend' is healthy
[INFO] Running internal smoke tests against 'green' ...
[ OK ] Internal smoke tests passed
[INFO] Switching gateway traffic: blue -> green
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[ OK ] Public health check passed on 'green'.
[INFO] Blue-Green deployment complete. Active colour: green

[INFO] Soak testing http://localhost:8080 for 40s (every 0.2s) ...
[INFO] Soak result: total=68 failures=0
[ OK ] Zero failed requests during the soak window

deploy_exit=0 soak_exit=0
```

**Interpretation**

- **68 requests** were sent during the switch window.
- **0 failed** (all returned HTTP 200).
- The gateway upstream changed from `blue-frontend` to `green-frontend` without dropping requests.
- The deployment finished with `Active colour: green`.

This is the evidence required for the zero-downtime requirement. On EC2, run the same commands against the production URL and capture the equivalent output.