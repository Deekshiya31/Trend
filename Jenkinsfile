pipeline {
    agent any
    environment {
        // Define image name and tag
        DOCKER_IMAGE = "deekshiya31/trend-app"
        IMAGE_TAG = "1.0"
        K8S_MANIFEST_DIR = "k8s"  // Path to your k8s folder
        EKS_CLUSTER_NAME = "trend-cluster"
        AWS_REGION = "ap-south-1"
    }
    stages {
        // 1. BUILD DOCKER IMAGE
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE:$IMAGE_TAG .'
            }
        }

        // 2. PUSH TO DOCKERHUB
        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh 'echo $PASS | docker login -u $USER --password-stdin'
                    sh 'docker push $DOCKER_IMAGE:$IMAGE_TAG'
                }
            }
        }

        // 3. DEPLOY TO EKS
        stage('Deploy to EKS') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-credentials') {
                    sh """
                        # Configure kubectl to talk to EKS cluster
                        aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
                        
                        # Apply Kubernetes manifests from k8s folder
                        kubectl apply -f $K8S_MANIFEST_DIR/deployment.yaml
                        kubectl apply -f $K8S_MANIFEST_DIR/service.yaml
                    """
                }
            }
        }
    }
}

