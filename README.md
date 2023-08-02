# noname-tf-example

## Below is my log for debugging/validating.  For the second half you can mostly see my progress through git commits

9:07 Starting

Account: 699899179833
IAM User: Derek
New Password: REDACTED

AccessKey: REDACTED
KeySecret: REDACTED

AssumeRole: CandidateTestRole

VPC: vpc-09cf75f05de5b433e
private-a: subnet-04102795c60e02f9d
public-a: subnet-07c25242abaef4f31

9:15 Setup access keys / changed password
 - looked over vpc to validate I was in the right region and notated the subnets
 - imported ssh key (candidate-derek)

9:18 wants ec2 box setup in private subnet but expects it to have public ip....
 - could just create it in public subnet or I could attach another eni from the public subnet to it or even a lb.
 - chose to create it in private subnet but with secondary network card in public subnet
 - assigned public ip 34.225.209.72 to the box

9:25 connected to box
 - configure aws cli to auto assume arn:aws:iam::699899179833:role/CandidateTestRole
 - installed kubectl
 - added candidate-test-cluster to kubeconfig

9:35 testing the curl
 - no response
 - nslookup candidate.test.nonamesec.com returns 34.206.233.122
 - 34.206.233.122 => ELB ad52b1c0530504c238dc9611a73fb257
 - 0 of 0 instances
 - kube-system/ingress-nginx-controller
 - no node resources
 - bumped test-az-a node group to desire 1 node
 - nginx now returning 503

9:45 debugging the kubernetes ingress
 - found the configured ingress kubectl get -A ingresses
 - described ingress for configuration looks like its pointed to candidate-test:999
        ```
        kubectl describe -n candidate-test ingress candidate-test-ingress
        Name:             candidate-test-ingress
        Labels:           app=candidate-test
                          app.kubernetes.io/instance=release-name
                          app.kubernetes.io/name=candidate-test
        Namespace:        candidate-test
        Address:          ad52b1c0530504c238dc9611a73fb257-1330456507.us-east-1.elb.amazonaws.com
        Ingress Class:    nginx
        Default backend:  <default>
        Rules:
          Host                          Path  Backends
          ----                          ----  --------
          candidate.test.nonamesec.com
                                        /   candidate-test:999 (<none>)
        Annotations:                    kubernetes.io/ingress.class: nginx
                                        nginx.ingress.kubernetes.io/configuration-snippet: more_set_headers "X-Forwarded-For $http_x_forwarded_for";
                                        nginx.ingress.kubernetes.io/proxy-connect-timeout: 120
                                        nginx.ingress.kubernetes.io/proxy-read-timeout: 120
                                        nginx.ingress.kubernetes.io/proxy-send-timeout: 120
                                        nginx.ingress.kubernetes.io/ssl-redirect: false
        Events:
          Type    Reason  Age    From                      Message
          ----    ------  ----   ----                      -------
          Normal  Sync    6m51s  nginx-ingress-controller  Scheduled for sync
        ```
 - found the pod that is not coming up kubectl describe -n candidate-test pod/candidate-test-d6584d897-qj4bj
        ```
        Events:
          Type     Reason            Age                  From               Message
          ----     ------            ----                 ----               -------
          Warning  FailedScheduling  11m (x225 over 18h)  default-scheduler  no nodes available to schedule pods
          Warning  FailedScheduling  9m4s                 default-scheduler  0/1 nodes are available: 1 node(s) had untolerated taint {node.cloudprovider.kubernetes.io/uninitialized: true}. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling..
          Warning  FailedScheduling  3m50s                default-scheduler  0/1 nodes are available: 1 node(s) didn't match Pod's node affinity/selector. preemption: 0/1 nodes are available: 1 P
        ```
 - most likely the deployment has an incompatible node-selector so checking it out by grabbing the deployment yaml and removing the nodeSelector
        ```
        [ec2-user@ip-180-180-143-20 ~]$ diff deployment.yaml new-deployment.yaml
        60,61d51
        <       nodeSelector:
        <         app: wrong-node-selector
        ---
        >       nodeSelector: {}
        ```
 - deployed change kubectl -n candidate-test apply -f new-deployment.yaml
 - deleted existing pod to speed it up kubectl delete -n candidate-test pod/candidate-test-d6584d897-qj4bj
 - still failed it didn't pick up the nodeSelector change
 - I changed the nodeSelector to app: candidate-test-az-a and replica count to 0 then scaled it up to 1 to get around the preemption policy + nodeselector change
 - it ran into cpu limit issues so I lowered the requests/limits from 20K to 200M and 20M respectively
 - then it couldn't pull the image at all which I then checked in ecr and the tag should be 1.0.0
10:45 still debugging took a breakfast break in the middle of debugging after a few failed attempts
 - finally pulled but crashed!
 - super helpful error at least ;) `Missing enviroment variable called MUST_EXIST`
 - pod is up and healthy
 - nginx call still fails
 - updating ingress definition to point to port 80 instead of 999
 - nginx finally returns `please go the bucket a98db973kwl8 and get the 64611.docx file` (it was a pdf file btw)

11-1 setup terraform code as you can see in the commit history here
1:30 was blocked due to iam issues
2-3:30 finished up what was remaining after a short block

# Final validation
```
[ec2-user@ip-180-180-143-20 eks]$ curl -vvvvv http://derek.nonamesec.com/test1
*   Trying 180.180.138.161:80...
* Connected to derek.nonamesec.com (180.180.138.161) port 80 (#0)
> GET /test1 HTTP/1.1
> Host: derek.nonamesec.com
> User-Agent: curl/8.0.1
> Accept: */*
>
< HTTP/1.1 200 OK
< Date: Wed, 02 Aug 2023 22:23:25 GMT
< Content-Type: application/json
< Content-Length: 19
< Connection: keep-alive
< server: uvicorn
<
* Connection #0 to host derek.nonamesec.com left intact
{"Hello":"World 1"}[ec2-user@ip-180-180-143-20 eks]$ curl -vvvvv http://derek.nonamesec.com/test2
*   Trying 180.180.138.161:80...
* Connected to derek.nonamesec.com (180.180.138.161) port 80 (#0)
> GET /test2 HTTP/1.1
> Host: derek.nonamesec.com
> User-Agent: curl/8.0.1
> Accept: */*
>
< HTTP/1.1 201 Created
< Date: Wed, 02 Aug 2023 22:23:31 GMT
< Content-Type: application/json
< Content-Length: 19
< Connection: keep-alive
< server: uvicorn
<
* Connection #0 to host derek.nonamesec.com left intact
{"Hello":"World 2"}
```
