pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "deekshiya31/trend-app"
        IMAGE_TAG = "1.0"
    }
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/Deekshiya31/Trend.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE:$IMAGE_TAG .'
            }
        }
        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh 'echo $PASS | docker login -u $USER --password-stdin'
                    sh 'docker push $DOCKER_IMAGE:$IMAGE_TAG'
                }
            }
        }
        // We'll add Deploy to EKS later
    }
}

