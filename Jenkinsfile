pipeline {
    agent none
    environment {
        DOCKER_IMAGE = "sathish1102/bankingapp"
        DOCKER_TAG = "${env.BUILD_NUMBER ?: 'latest'}"
        ANSIBLE_INVENTORY = 'ansible/inventory.yml'
        APP_NAME = 'banking-app'
        HOST_PORT = '8080'
        APP_PORT = '8080'
    }
    stages {
        stage('Checkout Code') {
            agent { label 'master' } 
            steps {
                checkout scm
                sh 'ls -la'  // Debug: show workspace contents
            }
        }
        stage('Build Application') {
            agent { label 'master' } 
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        stage('Run Tests') {
            agent { label 'master' } 
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        stage('Build Docker Image') {
            agent { label 'master' } 
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }
        stage('Push Docker Image') {
            agent { label 'master' } 
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh """
                        echo \$PASS | docker login -u \$USER --password-stdin
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    """
                }
            }
        }
        stage('Setup Docker on Test Environment') {
            agent { label 'master' }
            steps {
                script {
                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible-playbook -i ${ANSIBLE_INVENTORY} \\
                            --private-key /var/lib/jenkins/.ssh/id_rsa \\
                            --become \\
                            ansible/playbooks/setup_docker.yml \\
                            --limit test -v
                    """
                }
            }
        }
        stage('Deploy Application on Test Environment') {
            agent { label 'master' }
            steps {
                script {
                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible-playbook -i ${ANSIBLE_INVENTORY} \\
                            --private-key /var/lib/jenkins/.ssh/id_rsa \\
                            --become \\
                            -e docker_image=${DOCKER_IMAGE} \\
                            -e docker_tag=${DOCKER_TAG} \\
                            -e app_name=${APP_NAME} \\
                            -e host_port=${HOST_PORT} \\
                            -e app_port=${APP_PORT} \\
                            ansible/playbooks/deploy_app.yml \\
                            --limit test -v
                    """
                }
            }
        }
        stage('Approval for Production Deployment') {
            agent { label 'master' }
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: 'Approve Deployment to Production?', ok: 'Deploy'
                }
            }
        }
        stage('Setup Production Environment') {
            agent { label 'master' }
            steps {
                script {
                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible-playbook -i ${ANSIBLE_INVENTORY} \\
                            --private-key /var/lib/jenkins/.ssh/id_rsa \\
                            --become \\
                            ansible/playbooks/setup_docker.yml \\
                            --limit prod -v
                    """
                }
            }
        }
        stage('Deploy Application on Production Environment') {
            agent { label 'master' }
            steps {
                script {
                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible-playbook -i ${ANSIBLE_INVENTORY} \\
                            --private-key /var/lib/jenkins/.ssh/id_rsa \\
                            --become \\
                            -e docker_image=${DOCKER_IMAGE} \\
                            -e docker_tag=${DOCKER_TAG} \\
                            -e app_name=${APP_NAME} \\
                            -e host_port=${HOST_PORT} \\
                            -e app_port=${APP_PORT} \\
                            ansible/playbooks/deploy_app.yml \\
                            --limit prod -v
                    """
                }
            }
        }
    }
    post {
        always {
            node('master') {
                sh """
                    docker image prune -f || true
                    docker system df || true
                """
            }
        }
        failure {
            node('master') {
                echo "Pipeline failed. Check logs for details."
            }
        }
        success {
            node('master') {
                echo "Pipeline completed successfully!"
            }
        }
    }
}
