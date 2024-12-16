pipeline {
    agent any

    environment {
        VAULT_ADDR = "http://34.230.183.157:8200"
        VAULT_TOKEN = credentials('vault-token') // Add Vault token in Jenkins credentials
        ROLE_NAME = "balaji-role"
        COMMON_NAME = "test.balajipki.com"
        K8S_SECRET_NAME = "balaji-cert"
        NAMESPACE = "default"
        REMOTE_SERVER = '34.230.183.157'  // IP or hostname of the remote server
        REMOTE_USER = 'ubuntu'         // SSH username
    }

    stages {
        stage('Check the Cert Status') {
            steps {
                script {
                    // Use SSH to execute a shell script remotely
                    sshagent(['AWS-Cred']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_SERVER} 'bash -s' < check_and_renew_cert.sh
                        """
                    }
                }
            }
        }
        stage('Pull the Cert') {
            steps {
                script {
                    // Use SSH to execute a shell script remotely
                    sshagent(['AWS-Cred']) {
                        sh """
                            scp -r -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_SERVER}:/home/ubuntu/cert.crt /var/lib/jenkins/workspace/Pipeline_PKI
                            scp -r -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_SERVER}:/home/ubuntu/cert.key /var/lib/jenkins/workspace/Pipeline_PKI

                        """
                    }
                }
            }
        }
        stage('Deploy the Cert to K8s') {
            steps {
                echo "Updating certificate in Kubernetes..."
                sh """
                    kubectl create secret tls ${K8S_SECRET_NAME} \
                    --cert=cert.crt \
                    --key=cert.key \
                    --namespace=${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                """
            }
        }
        stage('Verify Deployment') {
            steps {
                echo "Verifying updated certificate in Kubernetes..."
                sh "kubectl get secret ${K8S_SECRET_NAME} -n ${NAMESPACE}"
            }
        }
    }

    post {
        success {
            echo "Certificate renewed and deployed successfully!"
        }
        failure {
            echo "Failed to renew or update the certificate."
        }
    }
}
