#!/bin/sh
# Operator: https://github.com/spotahome/redis-operator
# Autoscaling   API: autoscaling/v1
# https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.17/#horizontalpodautoscaler-v1-autoscaling
# Redisfailover API: databases.spotahome.com/v1
# Platform: EKS
# Kubernetes Version: 1.17
# Pre-requisite:
# 1. Operator installed, one instance created
# 2. ServiceAccount has sufficient privilege
# 3. HPA created with max/min replicas exactly matches redis replicas
#
# Error code:
# 1. main
# 2. pre_check
# 3. check_current

KUBE_TOKEN=`cat /var/run/secrets/kubernetes.io/serviceaccount/token`
NAMESPACE=`cat /var/run/secrets/kubernetes.io/serviceaccount/namespace`
APICMD="curl -sSk -H \"Authorization: Bearer $KUBE_TOKEN\" https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT"

KUBE_VERSION=v1.17
REDIS_NAMESPACE=redis
HPA_NAME=redis
REDIS_NAME=redisfailover
STS_NAME=rfr-redisfailover

UPPER_THRESHOLD_RANGE=10
LOWER_THRESHOLD_RANGE=10
MAX_REPLICAS=4
MIN_REPLICAS=3

RETRY=3
INTERVAL=15
WAIT_AFTER_SCALE=180

CURRENT_UTIL_AVG=
TARGET_UTIL_AVG=
CURRENT_REPLICAS=
STS_UPDATED_REPLICAS=

COUNTER_SCALE_OUT=0
COUNTER_SCALE_IN=0

