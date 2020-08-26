#!/usr/bin/env bash
cd "$(dirname "$0")"
source ./mo.sh
export AIRFLOW_HOME=${PWD}

export ENABLE_AIRFLOW_AUTH=1
export AIRFLOW_VERSION=1.10.12

function WEBSERVER_AUTH() {
    if [[ $ENABLE_AIRFLOW_AUTH == 1 ]]; then
        echo "authenticate = True"
        echo "rbac = True"
        echo "auth_backend = airflow.contrib.auth.backends.password_auth"
    else
        echo "authenticate = False"
        echo "rbac = False"
    fi
}

virtualenv -p `which python3` .
echo "export AIRFLOW_HOME=${AIRFLOW_HOME}" >> bin/activate
source bin/activate
pip install --upgrade pip
# pip install pendulum==1.4.4
# AIRFLOW_GPL_UNIDECODE=true pip install apache-airflow[crypto,password]==${AIRFLOW_VERSION}

export PYTHON_VERSION=$(python3 -c "import sys; print('%s.%s' % (sys.version_info.major, sys.version_info.minor))")
pip install \
     apache-airflow[crypto,password]==${AIRFLOW_VERSION} \
      --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

if [[ $AIRFLOW_VERSION == "1.10.3" ]]; then # killme
    # Apache Airflow : airflow initdb throws ModuleNotFoundError: No module named 'werkzeug.wrappers.json'; 'werkzeug.wrappers' is not a package error
    # https://stackoverflow.com/questions/56933523/apache-airflow-airflow-initdb-throws-modulenotfounderror-no-module-named-wer
    pip install -U Flask==1.0.4
    # pip install werkzeug==0.15.5
fi

if [[ $AIRFLOW_VERSION == "1.10.8" ]]; then # killme
    # Apache Airflow : airflow initdb throws ImportError: cannot import name 'secure_filename' from 'werkzeug'
    # https://stackoverflow.com/questions/60104484/cannot-run-apache-airflow-after-fresh-install-python-import-error
    pip install werkzeug==0.16.0
fi

# pip install --no-deps airflow-code-editor
rm -rf plugins
mkdir -p plugins
ln -sf "${PWD}/../airflow_code_editor" plugins/airflow_code_editor

mo -u < airflow.cfg.tmpl > airflow.cfg
airflow initdb

if [[ $ENABLE_AIRFLOW_AUTH == 1 ]]; then
    # Create user 'admin' with password 'admin'
    airflow create_user -r Admin -u admin -e admin@example.com -f admin -l admin -p admin
fi

