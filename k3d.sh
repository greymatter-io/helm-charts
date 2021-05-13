make destroy
make k3d
export KUBECONFIG=$(k3d kubeconfig write greymatter)
make secrets
make install