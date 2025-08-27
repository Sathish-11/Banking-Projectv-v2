pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "sathish1102/bankingapp"
        DOCKER_TAG = "${env.BUILD_NUMBER ?: 'latest'}"
        ANSIBLE_INVENTORY = 'inventory.yml'
    }
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', credentialsId: 'Github', url: 'https://github.com/Sathish-11/Banking-Project1.git'
            }
        }
        stage('Build Application') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        stage('Run Tests') {
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
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }
        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    script {
                        sh """
                            echo $PASS | docker login -u $USER --password-stdin && \
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                           """
                    }
                }
            }
        }
        stage('Setup Docker on test nodes') {
            steps {
                sh 'ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/playbooks/setup_docker.yml --limit test'
            }
        }
        stage('Deploy Application on Test Environment') {
            steps {
                sh 'ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/playbooks/deploy_app.yml --limit test'
            }
        }
        '''stage('Deploy Monitoring on Test Environment') {
            steps {
                sh 'ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/playbooks/monitoring.yml --limit test'
            }
        }'''
        stage('Approval for Production Deployment') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: 'Approve Deployment to Production?', ok: 'Deploy'
                }
            }
        }
        stage('Setup Production Environment') {
            steps {
                sh 'ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/playbooks/setup_docker.yml --limit prod' 
            }
        }
        stage('Deploy Application on Production Environment') {
            steps {
                sh 'ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/playbooks/deploy_app.yml --limit prod'
            }
        }
        '''stage('Deploy Monitoring on Production Environment') {
            steps {
                sh 'ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/playbooks/monitoring.yml --limit prod'
            }
        }'''
    }
}