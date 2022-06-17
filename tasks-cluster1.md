

# Cluster 1 Tasks

## 1. Troubleshoot the API Server
This task is intended more as a troubleshooting rehersal and command memory as you'll know what the issue is when you break the API server! Keep that in mind to get the best out of it.

1. Break the API Server by changing a parameter in the static pod manifest for the API server (/etc/kubernetes/manifests). Eg, change `--authorization-mode` to include a bunch of random letters. 
1. Restore the API server (move the manifest from the /etc/kubernetes/manifests dir to somewhere else and then move it back).
1. Confirm you are not able to access the API server by running `kubectl get nodes` (you should recieve an error).
1. Check the logs to find the reason for the API server going down.


<br><hr>
<details>
  <summary>Click to show answer!</summary>
    There isn't one correct answer to this task. The main aim is to familiarise yourself with the tools at your disposal for troubleshooting a broken cluster.<br><br>
    Try using the following to see if you can identify the root cause in the logs:<br><br>
    - journalctl -u kubelet<br>
    - journalctl -g "warn|error" | less<br>
    - Check the logs in /var/log/containers/kube-api<br>
    - crictl ps -a<br>
    - crictl log kube-api-containerid<br>
    <br>
    When you're done, revert the breaking change you made to the API server so you can continue with the remaining tasks in the cluster. Alternatively, tear down the cluster and bring it back up to start afresh.
</details>
<hr><br>

## 2. Web Server - Deployment
1. Create a namespace called `web-deployment` and create a deployment called `web` running nginx:alpine, running 3 replicas
1. Create a ClusterIP service using the `expose` command
1. Run a stand alone pod called `client` running the alpine/curl image, to curl the service and confirm connectivity (using the IP **and** the DNS of the service).
1. Delete the ClusterIP service and create a nodeport service called `web-nodeport` using port 30080. Connect to the nginx deployment via the host machine, if it doesn't work - fix it.

<br><hr>
<details>
  <summary>Click to show answer!</summary>
    <pre>
        <code>
        k create deployment web –image=nginx:alpine –port=80 –replicas=3
        k expose deployment web –port=80 –target-port=80
        k run pod1 –image=alpine/curl –command – curl <service_ip>:80
        k run pod2 –image=alpine/curl –command – curl http://web.web-deployment.svc.cluster.local:80
        k create service nodeport web-nodeport –tcp=80:80 –node-port=30080
        k edit service web-nodeport (update the selector match to app: web)
        </code>
    </pre>
</details>
<hr><br>

## 3. Web Server - Scale Up
Using the same deployment from the previous task:
1. Scale the deployment up to 5 using the `scale` command
1. Scale the deployment down to 1 using the `edit` command

<br><hr>
<details>
  <summary>Click to show answer!</summary>
    <pre>
        <code>
        k scale deployment web –replicas=5
        k edit deployment/web
        </code>
    </pre>
</details>
<hr><br>

## 4. Rollback Deployment
**Note:** This involves a feature which _may_ be deprecated now but it could be useful from a real world point of view where clusters aren't always running the latest version.

1. Change the image of the `web` deployment to use httpd:alpine3.15 using the `set` command **and** ensure that the change is recorded.
1. Check you can view the change in the deployment history
1. Uh oh! The change broke a thing - roll it back to a previous working revision!
1. Limit the revision history to 3 for the `web` deployment.

<br><hr>
<details>
  <summary>Click to show answer!</summary>
    <pre>
        <code>
        k set image deployment web nginx=httpd:alpine3.15 –record (note that record is now deprecated)
        k rollout history deployment web
        k rollout undo deployment web –to-revision=4
        k edit deployment web (spec.revisionHistoryLimit)
        </code>
    </pre>
</details>
<hr><br>

## 5. Scheduling Pods
1. Create a namespace called `scheduling` and create a deployment called `nodeSelector` which will explicitly get scheduled on _any_ control plane nodes using a `nodeSelector` - why doesn't the pod run?
1. Edit the deployment so that is **does** get scheduled on a control plane node.
1. Create a deployment called `nodename` which will explicitly get scheduled on `cluster1-master1`.
1. Create a pod which will automatically run on each current **and future** node in the cluster. (Hint: take a look at the network plugin pods...)
1. Create a static pod on one of the worker nodes (hint: this is **NOT** the same as a stand alone pod)

