Minimal Flask API packaged with a Docker image and Kubernetes manifests. Build the image, usage via Rancher Desktop, deploy to Kubernetes, and access it with `kubectl port-forward`.

---

- A small Flask app exposes:
  - `GET /` → JSON greeting
  - `GET /health` → health check for probes
- Dockerfile builds a non-root image and runs Gunicorn.
- Kubernetes manifests define a `Deployment` and a `Service` (ClusterIP).

---

#### Tech used

- Python 3.12
- Flask
- Gunicorn
- Dockerfile / OCI images
- Rancher Desktop (k3s + containerd)
- nerdctl (containerd CLI)
- kubectl (Kubernetes CLI)

---

#### Repository Contents

- `app.py` — Flask application.
- `requirements.txt` — Pinned dependencies.
- `Dockerfile` — Image build instructions (non-root, Gunicorn).
- `.dockerignore` — Common exclusions.
- `k8s/deployment.yaml` — Deployment with readiness/liveness probes.
- `k8s/service.yaml` — ClusterIP Service exposing container port 8000 as port 80 in-cluster.

---

#### Prerequisites

- Rancher Desktop installed and set to **containerd**.
- `kubectl` configured to the Rancher Desktop context (usually `rancher-desktop`).
- `nerdctl` available in the shell.

---

#### Usage

```bash
# Build image into Kubernetes' containerd namespace so the cluster can use it
nerdctl -n k8s.io build -t hello-flask:0.1 .

# Apply Kubernetes manifests
kubectl apply -f k8s/

# Wait until the pod is Running
kubectl get pods -w

# CTRL + C if running
````

Port-forward the Service to the local machine:

```bash
kubectl port-forward svc/hello-flask 8080:80
```

Test:

```bash
curl http://localhost:8080/
# what to expect as output: {"message":"Hello, world!"}
```

---

#### Development Workflow

##### Rebuild and roll out changes

```bash
# Rebuild with a new tag
nerdctl -n k8s.io build -t hello-flask:0.2 .

# Point the deployment to the new image
kubectl set image deploy/hello-flask web=hello-flask:0.2

# Watch rollout
kubectl rollout status deploy/hello-flask
```

##### local container test (before Kubernetes)

```bash
nerdctl build -t hello-flask:0.1 .
nerdctl run -d --name hello -p 8000:8000 hello-flask:0.1
curl http://localhost:8000/
nerdctl rm -f hello
```

---

#### Using Docker (Moby) Instead of containerd

If Rancher Desktop is set to Docker/Moby, Kubernetes will not see `docker build` images. Either switch to containerd and rebuild with `nerdctl -n k8s.io`, or push to a registry and reference it in `deployment.yaml`.

Example (Docker Hub):

```bash
docker build -t hello-flask:0.1 .
docker tag hello-flask:0.1 <dockerhub-username>/hello-flask:0.1
docker login
docker push <dockerhub-username>/hello-flask:0.1
```

Update the deployment image:

```yaml
# k8s/deployment.yaml
containers:
  - name: web
    image: <dockerhub-username>/hello-flask:0.1
    imagePullPolicy: Always
```

Apply:

```bash
kubectl apply -f k8s/
```

---

#### Troubleshooting

**ImagePullBackOff / ErrImagePull / not running**
Kubernetes attempted to pull `docker.io/library/hello-flask:0.1`:

* Build into the k8s namespace:

  ```bash
  nerdctl -n k8s.io build -t hello-flask:0.1 .
  kubectl rollout restart deploy/hello-flask
  ```

---

#### Clean Up

```bash
kubectl delete -f k8s/

# Optional: remove local images
nerdctl -n k8s.io rmi hello-flask:0.1 || true
```