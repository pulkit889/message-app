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
                git 'https://github.com/your-repo/your-flask-app.git'
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

        stage('Login to AWS ECR') {
            steps {
                script {
                    // Use AWS CLI to log in to the ECR registry
                    sh '''
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image
                    docker.build("${DOCKER_IMAGE}")
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    // Push the Docker image to ECR
                    docker.withRegistry("https://${ECR_REGISTRY}", '') {
                        docker.image("${DOCKER_IMAGE}").push()
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Apply Kubernetes manifest for deployment
                    sh "kubectl apply -f k8s/deployment.yaml"
                    sh "kubectl rollout status deployment/flask-app --namespace=default"
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