<br><hr>
<details>
  <summary>Click to show answer!</summary>
    <pre>
        <code>
        k create deployment nodeselector –image=nginx:alpine
        k edit deployment nodeselector (spec.template.spec.nodeSelector - key: value with a relevant node label, such as node-role.kubernetes.io/master: “”. It doesn’t work because the node has a taint called node-role.kubernetes.io/master with an effect of NoSchedule. To fix this, you need to add a toleration.
        <br>
        k edit deployment nodeselector (add spec.template.spec.tolerations
        Key (keyname of taint on node)
        Effect (NoSchedule, PerferNoSchedule or NoExecute)
        Operator (Either Exists or Equals)
        <br>
        k create deployment nodename –image=nginx:alpine
        k edit deployment nodename (spec.template.spec.nodeName)
        <br>
        k create deployment daemonset –image=nginx:alpine –dry-run=client -o yaml > daemonset.yaml (change kind to “DaemonSet” and remove deployment specific fields: replicas, status, resources, strategy)
        k apply -f daemonset.yaml
        <br>
        k run static –image=nginx:alpine –dry-run=client -o yaml > static.yaml
        scp static.yaml root@cluster1-worker2:/etc/kubernetes/manifests/static.yaml
        </code>
    </pre>
</details>
<hr><br>

## 6. Affinity/Anti-Affinity
1. Create a namespace called `affinity` and create a deployment called `web`, running nginx:alpine with 3 replicas. Make sure they're only deployed onto nodes called `cluster1-worker1` and `cluster1-worker2` and also make sure that not more than 1 pod is deployed on a single node. If done correctly, you should see 3 pods for the deployment but only 2 are running.

<br><hr>
<details>
  <summary>Click to show answer!</summary>
  Create the definition for the deployment first, and then add the affinity object to the yaml file before running a kubectl apply...
    <pre>
        <code>
        k create deployment affinity –image=nginx:alpine –dry-run=client -o affinity.yaml > affinity.yaml
        </code>
    </pre><br>
    The affinity properties should look something like this:
      <pre>
        <code>
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - cluster1-worker1
                        - cluster1-worker2
          podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                  matchLabels:
                    app: affinity
                topologyKey: kubernetes.io/hostname        
        </code>
      </pre>  
</details>
<hr><br>

## 7. Pod Resources
1. Create a namespace called `resource` and create a deployment called `stress` using the progrium/stress image with 1 replica. Run the container with the command `stress --cpu 4 --backoff 5000`. (If you need to clean up some previous task deployments in order to run this pod, then do so).
1. Sort all pods in the cluster by CPU, using the `kubectl top` command - why doesn't it work?
1. Install a metrics server and retry the above again. (You will need to add the `--kubelet-insecure-tls` argument to the metrics server if it doesn't work)
    1. `wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml -O metrics-server-components.yaml`
    1. Add the above mentioned parameter to the downloaded spec
    1. `kubectl apply -f metrics-server-components.yaml`
1. Edit the `stress` deployment to _limit_ the CPU resources to 1 CPU
1. Confirm the pod is using no more than 1 CPU
1. Remove the limits from the deployment and scale the deployment to 4 pods
1. Confirm the worker nodes are using ~100% CPU
1. Create a new deployment called `nogo` with image nginx:alpine which _requires_ 8 CPU - confirm that it **doesn't** get scheduled onto a node.

**Note:** Delete the `resource` namespace after these set of tasks, to alleviate the pressure on the nodes.

<br><hr>
<details>
  <summary>Click to show answer!</summary>
    <pre>
        <code>
        k create deployment stress –image=progium/stress (edit container command to the required params)
        k top pods –sort-by cpu –all-namespaces (doesn’t work because a metrics server isn’t running)
        k top pods –sort-by cpu –all-namespaces
        k edit deployment stress (spec.template.spec.containers.resources.limits cpu: 1)
        k top pods –sort-by cpu
        k edit deployment stress (remove resources key + child items and change replicas to 4)
        k top nodes
        k create deployment nogo –image=nginx:alpine –dry-run=client -o yaml > nogo.yaml
        vim nogo.yaml (spec.template.spec.containers.resources.requests cpu: 2) -> pod remains in pending state     
        </code>
      </pre>  
</details>

<hr><br>

## 8. ConfigMaps and Secrets
1. Create a namespace called `configmaps` and a configmap called `from-literal` with data: _myFile: this is my file data_ and _myVar: myEnvVar_
1. Create an env file with variables, _FOO=bar_ and _BAZ=foo_. Create a second configmap called `from-file` using this env file as a source.
1. Create a generic secret called `my-secret` with data: _mySecret: VerySecurePassword_
1. Create a pod running nginx:alpine which:
    1. Creates a file in /myConfigFiles called _myFile_ with the corresponding data from _myFile_ from the `from-literal` configmap, as the file contents
    1. Has an environment variable called _MY_ENV_VAR_  with the corresponding value from _myVar_ from the `from-literal` configmap
    1. Loads all the environment variables from the env file, `from-file` configmap
1. Create a pod which loads _mySecret_ from `my-secret` to an environment variable called APPLICATION_PASSWORD

<br><hr>
<details>
  <summary>Click to show answer!</summary>
    <pre>
        <code>
          k create configmap myconfigmap1 --from-literal=myFile="this is my data" --from-literal=myVar=myEnvVar
          cat <<EOF >.myenvfile FOO=bar BAZ=foo EOF
          k create configmap myconfigmap2 --from-env-file=/home/vagrant/.myenvfile
          k create secret generic mysecret1 --from-literal=mySecret=VerySecurePassword
          k create deployment configpod –image=nginx:alpine 
          edit the config to add a spec.template.spec.volumes.configMap and also a spec.template.spec.containers.volumeMounts with a mountPath and name
          edit the config to add a spec.template.spec.containers.env.valueFrom.configMapKeyRef with a key of myVar and name which matches the configmap.
          k edit deployment configpod (add spec.template.spec.containers.env.valueFrom.secretKeyRef with a key of mysecret and a name which matches the secret
        </code>
      </pre>  
</details>
<hr><br>

## 9. General kubectl Commands
These commands aim to help in learning to filter and sort kubernetes objects. The kubectl cheatsheet in the docs is a very good source to use so make sure you familiarize yourself with that in preparation for the exam.

1. Display all pods running in the cluster sorted by name
1. Change current context namespace to `default`
1. Display the current context **in use**
1. Display all pods which have a selector of _app=web_
1. Create a pod with a non-existent image name. Display all pods in the cluster which are **not** running. (Hint: the one with the non-existent name should at least be displayed)
1. Display all services, deployments and pods in the `management` namespace
1. Return the number of services, deployments and pods in the `management` namespace.

<br><hr>
<details>
  <summary>Click to show answer!</summary>
    <pre>
        <code>
        k get pods –all-namespaces –sort-by=.metadata.name
        k config set-context –current –namespace default
        k config view –minify
        k get pods –all-namespaces –selector app=web
        k run pod broken –image=nginx:asdasd -n management
        k get pods –field-selector=status.phase!=Running –all-namespaces (note, web-server is in an “error” state but appears in this list because at least 1 of the containers is in a running state)
        k get services,pods,deployments -n management
        k get services,pods,deployments -n management -o jsonpath=”{range.items[*]} {.metadata.name} {‘\n’}” | wc -l (note: the extra new line with the last item means the result is actually the $output - 1)
        Note: a more succinct way would be (plus it doesn’t have the ending carriage return problem like the previous example):
        k get services,pods,deployments -n management –no-headers | wc -l
        </code>
      </pre>
      <b>Note:</b> I've included 2 examples for the last task. The latter is a superior method to use but there's value in seeing the iteration syntax with the jsonpath query which is why I've kept it in.
</details>
<hr><br>

## 10. Network Policies
1. Create 2 namespaces, `netpol1` and `netpol2`. Create 2 deployments (1 in each, named after the namespace they're in) running the nginx:alpine image. Create a service for the `netpol2` so it's contactable from within the cluster.
1. Confirm you can `curl` from `netpol1` to `netpol2` and hit the default nginx welcome page.
1. Create a network policy applied to the `netpol2` deployment that blocks all traffic to it. Confirm you're no longer able to see the Nginx welcome page from `netpol1`.
1. Create a second deployment in the `netpol1` namespace called `web` running nginx:alpine and ammend the network policy to allow traffic from `web` only, to the `netpol2` deployment. Confirm this works by getting the welcome page from the `web` pod but not from the `netpol1` pod.

<br><hr>
<details>
  <summary>Click to show answer!</summary>
    <pre>
      <code>
      k create namespace netpol1 && k create namespace netpol2
      k create deployment netpol1 –image=nginx:alpine –namespace netpol1
      k create deployment netpol2 –image=nginx:alpine –namespace netpol2
      k expose deployment netpol2 –port 80 –target-port 80 –namespace netpol2
      k exec deploy/netpol1 – curl -s http://netpol2.netpol2.svc.cluster.local
      </code>
    </pre><br><br>
      The rest of the commands requires some declarative yaml files and kubectl apply -f ...<br><br>
      Create the network policy:
    <pre>
      <code>
        kind: NetworkPolicy
        apiVersion: networking.k8s.io/v1
        metadata:
          name: netpol-2
          namespace: netpol2
        spec:
          podSelector:
            matchLabels:
              app: netpol2
      </code>
    </pre><br><br>
    <pre>
      <code>
        k exec deploy/netpol1 – curl -s http://netpol2.netpol2.svc.cluster.local (should just hang - no response)
        k create deployment web –image=nginx:alpine –namespace netpol1
      </code>
    </pre><br><br> 
    Create the policy to allow traffic from web but not from netpol1
    <pre>
      <code>
      kind: NetworkPolicy
      apiVersion: networking.k8s.io/v1
      metadata:
        name: netpol-2
        namespace: netpol2
      spec:
        podSelector:
          matchLabels:
            app: netpol2
        ingress:
      from:
      namespaceSelector:
        matchLabels: 
          kubernetes.io/metadata.name: netpol1
      podSelector:
        matchLabels:
          app: web
      </code>
    </pre><br><br>
    <pre>
      <code>
      k exec deploy/web – curl -s http://netpol2.netpol2.svc.cluster.local (should return the default nginx welcome page)
      </code>
    </pre>
</details>
<hr><br>

## 11. RBAC and Service Accounts
**Note:** Since creating these, I've briefly found out about `kubectl auth can-i` commands. These might be a better way to validate the auth in the proceeding tasks. Feel free to use the `auth` command instead. Bonus points for a PR to update these :)

1. Create 2 namespaces, `rbac1` and `rbac2`. Run a prod called `rbac-test` using the image luksa/kubectl-proxy in the `rbac1` namespace.
1. Confirm that RBAC is enabled by `curl`ing the API from inside the pod, to list all service accounts in the `rbac` namespace. (Hint: localhost:8001/api/v1/namespaces/rbac1/serviceaccounts - you should expect to see a forbidden response)
1. Create a role called `read-role` in the `rbac1` namespace which grants the GET and LIST verbs to the services resource.
1. Create a headless service (just to view a service resource in the namespace - it doesn't need to do anything)
1. Create a rolebinding called `read-role-binding` which binds `read-role` to the default service account used by pods in that namespace. Test you can now list services within the `rbac-test` pod in the `rbac1` namespace.
1. Check if you can list the service accounts in the `rbac2` namespace. Create the necessary resources to allow the service account in `rbac1` to list service accounts in `rbac2`. Confirm this has worked.
1. Create the necessary resources to allow the default serviceaccount in `rbac1` to list all pods in **all** namespaces. (Hint: localhost:8001/api/v1/pods)
1. Create the necessary resources to allow the default serviceaccount in `rbac1` to list all pods in all namespaces **except** `kube-system` (Hint: localhost:8001/api/v1/namespaces/< any namespace except kube-system >/pods)

<br><hr>
<details>
  <summary>Click to show answer!</summary>
    <pre>
        <code>
        k create namespace rbac1 && k create namespace rbac2
        k run rbac-test –image=luksa/kubectl-proxy -n rbac1
        <br>
        k exec rbac-test -n rbac1 – curl -s localhost:8001/api/v1/namespaces/rbac1/serviceaccounts
        (Should receive a response which gives you a status: Failure and reason: Forbidden).
        <br>
        k create role read-role -n rbac1 –verb=get –verb=list –resource=services
        <br>
        k create rolebinding read-role-bind -n rbac1 –role read-role –serviceaccount=rbac1:default
        k exec rbac-test -n rbac1 – curl localhost:8001/api/v1/namespaces/rbac1/service (Should receive a payload which describes all the services in rbac1)
        <br>
        k create role read-role -n rbac2 –verb=get –verb=list –resource=services
        k create rolebinding read-role-bind -n rbac2 –role read-role –serviceaccount=rbac1:default
        k exec rbac-test -n rbac1 – curl -s localhost:8001/api/v1/namespaces/rbac2/services (Should see the description of the service accounts in the rbac2 namespace)
        <br>
        k create clusterrole pod-reader –verb=get,list –resource=pods
        k create clusterrolebinding pod-reader-bind –clusterrole pod-reader –serviceaccount rbac1:default
        k exec rbac-test -n rbac1 – curl -s localhost:8001/api/v1/pods (Should list all pods)
        <br>
        (remove the cluster role binding from previous test first)
        k create role pod-reader –verb=get,list –resource=pods -n < not kube-system > (for all namespaces except kube-system)
        k create rolebinding pod-reader-binding –role pod-reader –serviceaccount=rbac1:default -n < not kube-system >
        (There is no exclude mechanism so you have to create a role + binding for each namespace in the cluster that isn’t kube-system)
        </code>
      </pre>
</details>
<hr><br>

## 12. Volumes and Persistent Volumes/Claims
1. Create a namespace called `volumes`. Create a deployment called `host-vol` with a mounted volume from /data (on the host) to /output on the container. Confirm a file created on the host at /data/ is seen on the container at /output.
1. Create a deployment called `shared-vol` with 2 containers which share a volume in local dir: /output. Confirm that a file created on one container is seen on the other container.
1. Create a pesistent volume called `pv-retain` backed by the host at /data/pv with 1Gi of storage. Create a PVC and a deployment which uses it, mounted to /output. Write data to it and confirm the data exists the host's underlying filesystem.
1. Create a storage class called `fast` which doesn't allow volume expansion and uses the _kubernetes.io/no-provisioner_ as the provisioner. Create a PV which uses the `fast` storage class with 100Mi capacity. Then create a PVC which requests for 50Mi of the PV. Attempt to change the capacity to 100Mi.

<br><hr>
<details>
  <summary>Click to show answer!</summary>
    <pre>
      <code>
      mkdir /data && echo “some data to put in the file” > /data/somefile.txt && k create namespace volumes
      k create deployment host-vol –image=nginx:alpine (edit the deployment to run on the master node and add deployment.spec.template.spec.volumes (hostPath.path: /data hostPath.name: data-host-vol) Add deployment.spec.template.spec.containers.volumeMounts (mountPath: /output name: data-host-vol) with deployment.spec.template.spec.nodeSelector: node-role.kubernetes.io/master: “” and deployment.spec.template.spec.tolerations key: node-role.kubernetes.io/master operator: Exists)
      k exec deploy/host-vol – cat /output/somefile.txt
      <br>
      k create deployment shared-vol –image=nginx:alpine (edit the deployment to add deployment.spec.template.spec.volumes (emptyDir: {} and name: shared-vol). Add a second container to the deployment running busybox. Add deployment.spec.template.spec.containers[*]volumeMounts (name: shared-vol mountPath: /output)). Note: If you set the busybox to write data out to /output/somefile.txt, you’ll be able to check that the other container can see it with the exec command.
      </code>
    </pre><br><br>
    Then apply the following PV and PVC
    <pre>
      <code>
      apiVersion: v1
      kind: PersistentVolume
      metadata:
        name: pv-retain
      spec:
        storageClassName: ''
        persistentVolumeReclaimPolicy: Retain
        hostPath:
          path: /data/pv
        accessModes:
          - ReadWriteOnce
        capacity:
          storage: 1Gi
      <br>
      apiVersion: v1
      kind: PersistentVolumeClaim
      metadata:
        name: pv-retain-claim
      spec:
        accessModes:
          - ReadWriteOnce
        volumeName: pv-retain
        resources:
          requests:
            storage: 1Gi      
      </code>
    </pre><br><br>  
    Test the PVC with a pod...
    <pre>
      <code>
      k create deployment pv-test –image=nginx:alpine (edit deployment.spec.template.spec.volumes (name: pv-retain-vol).persistentVolumeClaim (claimName: pv-retain-claim and deployment.spec.template.spec.containers.volumeMounts (name: pv-retain-vol and mountPath: /output))
      k exec deploy/pv-test –tty –stdin – /bin/sh (date > /output/somedata.txt)
      k get pods -o wide (check which node the pod is on and make sure the data exists on the host in /data/pv/somedata.txt)
      </code>
    </pre><br><br>
    Create the "fast" storage class and PV, PVC
    <pre>
      <code>
      apiVersion: storage.k8s.io/v1
      kind: StorageClass
      metadata:
        name: fast
      provisioner: kubernetes.io/no-provisioner
      allowVolumeExpansion: false
      <br>
      apiVersion: v1
      kind: PersistentVolume
      metadata:
        name: pv-expand
      spec:
        storageClassName: fast
        capacity:
          storage: 100Mi
        accessModes:
        - ReadWriteOnce
        hostPath:
          path: /data/fast/pv
      <br>
      apiVersion: v1
      kind: PersistentVolumeClaim
      metadata:
        name: pvc-expand
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 50Mi
        storageClassName: fast       
      </code>
    </pre><br><br>  
    Expand the vol:
    <pre>
      <code>
    k edit pvc pvc-expand (Edit the storage request to 100Mi - should result in this error:
error: persistentvolumeclaims "pvc-expand" could not be patched: persistentvolumeclaims "pvc-expand" is forbidden: only dynamically provisioned pvc can be resized and the storageclass that provisions the pvc must support resize )
      </code>
    </pre><br><br>  
</details>
<hr><br>

## 13. Horizontal Pod Autoscaler
1. Create a namespace called `hpa`
1. Create a deployment called `hpa` using the _k8s.gcr.io/hpa-example_ image with 1 replica. Make sure the deployment has the following resources set:
    1. limits: cpu: 500m
    1. requests: cpu: 200m
1. Expose the deployment on port 80 with a target of 80
1. Create an HPA resource for the `hpa` deployment with a min of 1, max of 10 and scales based on CPU (percent 50)
1. Run `k get hpa` - why do the targets say "unknown/50%"?
1. Fix the above to make it work
1. Create a pod called `loadgen` which runs the following command:
```
while sleep 0.01; do wget -q -O- http://hpa; done
```
This will generate load to the HPA deployment. The replicas should start to increment. Watch this with `k get hpa hpa --watch`

<br><hr>
<details>
  <summary>Click to show answer!</summary>
    <pre>
        <code>
        k create namespace hpa
        k create deployment hpa –image=k8s.gcr.io/hpa-example
        (add cpu requests and limits for deployment.spec.template.spec.containers)
        k expose deployment hpa –port 80 –target-port 80
        k autoscale deployment hpa –cpu-percent=50 –min=1 –max=10
        Doesn’t work because metrics server isn’t enabled and HPA needs a metrics server to observe in order to work.
        wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml -O metrics-server-components.yaml (note: need to to edit the metrics server deployment to add the –kubelet-insecure-tls flag to the list of args)
        k get hpa hpa –watch
        </code>
      </pre>
</details>
<hr><br>
