pipeline {
    agent any

    environment {
        VAULT_ADDR = "http://34.230.183.157:8200"
        VAULT_TOKEN = credentials('vault-token') // Add Vault token in Jenkins credentials
        ROLE_NAME = "balaji-role"
        COMMON_NAME = "test.balajipki.com"
        K8S_SECRET_NAME = "balaji-cert"
        NAMESPACE = "default"
    }

    stages {
        stage('Check Certificate and Renew') {
            steps {
                script {
                    // Run the shell script
                    sh '''
                    #!/bin/bash
                    chmod +x check_and_renew_cert.sh
                    ./check_and_renew_cert.sh
                    '''
                }
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
