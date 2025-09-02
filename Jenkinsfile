pipeline {
    agent none
    
    environment {
        DOCKER_IMAGE = "sathish1102/bankingapp"
        DOCKER_TAG = "${env.BUILD_NUMBER ?: 'latest'}"
        ANSIBLE_INVENTORY = 'ansible/inventory.yml'
        ANSIBLE_PRIVATE_KEY = credentials('ansible-private-key')
        APP_NAME = 'banking-app'
        HOST_PORT = '8080'
        APP_PORT = '8081'
    }
    
    stages {
        stage('Checkout Code') {
            agent { label 'master' }
            steps {
                git branch: 'main', 
                    credentialsId: 'Github', 
                    url: 'https://github.com/Sathish-11/Banking-Projectv-v2.git'
            }
        }
        
        stage('Build Application') {
            agent { label 'master' }
            steps {
                sh 'mvn clean package -DskipTests'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
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
                sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
            }
        }
        
        stage('Push Docker Image') {
            agent { label 'master' }
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    script {
                        sh """
                            echo \$PASS | docker login -u \$USER --password-stdin
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                        """
                    }
                }
            }
        }
        
        stage('Setup Docker on Test Environment') {
            agent { label 'master' }
            steps {
                script {
                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible-playbook -i ${ANSIBLE_INVENTORY} \
                            --private-key ${ANSIBLE_PRIVATE_KEY} \
                            --become \
                            ansible/playbooks/setup_docker.yml \
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
                        ansible-playbook -i ${ANSIBLE_INVENTORY} \
                            --private-key ${ANSIBLE_PRIVATE_KEY} \
                            --become \
                            -e docker_image=${DOCKER_IMAGE} \
                            -e docker_tag=${DOCKER_TAG} \
                            -e app_name=${APP_NAME} \
                            -e host_port=9000 \
                            -e app_port=${APP_PORT} \
                            ansible/playbooks/deploy_app.yml \
                            --limit test -v
                    """
                }
            }
        }
        
        stage('Test Health Check') {
            agent { label 'master' }
            steps {
                script {
                    sleep(30)
                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible -i ${ANSIBLE_INVENTORY} test \
                            --private-key ${ANSIBLE_PRIVATE_KEY} \
                            -m uri -a "url=http://{{ ansible_host }}:9000/actuator/health method=GET"
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
                        ansible-playbook -i ${ANSIBLE_INVENTORY} \
                            --private-key ${ANSIBLE_PRIVATE_KEY} \
                            --become \
                            ansible/playbooks/setup_docker.yml \
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
                        ansible-playbook -i ${ANSIBLE_INVENTORY} \
                            --private-key ${ANSIBLE_PRIVATE_KEY} \
                            --become \
                            -e docker_image=${DOCKER_IMAGE} \
                            -e docker_tag=stable \
                            -e app_name=${APP_NAME} \
                            -e host_port=88 \
                            -e app_port=${APP_PORT} \
                            ansible/playbooks/deploy_app.yml \
                            --limit prod -v
                    """
                }
            }
        }
        
        stage('Production Health Check') {
            agent { label 'master' }
            steps {
                script {
                    sleep(30)
                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible -i ${ANSIBLE_INVENTORY} prod \
                            --private-key ${ANSIBLE_PRIVATE_KEY} \
                            -m uri -a "url=http://{{ ansible_host }}:88/actuator/health method=GET"
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
                echo 'Pipeline execution completed'
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
                echo "Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            }
        }
    }
}
