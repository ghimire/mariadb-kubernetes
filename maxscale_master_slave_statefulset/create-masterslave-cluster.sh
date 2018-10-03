#!/bin/bash
# Copyright (C) 2018 MariaDB Corporation
# Creates a templetised master-slave cluster fronted by MaxScale in Kubernetes
# User-defined parameters are "application" and "environment"

function print_usage() {
    echo "Usage: "
    echo "create-masterslave-cluster.sh -a <application> -e <environment> [<options>]"
    echo ""
    echo "Required options: "
    echo "         -a <application name>"
    echo "         -e <environment name>"
    echo "         -id <id, integer>"
    echo ""
    echo "<application name>-<environment name> will be prepended to kubernetes instance names"
    echo ""
    echo "Supported options: "
    echo "         -t <template>, default: masterslave"
    echo "         -u <database user>, default: mariadb-admin"
    echo "         -p <database password>, default: autogenerated"
    echo "         --repl-user <replication user>, default: repl"
    echo "         --repl-password <replication password>, default: autogenerated"
    echo "         --dry-run generate yaml definitions only"
    echo "         --delete delete the cluster"
    echo "         -h print this screen"
    exit 1
}

function parse_options() {
    APP=""
    ENV=""
    DBUSER="admin"
    DBPWD=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
    REPLUSER="repl"
    REPLPWD=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
    DRY_RUN=""
    VOLSIZE="1"
    DELETE="no"
    CATALOG="masterslave"
    
    while [[ $# -gt 0 ]]
    do

    key="$1"
    case $key in
        (-a|--app)
        APP="$2"
        shift
        shift
        ;;
        (-e|--env)
        ENV="$2"
        shift
        shift
        ;;
        (-id)
        ID="$2"
        shift
        shift
        ;;
        (-u|--db-user)
        DBUSER="$2"
        shift
        shift
        ;;
        (-p|--db-pass)
        DBPWD="$2"
        shift
        shift
        ;;
        (--dry-run)
        DRY_RUN="--dry-run -o yaml"
        shift
        ;;
        (-d|--delete)
        DELETE="yes"
        shift
        ;;
        (-t|--template)
        CATALOG="$2"
        shift
        shift
        ;;
        (-h|*)
        print_usage
        ;;
    esac
    done

    if [[ -z "$APP" ]]; then
       print_usage
    fi

    if [[ -z "$ENV" ]]; then
       print_usage
    fi

    if [[ -z "$ID" ]]; then
       print_usage
    fi

    LABEL="$APP-$ENV"
    MARIADB_ID="$ID"
}

function expand_templates() {
    # copy template files to a temp directory
    TEMPDIR=$(mktemp -d)
    cp -r "$DIR/catalog" "$TEMPDIR"
    cp -r "$DIR/config" "$TEMPDIR"
    # cp -r "$DIR/state-store" "$TEMPDIR"

    TEMPLATE="$TEMPDIR/catalog"
    # STATE_STORE="$TEMPDIR/state-store"
    CONFIG="$TEMPDIR/config"

    INITIAL_COUNT_MAXSCALE=2
    INITIAL_COUNT_TX=3

    for filename in $TEMPLATE/*.yaml; do
        sed -e "s/{{ .Values.APP_NAME }}/$APP/g" \
            -e "s/{{ .Values.ENV_NAME }}/$ENV/g" \
            -e "s/{{ .Values.ID }}/$ID/g" \
            -e "s/{{ .Values.LABEL }}/$LABEL/g" \
            -e "s/{{ .Values.MARIADB_VOLUME_SIZE }}/$VOLSIZE/g" \
            -e "s/{{ .Values.ADMIN_USERNAME | b64enc }}/$(echo -n $DBUSER | base64)/g" \
            -e "s/{{ .Values.ADMIN_PASSWORD | b64enc }}/$(echo -n $DBPWD | base64)/g" \
            -e "s/{{ .Values.REPLICATION_USERNAME | b64enc }}/$(echo -n $REPLUSER | base64)/g" \
            -e "s/{{ .Values.REPLICATION_PASSWORD | b64enc }}/$(echo -n $REPLPWD | base64)/g" \
            -e "s/{{ .Values.INITIAL_COUNT_MAXSCALE }}/$INITIAL_COUNT_MAXSCALE/g" \
            -e "s/{{ .Values.INITIAL_COUNT_TX }}/$INITIAL_COUNT_TX/g" \
            -i $filename
    done
}

parse_options "$@"

# get directory of script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
KUBECTL=kubectl

# ensure template exists
yaml_cnt=0
for yaml in $(grep -E "^$CATALOG=" "$DIR"/catalog/catalog | sed -e "s/^$CATALOG=//g"); do
    if [ ! -f "$DIR/catalog/$yaml" ]; then
       >&2 echo "YAML template $yaml does not exist"
       print_usage
    fi

    yaml_cnt=$((yaml_cnt+1))
done

if [ "$yaml_cnt" == "0" ]; then
   >&2 echo "unknown template $CATALOG specified"
   print_usage
fi

# delete cluster and exit if requested
if [ "$DELETE" == "yes" ]; then
   set -e

   $KUBECTL delete svc,sts,deployment,secret,configmap -l mariadb=$LABEL,id.mariadb=$ID
   $KUBECTL delete pvc -l mariadb=$LABEL,id.mariadb=$ID

   exit 0
fi

expand_templates

if [ "$DRY_RUN" == "" ]; then
   $KUBECTL delete configmap -l mariadb=$LABEL,id.mariadb=$ID 2> /dev/null
fi

set -e

# compress the state store in order for it to fit in a config map
# tar czf "$CONFIG"/state-store.tar.gz -C "$STATE_STORE" .
# rm -R -f "$STATE_STORE"

# create configmaps for the configurations of the two types of service
$KUBECTL create configmap $LABEL-mariadb-config --from-file="$CONFIG"
# IMPORTANT: we want the config map to be shared amongst all instances, removing labeling below
# $KUBECTL label configmap $LABEL-mariadb-config mariadb=$LABEL
# $KUBECTL label configmap $LABEL-mariadb-config id.mariadb=$ID
if [ "$DRY_RUN" != "" ]; then
   echo "---"
fi

# create the secret that holds user names and passwords
$KUBECTL create -f "$TEMPLATE"/mariadb-secret.yaml $DRY_RUN
if [ "$DRY_RUN" != "" ]; then
   echo "---"
fi

# apply templates
for yaml in $(grep -E "^$CATALOG=" "$DIR"/catalog/catalog | sed -e "s/^$CATALOG=//g"); do
    $KUBECTL create -f "$TEMPLATE/$yaml" $DRY_RUN
    if [ "$DRY_RUN" != "" ]; then
       echo "---"
    fi
done

# cleanup temporary files
rm -R -f "$TEMPDIR"
# done
