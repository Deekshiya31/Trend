pipeline {
    agent any
    environment {
        // Define image name and tag
        DOCKER_IMAGE = "deekshiya31/trend-app"
        IMAGE_TAG = "1.0"
    }
    stages {
        // 1. BUILD DOCKER IMAGE
        // Note: The code is already checked out by Jenkins's job configuration,
        // so we start directly with the build step.
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE:$IMAGE_TAG .'
            }
        }
        
        // 2. PUSH TO DOCKERHUB
        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    // Log in to Docker Hub using credentials stored in Jenkins
                    sh 'echo $PASS | docker login -u $USER --password-stdin'
                    // Push the built image
                    sh 'docker push $DOCKER_IMAGE:$IMAGE_TAG'
                }
            }
        }
        
        // 3. DEPLOY TO EKS (Future Stage)
        // stage('Deploy to EKS') {
        //     steps {
        //         // Add your kubectl or Helm commands here later
        //     }
        // }
    }
}
