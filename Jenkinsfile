pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'  // Set your default region, or fetch dynamically
        ECR_REPO = 'message-app'  // Your ECR repository name
        IMAGE_TAG = "${env.BUILD_ID}"  // Tag with the Jenkins build ID or other tag
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout code from the repository
                git branch: 'main', url: 'https://github.com/pulkit889/message-app.git'
            }
        }

        stage('Fetch AWS Account ID and ECR URL') {
            steps {
                script {
                    // Retrieve AWS account ID and construct the ECR registry URL dynamically
                    def accountId = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                    def ecrRegistry = "${accountId}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    
                    // Export the ECR Registry dynamically
                    env.ECR_REGISTRY = ecrRegistry
                    env.DOCKER_IMAGE = "${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
                }
            }
        }

        stage('Build and Push Image') {
            steps {
                script {
                    sh '''
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
                    docker build -t $DOCKER_IMAGE -f app/Dockerfile app
                    docker push $DOCKER_IMAGE
                    '''
                }
            }
        }


        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh "aws eks update-kubeconfig --region $AWS_REGION --name message-app-eks-cluster"
                    sh "kubectl apply -f k8s-menifests/deployment.yml"
                    sh "kubectl rollout status deployment/message-service --namespace=default"
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed.'
        }
    }
}
