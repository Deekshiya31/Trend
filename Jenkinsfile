pipeline {
    agent any

    environment {
        // Define image name and tag
        DOCKER_IMAGE = "deekshiya31/trend-app"
        IMAGE_TAG = "1.0"

        // EKS/AWS Configuration
        K8S_MANIFEST_DIR = "k8s"      // Path to your k8s folder
        EKS_CLUSTER_NAME = "trend-cluster"
        AWS_REGION = "ap-south-1"     // Official Region ID for Asia Pacific (Mumbai)
    }

    stages {
        // 1. BUILD DOCKER IMAGE
        stage('Build Docker Image') {
            steps {
                // Ensure Docker is available and build the image
                sh 'docker build -t $DOCKER_IMAGE:$IMAGE_TAG .'
            }
        }

//------------------------------------------------------------------------------------------------

        // 2. PUSH TO DOCKERHUB
        stage('Push to DockerHub') {
            steps {
                // NOTE: Change 'dockerhub-credentials' ID to match the ID you set in Jenkins
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh 'echo $PASS | docker login -u $USER --password-stdin'
                    sh 'docker push $DOCKER_IMAGE:$IMAGE_TAG'
                }
            }
        }

//------------------------------------------------------------------------------------------------

        // 3. DEPLOY TO EKS
        stage('Deploy to EKS') {
            steps {
                // **FIXED:** Removed 'credentials' parameter to automatically use the EC2 Instance's IAM Role.
                // The region must be the official ID, which is set in the environment block.
                withAWS(region: AWS_REGION) {
                    sh """
                        # The attached IAM role is used automatically.
                        # This command fetches the EKS cluster config and merges it with kubectl config.
                        aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
                        
                        # Apply Kubernetes manifests
                        kubectl apply -f $K8S_MANIFEST_DIR/deployment.yaml
                        kubectl apply -f $K8S_MANIFEST_DIR/service.yaml
                    """
                }
            }
        }
    }
}
