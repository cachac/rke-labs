#!/bin/bash
KUBE_PRIMARY=kube-master02

# Unassign peer's IP aliases. Try it until it's possible.
for node in "kube-master03" "kube-master02"
do
	until gcloud compute instances network-interfaces update $node \
		--zone="us-central1-a" \
		--aliases "" >> /etc/keepalived/takeover.log 2>&1; do
				echo "Instance $node not accessible during takeover. Retrying in 5 seconds..."
				sleep 5
	done
done

# Assign IP aliases to me because now I am the MASTER!
gcloud compute instances network-interfaces update ${KUBE_PRIMARY} \
	--zone="us-central1-a" \
	--aliases "10.0.0.3" >> /etc/keepalived/takeover.log 2>&1
sleep 5

systemctl restart haproxy
echo "I became the MASTER at: $(date)" >> /etc/keepalived/takeover.log