main() {

    say="echo main: "
    error_code=1

    apk update -q
    apk add curl jq -q
    rm -rf /var/cache/apk/*

    pre_check

    while true
    do
        # Update all values
	echo
        check_current

        # Do nothing if StatefulSet hasn't updated all pods
        # Reset counters
        if check_replicas_mismatch; then
            $say StatefulSet $REDIS_NAMESPACE/$STS_NAME not updated
            $say Replicas updated: $STS_UPDATED_REPLICAS/$CURRENT_REPLICAS
            reset_counters
            sleep $INTERVAL
            continue
        fi

        # Compare current util and target util, increase counter if threshold reached
 	compare
        STATUS=$?
	
        say="echo scaling: "

    	# Do nothing if utilization in normal range
        # Reset counters
    	if [[ $STATUS -eq 0 ]]; then
            reset_counters
            sleep $INTERVAL

        # Scale-out counter reach retry count
        elif [[ $STATUS -eq 1 ]] && [[ $COUNTER_SCALE_OUT -ge $RETRY ]]; then
            
            # Max replicas reached
            # Reset counter
            if [[ $CURRENT_REPLICAS -ge $MAX_REPLICAS ]]; then
                $say Max replicas reached \($CURRENT_REPLICAS/$MAX_REPLICAS\)
                reset_counters
                sleep $INTERVAL
                continue

            # OK to scale-out
            elif [[ $CURRENT_REPLICAS -lt $MAX_REPLICAS ]]; then
                let "CURRENT_REPLICAS++"
                scale $CURRENT_REPLICAS
                $say Scaled-out to $CURRENT_REPLICAS replicas, max: $MAX_REPLICAS
                reset_counters
                sleep $WAIT_AFTER_SCALE
                continue
            fi

        # Scale-in if counter reach retry count
        elif [[ $STATUS -eq 2 ]] && [[ $COUNTER_SCALE_IN -ge $RETRY ]]; then

            # Min replicas reached
            # Reset counter
            if [[ $CURRENT_REPLICAS -le $MIN_REPLICAS ]]; then
                $say Min replicas reached \($CURRENT_REPLICAS/$MIN_REPLICAS\)
                reset_counters
                sleep $INTERVAL
                continue

            # OK to scale-in
            elif [[ $CURRENT_REPLICAS -gt $MIN_REPLICAS ]]; then
                let "CURRENT_REPLICAS--"
                scale $CURRENT_REPLICAS
                $say Scaled-in to $CURRENT_REPLICAS replicas, min: $MIN_REPLICAS
                reset_counters
                sleep $WAIT_AFTER_SCALE
                continue
            fi
        fi

        # Something is happening, but nothing is triggered
        sleep $INTERVAL
    done
}

# Check pre-requisites 
# Usage: pre_check

function pre_check() {

    say="echo pre_check: "
    error_code=2
    
    # Check installed tools
    for i in jq curl
    do
        if which $i > /dev/null; then
            $say Tool $i OK
        else
            $say Error: Tool $i not found.
            exit $error_code
        fi
    done

    # Check kubernetes version matches configured version
    if eval $APICMD/version | jq '.gitVersion' | grep -q $KUBE_VERSION; then
        $say API version OK
    else
        $say Error: Actual Kubernetes version mismatch with configured version $KUBE_VERSION
        exit $error_code
    fi

    $say Completed!
}

# Check and update usage
# Usage: check_current

function check_current() {

    say="echo check_current: "
    error_code=3

    CURRENT_UTIL_AVG=$(eval $APICMD/apis/autoscaling/v1/namespaces/${REDIS_NAMESPACE}/horizontalpodautoscalers/${HPA_NAME} | jq -r '.status.currentCPUUtilizationPercentage')

    TARGET_UTIL_AVG=$(eval $APICMD/apis/autoscaling/v1/namespaces/${REDIS_NAMESPACE}/horizontalpodautoscalers/${HPA_NAME} | jq -r '.spec.targetCPUUtilizationPercentage')

    CURRENT_REPLICAS=$(eval $APICMD/apis/databases.spotahome.com/v1/namespaces/${REDIS_NAMESPACE}/redisfailovers/${REDIS_NAME} | jq -r '.spec.redis.replicas')

    STS_UPDATED_REPLICAS=$(eval $APICMD/apis/apps/v1/namespaces/${REDIS_NAMESPACE}/statefulsets/${STS_NAME} | jq '.status.updatedReplicas')

    if [[ $CURRENT_UTIL_AVG -ge 0 ]]; then
        $say HPA object $REDIS_NAMESPACE/$HPA_NAME current utilization: $CURRENT_UTIL_AVG
    else
        $say Error: Current average utility not valid for HPA object $REDIS_NAMESPACE/$HPA_NAME
        exit $error_code
    fi

    if [[ $TARGET_UTIL_AVG -ge 0 ]]; then
        $say HPA object $REDIS_NAMESPACE/$HPA_NAME target  utilization: $TARGET_UTIL_AVG
    else
        $say Error: Target average utility not valid for HPA object $REDIS_NAMESPACE/$HPA_NAME
        exit $error_code
    fi

    if [[ $CURRENT_REPLICAS -ge 0 ]]; then
        $say Current custom resource redisfailover ${REDIS_NAMESPACE}/${REDIS_NAME} replicas: $CURRENT_REPLICAS
    else
        $say Error: custom resource redisfailover ${REDIS_NAMESPACE}/${REDIS_NAME} not found
        exit $error_code
    fi

    if [[ $STS_UPDATED_REPLICAS -ge 0 ]]; then
        $say Current statefulset ${REDIS_NAMESPACE}/${STS_NAME} updated replicas: $STS_UPDATED_REPLICAS
    else
        $say Error: Statefulset ${REDIS_NAMESPACE}/${STS_NAME} not found
        exit $error_code
    fi
    
    $say Updated at $(date)
}

# Compare current util and target util, increase counter value
# Usage: comparea
# Return value:
# 0 - Normal
# 1 - Too high
# 2 - Too low

function compare() {
    
    say="echo compare: "

    if [[ $CURRENT_UTIL_AVG -gt $(($TARGET_UTIL_AVG + $UPPER_THRESHOLD_RANGE)) ]]; then
        if [[ $COUNTER_SCALE_OUT -ge $RETRY ]]; then
            COUNTER_SCALE_OUT=$RETRY
        else
            let "COUNTER_SCALE_OUT++"
        fi
        COUNTER_SCALE_IN=0
        $say utilization too high \($CURRENT_UTIL_AVG/$TARGET_UTIL_AVG\), setting scale-out counter to $COUNTER_SCALE_OUT
    	return 1

    elif [[ $CURRENT_UTIL_AVG -lt $(($TARGET_UTIL_AVG - $LOWER_THRESHOLD_RANGE)) ]]; then
        if [[ $COUNTER_SCALE_IN -ge $RETRY ]]; then
            COUNTER_SCALE_IN=$RETRY
        else
            let "COUNTER_SCALE_IN++"
        fi
        COUNTER_SCALE_OUT=0
        $say utilization too low \($CURRENT_UTIL_AVG/$TARGET_UTIL_AVG\), setting scale-in counter to $COUNTER_SCALE_IN
    	return 2

    else
        $say utilization OK \($CURRENT_UTIL_AVG/$TARGET_UTIL_AVG\)
    	return 0
    fi
}

# Check if current replicas equals target replicas
# Usage: check_replicas_mismatch
# Return value:
# 0 - Mismatch
# 1 - Match

function check_replicas_mismatch() {
    say="echo check_replicas_mismatch: "
    if [[ $CURRENT_REPLICAS -ne $STS_UPDATED_REPLICAS ]]; then
        return 0
    else
        return 1
    fi
}

# Update redis replicas
# Usage: scale $TARGET_REPLICAS

function scale() {

curl -sSk \
    -X PATCH\
    -d @- \
    -H "Authorization: Bearer $KUBE_TOKEN" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/merge-patch+json' \
    https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/autoscaling/v1/namespaces/${REDIS_NAMESPACE}/horizontalpodautoscalers/${HPA_NAME} <<EOF
{
    "kind": "HorizontalPodAutoscaler",
    "apiVersion": "autoscaling/v1",
    "metadata": {
        "name": "${HPA_NAME}",
        "namespace": "${REDIS_NAMESPACE}"  },
    "spec": {
    "maxReplicas": $1,
    "minReplicas": $1
    }
}
EOF

curl -sSk \
    -X PATCH\
    -d @- \
    -H "Authorization: Bearer $KUBE_TOKEN" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/merge-patch+json' \
    https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/databases.spotahome.com/v1/namespaces/${REDIS_NAMESPACE}/redisfailovers/${REDIS_NAME} <<EOF
{
    "kind": "RedisFailover",
    "apiVersion": "databases.spotahome.com/v1",
    "metadata": {
        "name": "${REDIS_NAME}",
        "namespace": "${REDIS_NAMESPACE}"  },
    "spec": {
        "redis": {
            "replicas": $1
        },
        "sentinel": {
            "replicas": 3
        }
    }
}
EOF

}

# Reset counters

function reset_counters() {
    say="echo reset_counters: "
    COUNTER_SCALE_OUT=0
    COUNTER_SCALE_IN=0
    $say Resetting counters...
}

# Execution

main "$@"
exit
