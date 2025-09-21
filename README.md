# PRT-MERN-EKS

<img width="953" height="539" alt="image" src="https://github.com/user-attachments/assets/88b9baae-435f-4225-b4fa-0c8b041258fa" />

<img width="959" height="379" alt="image" src="https://github.com/user-attachments/assets/8241f3a8-18aa-4e0f-a2d4-7427cbae0ad9" />

<img width="959" height="257" alt="image" src="https://github.com/user-attachments/assets/7f1ec858-a43c-4272-9919-057d44d57507" />

<img width="959" height="301" alt="image" src="https://github.com/user-attachments/assets/838563c4-4b49-45af-8956-8121d51be28e" />

<img width="959" height="539" alt="image" src="https://github.com/user-attachments/assets/cf205e35-2942-432a-812f-adfecfde17ed" />

<img width="959" height="477" alt="image" src="https://github.com/user-attachments/assets/618f394e-5d4d-4c32-ac9a-ac80c3f1386d" />

<img width="959" height="510" alt="image" src="https://github.com/user-attachments/assets/47199914-9116-4950-873b-f8a6e8db149d" />

```
pipeline {
  agent any
  options {
    timestamps()
  }
  environment {
    AWS_REGION        = 'us-west-2'
    CLUSTER_NAME      = 'mern-cluster'
    NAMESPACE         = 'mern'
    ECR_REPO_FRONTEND = 'mern-frontend'
    ECR_REPO_BACKEND  = 'mern-backend'
    ECR_REGISTRY      = "623593084704.dkr.ecr.us-west-2.amazonaws.com" // <-- replace with your AWS account ID
  }
  stages {
    stage('Init AWS + Vars') {
      steps {
        script {
          withAWS(region: "${AWS_REGION}", credentials: 'as-eks-creds') {
            echo "AWS credentials and region set"
          }
        }
      }
    }
    stage('Checkout Code') {
      steps {
        git branch: 'main', url: 'https://github.com/vipulsaw/PRT-MERN-EKS.git'
      }
    }
    stage('Configure kubeconfig') {
      steps {
        script {
          withAWS(region: "${AWS_REGION}", credentials: 'as-eks-creds') {
            sh """
              set -e
              aws eks --region ${AWS_REGION} update-kubeconfig --name ${CLUSTER_NAME}
            """
          }
        }
      }
    }
    stage('Ensure ECR repos') {
      steps {
        script {
          withAWS(region: "${AWS_REGION}", credentials: 'as-eks-creds') {
            sh """
              set -e
              aws ecr describe-repositories --repository-names ${ECR_REPO_FRONTEND} >/dev/null 2>&1 || \
                aws ecr create-repository --repository-name ${ECR_REPO_FRONTEND}
              aws ecr describe-repositories --repository-names ${ECR_REPO_BACKEND} >/dev/null 2>&1 || \
                aws ecr create-repository --repository-name ${ECR_REPO_BACKEND}
            """
          }
        }
      }
    }
    stage('Login to ECR') {
      steps {
        script {
          withAWS(region: "${AWS_REGION}", credentials: 'as-eks-creds') {
            sh """
              aws ecr get-login-password --region ${AWS_REGION} | \
              docker login --username AWS --password-stdin ${ECR_REGISTRY}
            """
          }
        }
      }
    }
    stage('Build Frontend Image') {
      steps {
        sh """
          cd frontend
          docker build -t ${ECR_REGISTRY}/${ECR_REPO_FRONTEND}:latest .
        """
      }
    }
    stage('Build Backend Image') {
      steps {
        sh """
          cd backend
          docker build -t ${ECR_REGISTRY}/${ECR_REPO_BACKEND}:latest .
        """
      }
    }
    stage('Push Images to ECR') {
      steps {
        script {
          withAWS(region: "${AWS_REGION}", credentials: 'as-eks-creds') {
            sh """
              docker push ${ECR_REGISTRY}/${ECR_REPO_FRONTEND}:latest
              docker push ${ECR_REGISTRY}/${ECR_REPO_BACKEND}:latest
            """
          }
        }
      }
    }
    stage('Apply Manifests to EKS') {
      steps {
        script {
          withAWS(region: "${AWS_REGION}", credentials: 'as-eks-creds') {
            sh """
              echo "Applying backend deployment and service..."
              kubectl apply -f k8s-Manifests/backend/deployment.yaml -n ${NAMESPACE}
              kubectl apply -f k8s-Manifests/backend/service.yaml -n ${NAMESPACE}
              echo "Waiting for backend pods to be ready..."
              kubectl rollout status deployment/api -n ${NAMESPACE} --timeout=180s
              echo "Applying frontend deployment and service..."
              kubectl apply -f k8s-Manifests/frontend/deployment.yaml -n ${NAMESPACE}
              kubectl apply -f k8s-Manifests/frontend/service.yaml -n ${NAMESPACE}
              echo "Waiting for frontend pods to be ready..."
              kubectl rollout status deployment/frontend -n ${NAMESPACE} --timeout=180s
            """
          }
        }
      }
    }
  }
}

```

<img width="959" height="539" alt="image" src="https://github.com/user-attachments/assets/9270cc4e-0896-462b-8c15-9854a9d32808" />





