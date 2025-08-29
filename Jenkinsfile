pipeline {
    agent none

    environment {
        DOCKER_IMAGE = "sathish1102/bankingapp1"
        DOCKER_TAG = "${env.BUILD_NUMBER ?: 'latest'}"
        ANSIBLE_INVENTORY = 'ansible/inventory.yml'
    }

    stages {
        stage('Checkout Code') {
            agent { label 'master' }
            steps {
                git branch: 'main', url: 'https://github.com/Sathish-11/Banking-Project1.git'
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
                withCredentials([usernamePassword(credentialsId: 'docker-hub',
                                                  passwordVariable: 'PASS',
                                                  usernameVariable: 'USER')]) {
                    sh """
                        echo "\$PASS" | docker login -u "\$USER" --password-stdin
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    """
                }
            }
        }

        stage('Setup Docker on Test Nodes') {
            agent { label 'master' }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ansible-ssh',
                                                   keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible-playbook -i ansible/inventory.yml \
                        --private-key "\$SSH_KEY" \
                        --become \
                        ansible/playbooks/setup_docker.yml --limit test -vvv
                    """
                }
            }
        }

        stage('Deploy Application on Test Environment') {
            agent { label 'master' }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ansible-ssh',
                                                   keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible-playbook -i ansible/inventory.yml \
                        --private-key "\$SSH_KEY" \
                        --become \
                        -e "docker_image=${DOCKER_IMAGE}:${DOCKER_TAG}" \
                        ansible/playbooks/deploy_app.yml --limit test -vvv
                    """
                }
            }
        }

        stage('Approval for Production Deployment') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: 'Approve Deployment to Production?', ok: 'Deploy'
                }
            }
        }

        stage('Setup Production Environment') {
            agent { label 'master' }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ansible-ssh',
                                                   keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible-playbook -i ansible/inventory.yml \
                        --private-key "\$SSH_KEY" \
                        --become \
                        ansible/playbooks/setup_docker.yml --limit prod -vvv
                    """
                }
            }
        }

        stage('Deploy Application on Production Environment') {
            agent { label 'master' }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ansible-ssh',
                                                   keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible-playbook -i ansible/inventory.yml \
                        --private-key "\$SSH_KEY" \
                        --become \
                        -e "docker_image=${DOCKER_IMAGE}:${DOCKER_TAG}" \
                        ansible/playbooks/deploy_app.yml --limit prod -vvv
                    """
                }
            }
        }
    }
}