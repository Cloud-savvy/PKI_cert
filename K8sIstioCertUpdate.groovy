pipeline {
    agent any

    environment {
        VAULT_ADDR = "http://34.230.183.157:8200"
        VAULT_TOKEN = credentials('vault-token') // Vault token stored in Jenkins credentials
        ROLE_NAME = "balaji-role"
        COMMON_NAME = "istio.balajipki.com"
        K8S_SECRET_NAME = "istio-cert"
        NAMESPACE = "istio-system"
        REMOTE_SERVER = '34.230.183.157'  // IP or hostname of the remote server
        REMOTE_USER = 'ubuntu'         // SSH username
    }

    stages {
        stage('Check and Renew Certificate') {
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
        stage('Pull the Certificate') {
            steps {
                script {
                    // Use SCP to transfer the renewed certificate files
                    sshagent(['AWS-Cred']) {
                        sh """
                            scp -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_SERVER}:/home/ubuntu/cert.crt /var/lib/jenkins/workspace/Pipeline_PKI
                            scp -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_SERVER}:/home/ubuntu/cert.key /var/lib/jenkins/workspace/Pipeline_PKI
                        """
                    }
                }
            }
        }
        stage('Deploy the Certificate to Kubernetes') {
            steps {
                script {
                    sh """
                        kubectl create secret tls ${K8S_SECRET_NAME} --cert=/var/lib/jenkins/workspace/Pipeline_PKI/cert.crt --key=/var/lib/jenkins/workspace/Pipeline_PKI/cert.key --namespace=${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                    """
                }
            }
        }
        stage('Verify Deployment') {
            steps {
                script {
                    sh """
                        kubectl get secret ${K8S_SECRET_NAME} -n ${NAMESPACE}
                    """
                }
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